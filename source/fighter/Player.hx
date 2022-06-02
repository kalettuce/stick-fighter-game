package fighter;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.system.FlxSplash;
import flixel.tile.FlxTilemap;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import openfl.geom.Point;

class Player extends FightUnit {
    private static final WALK_VELOCITY:Int = 230;
    private static final RUN_VELOCITY:Int = 400;
    private static final JUMP_CUMULATIVE_STEP:Int = 4200;
    private static final MAX_JUMP_VELOCITY:Int = 1500;
    private static final MIN_JUMP_VELOCITY:Int = 600;
    private static final GRAVITY:Int = 1500;
    private static final DRAG_Y:Int = 300;
    private static final ATTACK_RANGE:Int = 219;
    private static final STAMINA_RECOVERY_RATE:Int = 16;
    private static final LIGHT_STAMINA_USAGE:Int = 10;
    private static final HEAVY_STAMINA_USAGE:Int = 20;
    private static final CANCEL_STAMINA_USAGE:Int = 10;

    // offset of the collider relative to the rendered sprite
    private static final COLLIDER_OFFSET_X = 205;
    private static final COLLIDER_OFFSET_Y = 152;

    private var externalCam:FlxCamera;

    public var stamina:Float;

    public var enemies:FlxTypedGroup<Enemy>;
    private var enemiesHit:Array<Bool>;
    public var minions:FlxTypedGroup<Minion>;
    private var minionsHit:Array<Bool>;

    private var cumulativeJumpVelocity:Int;
    private var readyCancel:Bool;
    private var cancelling:Bool; // true if we're cancelling the current heavy attack

    /**
     * Constructor of a player character
     * (x,y) is the coordinates to spawn the player in.
     * Defaults to spawning at (0,0)
     */
    public function new(x:Int = 0, y:Int = 0) {
        super(x-COLLIDER_OFFSET_X, y-COLLIDER_OFFSET_Y);
        enemies = new FlxTypedGroup<Enemy>();
        enemiesHit = new Array<Bool>();
        minions = new FlxTypedGroup<Minion>();
        minionsHit = new Array<Bool>();
        stunned = false;
        cancelling = false;
        readyCancel = false;

        // load the sprites for animation
        // load the rendered animation
        loadGraphic("assets/images/spear_sprites_render.png", true, 450, 400);
        animation.add("idle", [0, 1, 2, 3, 0], 10);
        animation.add("parry", [4, 5, 6, 7, 8, 9], 10, false);
        animation.add("jump", [10], 10, false);
        animation.add("float", [11], 10);
        animation.add("land", [10], 10, false);
        animation.add("walk", [20, 21, 22, 23, 0], 10);
        animation.add("run", [33, 34, 35, 36, 37], 10);
        animation.add("light", [0, 30, 31, 32, 0], 10, false);
        animation.add("heavy", [0, 19, 27, 27, 27, 28, 29, 29, 29, 0], 10, false);
        animation.add("light-hit", [40, 41, 42, 0], 12, false);
        animation.add("heavy-hit", [40, 41, 41, 42, 42, 0], 10, false);
        animation.add("parried", [12, 13, 14, 15, 16, 17, 0], 6, false);
        animation.add("block", [18], 10);
        animation.add("death", [24, 25, 26], 10, false);
        animation.callback = animationFrameCallback;
        animation.finishCallback = animationFinishCallback;
        setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        setFacingFlip(FlxDirectionFlags.RIGHT, true, false);

        // load the collider
        collider = new FlxSprite(x, y);
        collider.loadGraphic("assets/images/spear_sprites_collider.png", false);

        collider.acceleration.y = GRAVITY;
        collider.maxVelocity.y = 2*GRAVITY;
        collider.drag.y = DRAG_Y;
        collider.active = false; // prevents collider.update() from being automatically called

        // load the hit area
        hitArea = new FlxSprite(x-COLLIDER_OFFSET_X, y-COLLIDER_OFFSET_Y);
        hitArea.loadGraphic("assets/images/spear_hit_area.png", true, 450, 400);
        hitArea.animation.add("idle", [0], 10);
        hitArea.animation.add("light", [1, 0, 31, 0, 0], 10, false);
        hitArea.animation.add("heavy", [0, 0, 0, 1, 0, 28, 29, 0, 0, 0], 10, false);
        hitArea.setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        hitArea.setFacingFlip(FlxDirectionFlags.RIGHT, true, false);
        hitArea.alpha = 0.01;

        // load the effects layer
        effects = new FlxSprite(x-COLLIDER_OFFSET_X, y-COLLIDER_OFFSET_Y);
        effects.loadGraphic("assets/images/spear_effect.png", true, 450, 400);
        effects.animation.add("idle", [0], 10);
        effects.animation.add("hit-block", [1, 2, 3, 4, 5, 6, 7], 15, false);
        effects.animation.callback = effectsAnimationFrameCallback;
        effects.animation.finishCallback = effectsAnimationFinishCallback;
        effects.setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        effects.setFacingFlip(FlxDirectionFlags.RIGHT, true, false);

        // start in idle
        idle();
        effects.animation.play("idle");

        // other initializations
        setFacing(FlxDirectionFlags.RIGHT);
        health = 100;
        stamina = 100;
        dead = false;
        status = FighterStates.IDLE;
        cumulativeJumpVelocity = 0;
    }

    /********************************************* Public Queries *********************************************/
    public function addEnemy(enemy:Enemy) {
        enemies.add(enemy);
        enemiesHit.push(false);
    }

    public function addMinion(minion:Minion) {
        minions.add(minion);
        minionsHit.push(false);
    }

    public function setCamera(camera:FlxCamera) {
        externalCam = camera;
    }

    public function attackImminent():Bool {
        return hitArea.animation.frameIndex == 1;
    }

    override public function isParrying():Bool {
        return animation.frameIndex == 5 || animation.frameIndex == 6;
    }

    override public function getRange():Int {
        return ATTACK_RANGE;
    }

    /********************************************* Actions Functions *********************************************/
    private function idle() {
        // only idles if on the floor
        // does not interrupt jumping or landing animations
        if (collider.isTouching(FlxDirectionFlags.FLOOR) && status != FighterStates.JUMP && !(!animation.finished && animation.name == "land")) {
            play("idle");
            status = FighterStates.IDLE;
        } else if (collider.velocity.y > 0) {
            float();
        }
        collider.velocity.x = 0;
        stunned = false;
    }

    private function run() {
        switch (status) {
            case FighterStates.IDLE, FighterStates.WALK, FighterStates.RUN:
                // float if falling
                if (collider.velocity.y > 0) {
                    float();
                    return;
                }

                // do not interrupt landing
                if (animation.name != "land") {
                    play("run");
                }
                stunned = false;
                status = FighterStates.WALK;
                if (facing == FlxDirectionFlags.LEFT) {
                    collider.velocity.x = -RUN_VELOCITY;
                } else {
                    collider.velocity.x = RUN_VELOCITY;
                }
            case FighterStates.JUMP, FighterStates.AIR:
                if (facing == FlxDirectionFlags.LEFT) {
                    collider.velocity.x = -WALK_VELOCITY;
                } else {
                    collider.velocity.x = WALK_VELOCITY;
                }
            default:
        }
    }

    private function walk() {
        switch (status) {
            // when on the ground, play "walk" and set velocity
            case FighterStates.IDLE, FighterStates.WALK, FighterStates.RUN:
                // float if falling
                if (collider.velocity.y > 0) {
                    float();
                    return;
                }

                // does not interrupt a landing animation
                if (animation.name != "land") {
                    play("walk");
                }

                stunned = false;
                status = FighterStates.WALK;
                if (facing == FlxDirectionFlags.LEFT) {
                    collider.velocity.x = -WALK_VELOCITY;
                } else {
                    collider.velocity.x = WALK_VELOCITY;
                }
            // when jumping, sets the velocity but does not switch the animation
            case FighterStates.JUMP, FighterStates.AIR:
                if (facing == FlxDirectionFlags.LEFT) {
                    collider.velocity.x = -WALK_VELOCITY;
                } else {
                    collider.velocity.x = WALK_VELOCITY;
                }
            default:
        }
    }

    private function light() {
        status = FighterStates.LIGHT;
        play("light");
        stunned = true;
        stamina -= LIGHT_STAMINA_USAGE;
        collider.velocity.x = 0;
        // log light attack
        Main.LOGGER.logLevelAction(LoggingActions.PLAYER_ATTACK, {type: "light attack", version: FlxG.save.data.version});
    }

    private function heavy() {
        status = FighterStates.HEAVY;
        play("heavy");
        cancelling = false;
        readyCancel = false;
        stunned = true;
        stamina -= HEAVY_STAMINA_USAGE;
        collider.velocity.x = 0;
        // log heavy attack
        Main.LOGGER.logLevelAction(LoggingActions.PLAYER_ATTACK, {type: "heavy attack", version: FlxG.save.data.version});
    }

    private function block() {
        play("block");
        stunned = true;
        status = FighterStates.BLOCK;
        collider.velocity.x = 0;
        // log move "block"
        Main.LOGGER.logLevelAction(LoggingActions.PLAYER_BLOCK, {action: "block", version: FlxG.save.data.version});
    }

    private function parry() {
        play("parry");
        stunned = true;
        status = FighterStates.PARRY;
        collider.velocity.x = 0;
        // log move "parry"
        Main.LOGGER.logLevelAction(LoggingActions.PLAYER_PARRY, {action: "parry", version: FlxG.save.data.version});
    }

    // handles jumping, needs to be called before super.update()
    private function jump() {
        play("jump");
        stunned = false;
        status = FighterStates.JUMP;
        Main.LOGGER.logLevelAction(LoggingActions.PLAYER_MOVE, {action: "jump", version: FlxG.save.data.version});
    }

    // float in air
    private function float() {
        play("float");
        platformIndex = 0;
        status = FighterStates.AIR;
        stunned = false;
    }

    private function parried() {
        animation.play("parried");
        hitArea.animation.play("idle");
        if (status == FighterStates.LIGHT) {
            status = FighterStates.LIGHTPARRIED;
            camera.flash(0xb0000000, 0.8, null, true);
            camera.shake(0.01, 0.1, null, true);
            Main.LOGGER.logLevelAction(LoggingActions.PLAYER_ATTACK_PARRIED, {event: "PLAYER light attack PARRIED", version: FlxG.save.data.version});
        } else {
            status = FighterStates.HEAVYPARRIED;
            camera.flash(0x70000000, 0.4, null, true);
            Main.LOGGER.logLevelAction(LoggingActions.PLAYER_ATTACK_PARRIED, {event: "PLAYER heavy attack PARRIED", version: FlxG.save.data.version});
        }
        stunned = true;
    }

    /***************************************** Passive Actions Functions ******************************************/
    public function lightHit(damage:Float) {
        Main.LOGGER.logLevelAction(LoggingActions.ENEMY_ATTACK_HIT, {event: "ENEMY light attack HIT", version: FlxG.save.data.version});
        camera.flash(0x30ff0000, 0.5, null, true);
        animation.play("light-hit");
        hitArea.animation.play("idle");
        stunned = true;
        collider.velocity.x = 0;
        collider.velocity.y = 0;
        status = FighterStates.HITSTUNLIGHT;
        resetEnemiesHit();
        hurt(damage);
    }

    public function heavyHit(damage:Float) {
        Main.LOGGER.logLevelAction(LoggingActions.ENEMY_ATTACK_HIT, {event: "ENEMY heavy attack HIT", version: FlxG.save.data.version});
        camera.flash(0x80ff0000, 0.5, null, true);
        animation.play("heavy-hit");
        hitArea.animation.play("idle");
        stunned = true;
        collider.velocity.x = 0;
        collider.velocity.y = 0;
        status = FighterStates.HITSTUNHEAVY;
        resetEnemiesHit();
        hurt(damage);
    }

    public function hitBlock() {
        Main.LOGGER.logLevelAction(LoggingActions.ENEMY_ATTACK_HIT, {event: "ENEMY attack BLOCKED", version: FlxG.save.data.version});
        effects.animation.play("hit-block", true);

        if (facing == FlxDirectionFlags.LEFT) {
            collider.velocity.x = 150;
        } else {
            collider.velocity.x = -150;
        }
    }

    public function hitLightParry() {
        camera.flash(0xb0ffffff, 0.6, null, true);
    }
    public function hitHeavyParry() {
        camera.flash(0x50ffffff, 0.3, null, true);
    }

    /********************************************* Animation Callbacks *********************************************/
    private function animationFinishCallback(name:String) {
        // Note that switch statements in Haxe does not "fall through"
        switch (name) {
            case "jump":
                if (cumulativeJumpVelocity > MAX_JUMP_VELOCITY) {
                    collider.velocity.y = -MAX_JUMP_VELOCITY;
                } else {
                    collider.velocity.y = -cumulativeJumpVelocity;
                }
                cumulativeJumpVelocity = 0;
                float();
            case "light", "heavy":
                idle();
                resetEnemiesHit();
            case "death": // stay dead
            default: idle();
        }
    }

    private function animationFrameCallback(name:String, frameNumber:Int, frameIndex:Int) {
        // TODO: minor bug, the code seems to be able to enter this branch even when (status == IDLE)
        if ((status == FighterStates.AIR) && (collider.velocity.y == 0) && collider.isTouching(FlxDirectionFlags.FLOOR)) {
            play("land");
            //trace("landing with status " + status);
            status = FighterStates.IDLE;
            updatePlatformIndex();
        }
    }

    private function effectsAnimationFrameCallback(name:String, frameNumber:Int, frameIndex:Int) {
        switch (name) {
            case "hit-block": collider.velocity.x = 0;
            default:
        }
    }

    private function effectsAnimationFinishCallback(name:String) {
       effects.animation.play("idle");
    }

    /********************************************* update() helper functions *********************************************/

    // determines what action to execute based on user input
    private function actions(elapsed:Float) {
        // handling the case when the player is blocking
        if (stunned && status == FighterStates.BLOCK) {
            if (collider.velocity.y > 0) {
                float();
            } else if (!FlxG.keys.pressed.K) {
                idle();
            } else if (FlxG.keys.pressed.J) {
                parry();
            }
            return;
        } else if (stunned && status == FighterStates.HEAVY) {
            if (FlxG.keys.pressed.E) {
                cancelling = true;
            }
        }

        // otherwisd, no action is permitted when stunned
        if (stunned) {
            collider.velocity.x = 0;
            return;
        }

        final leftPressed:Bool = FlxG.keys.pressed.A;
        final rightPressed:Bool = FlxG.keys.pressed.D;
        final leftJustPressed:Bool = FlxG.keys.justPressed.A;
        final rightJustPressed:Bool = FlxG.keys.justPressed.D;
        // decides whether to initiate attack, block, or jump
        if (status == FighterStates.IDLE || status == FighterStates.WALK) {
            if (FlxG.keys.pressed.J && stamina >= LIGHT_STAMINA_USAGE) {
                light();
            } else if (FlxG.keys.pressed.I && stamina >= HEAVY_STAMINA_USAGE) {
                heavy();
            } else if (FlxG.keys.pressed.K) {
                block();
            } else if (FlxG.keys.justPressed.SPACE && collider.isTouching(FlxDirectionFlags.FLOOR)) {
                cumulativeJumpVelocity = MIN_JUMP_VELOCITY;
                jump();
            }
        } else if (status == FighterStates.JUMP) {
            if (FlxG.keys.pressed.SPACE) {
                cumulativeJumpVelocity += Std.int(JUMP_CUMULATIVE_STEP * elapsed);
            }
        }

        final shiftPressed:Bool = FlxG.keys.pressed.SHIFT;
        // do not execute movement actions if stunned from previous decisions
        if (stunned) return;
        if ((leftPressed && rightPressed) || (!leftPressed && !rightPressed)) {
            idle();
        } else if (leftPressed) {
            setFacing(FlxDirectionFlags.LEFT);
            if (shiftPressed) {
                run();
            } else {
                walk();
            }
            // log only on justPress
            if (leftJustPressed) {
                Main.LOGGER.logLevelAction(LoggingActions.PLAYER_MOVE, {direction: "left", version: FlxG.save.data.version});
            }
        } else if (rightPressed) {
            setFacing(FlxDirectionFlags.RIGHT);
            if (shiftPressed) {
                run();
            } else {
                walk();
            }
            if (rightJustPressed) {
                Main.LOGGER.logLevelAction(LoggingActions.PLAYER_MOVE, {direction: "right", version: FlxG.save.data.version});
            }
        } else {
            idle();
        }
    }

    private function hitCheck() {
        if (hitArea.animation.frameIndex == 31 || hitArea.animation.frameIndex == 28 || hitArea.animation.frameIndex == 29) {
            for (i in 0...enemies.members.length) {
                if (!enemiesHit[i] && !enemies.members[i].isDead() && FlxG.pixelPerfectOverlap(hitArea, enemies.members[i], 1)) {
                    if (enemies.members[i].isParrying()) {
                        enemies.members[i].hitParry();
                        parried();
                        resetEnemiesHit();
                    } else if (enemies.members[i].isBlocking() && status == FighterStates.LIGHT && enemies.members[i].facing != facing) {
                        enemies.members[i].hitBlock();
                        enemiesHit[i] = true;
                    } else {
                        if (status == FighterStates.LIGHT) {
                            enemies.members[i].lightHit(20);
                        } else {
                            enemies.members[i].heavyHit(30);
                        }
                        enemiesHit[i] = true;
                    }
                }
            }

            // do the same for minions
            for (i in 0...minions.members.length) {
                if (!minionsHit[i] && !minions.members[i].isDead() && FlxG.pixelPerfectOverlap(hitArea, minions.members[i], 1)) {
                    if (status == FighterStates.LIGHT) {
                        minions.members[i].lightHit(20);
                    } else {
                        minions.members[i].heavyHit(30);
                    }
                    minionsHit[i] = true;
                }
            }
        }
    }

    private function resetEnemiesHit() {
        for (i in 0...enemiesHit.length) {
            enemiesHit[i] = false;
        }
        for (i in 0...minionsHit.length) {
            minionsHit[i] = false;
        }
    }

    /***************************************** Overriden Functions from FlxSprite *********************************************/

    // sets the collider to the given location and the other layers to their
    // matching location as well
    override public function setPosition(x:Float = 0, y:Float = 0) {
        final originalX:Float = x - COLLIDER_OFFSET_X;
        final originalY:Float = y - COLLIDER_OFFSET_Y;
        super.setPosition(originalX, originalY);
        hitArea.setPosition(originalX, originalY);
        effects.setPosition(originalX, originalY);
        collider.setPosition(x, y);
    }

    override public function kill() {
        animation.play("death");
        stunned = true;
        dead = true;
    }

    override public function update(elapsed:Float) {
        // recovers stamina if not attacking
        if (status != FighterStates.LIGHT && status != FighterStates.HEAVY) {
            stamina = Math.min(stamina + elapsed * STAMINA_RECOVERY_RATE, 100);
        }

        if (attackImminent() && status == FighterStates.HEAVY && cancelling) {
            if (readyCancel) {
                idle();
            } else {
                readyCancel = true;
            }
        }

        // sync position to collider
        setPosition(collider.x, collider.y);
        if (!dead) {
            // execute player input
            actions(elapsed);
            // check for any hit enemies
            hitCheck();
        }

        super.update(elapsed);
        collider.update(elapsed);
    }
}