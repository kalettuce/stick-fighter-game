package fighter;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.system.FlxSplash;
import flixel.tile.FlxTilemap;
import flixel.util.FlxCollision;
import flixel.util.FlxDirectionFlags;
import openfl.geom.Point;

class Player extends FightUnit {
    private static final WALK_VELOCITY:Int = 230;
    private static final JUMP_CUMULATIVE_STEP:Int = 4200;
    private static final MAX_JUMP_VELOCITY:Int = 800;
    private static final MIN_JUMP_VELOCITY:Int = 400;
    private static final GRAVITY:Int = 1000;
    private static final ATTACK_RANGE:Int = 219;
    private static final STAMINA_RECOVERY_RATE = 16;

    // offset of the collider relative to the rendered sprite
    private static final COLLIDER_OFFSET_X = 205;
    private static final COLLIDER_OFFSET_Y = 152;

    public var stamina:Float;

    public var enemies:FlxTypedGroup<Enemy>;
    private var enemiesHit:Array<Bool>;

    private var cumulativeJumpVelocity:Int;

    /**
     * Constructor of a player character
     * (x,y) is the coordinates to spawn the player in.
     * Defaults to spawning at (0,0)
     */
    public function new(x:Int = 0, y:Int = 0) {
        super(x, y);
        enemies = new FlxTypedGroup<Enemy>();
        enemiesHit = new Array<Bool>();
        stunned = false;

        // load the sprites for animation
        // load the rendered animation
        loadGraphic("assets/images/spear_sprites_render.png", true, 450, 400);
        animation.add("idle", [0, 1, 2, 3, 0], 10);
        animation.add("parry", [4, 5, 6, 7, 8, 9], 10, false);
        animation.add("jump", [10], 10, false);
        animation.add("float", [11], 10);
        animation.add("land", [10], 10, false);
        animation.add("walk", [20, 21, 22, 23, 0], 10);
        animation.add("light", [0, 30, 31, 32, 0], 10, false);
        animation.add("hit", [40, 41, 42, 0], 10, false);
        animation.add("parried", [12, 13, 14, 15, 16, 17, 0], 6, false);
        animation.add("block", [18], 10);
        animation.add("death", [24, 25, 26], 10, false);
        animation.callback = animationFrameCallback;
        animation.finishCallback = animationFinishCallback;
        setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        setFacingFlip(FlxDirectionFlags.RIGHT, true, false);

        // load the collider
        collider = new FlxSprite(x+COLLIDER_OFFSET_X, y+COLLIDER_OFFSET_Y);
        collider.loadGraphic("assets/images/spear_sprites_collider.png", false);

        collider.acceleration.y = GRAVITY;
        collider.maxVelocity.y = GRAVITY;
        collider.active = false; // prevents collider.update() from being automatically called

        // load the hit area
        hitArea = new FlxSprite(x, y);
        hitArea.loadGraphic("assets/images/spear_hit_area.png", true, 450, 400);
        hitArea.animation.add("idle", [0], 10);
        hitArea.animation.add("light", [0, 30, 31, 32, 0], 10, false);
        hitArea.setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        hitArea.setFacingFlip(FlxDirectionFlags.RIGHT, true, false);
        hitArea.alpha = 0.01;

        // load the effects layer
        effects = new FlxSprite(x, y);
        effects.loadGraphic("assets/images/spear_effect.png", true, 450, 400);
        effects.animation.add("idle", [0], 10);
        effects.animation.add("hit_block", [1, 2, 3, 4, 5, 6, 7], 15, false);
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

    private function walk() {
        switch (status) {
            // when on the ground, play "walk" and set velocity
            case FighterStates.IDLE, FighterStates.WALK:
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
        stamina -= 20;
        collider.velocity.x = 0;
        // log move
        Main.LOGGER.logLevelAction(LoggingActions.PLAYER_ATTACK, {direction: "high attack"});
    }

    private function block() {
        play("block");
        stunned = true;
        status = FighterStates.BLOCK;
        collider.velocity.x = 0;
        // log move "block"
        Main.LOGGER.logLevelAction(LoggingActions.PLAYER_BLOCK, {direction: "high block"});
    }

    private function parry() {
        play("parry");
        stunned = true;
        status = FighterStates.PARRY;
        collider.velocity.x = 0;
        // log move "parry"
        Main.LOGGER.logLevelAction(LoggingActions.PLAYER_PARRY, {direction: "high parry"});
    }

    // handles jumping, needs to be called before super.update()
    private function jump() {
        play("jump");
        stunned = false;
        status = FighterStates.JUMP;
        Main.LOGGER.logLevelAction(LoggingActions.PLAYER_MOVE, {direction: "jump"});
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
        } else {
            status = FighterStates.HEAVYPARRIED;
        }
        stunned = true;
    }

    /***************************************** Passive Actions Functions ******************************************/
    public function lightHit(damage:Float) {
        animation.play("hit");
        hitArea.animation.play("idle");
        stunned = true;
        collider.velocity.x = 0;
        collider.velocity.y = 0;
        status = FighterStates.HITSTUNLIGHT;
        resetEnemiesHit();
        hurt(damage);
    }

    public function hitBlock() {
        effects.animation.play("hit_block");

        if (facing == FlxDirectionFlags.LEFT) {
            collider.velocity.x = 150;
        } else {
            collider.velocity.x = -150;
        }
    }


    /********************************************* Animation Callbacks *********************************************/
    private function animationFinishCallback(name:String) {
        // Note that switch statements in Haxe does not "fall through"
        switch (name) {
            case "jump":
                if (cumulativeJumpVelocity > MAX_JUMP_VELOCITY) {
                    collider.velocity.y = -MAX_JUMP_VELOCITY;
                } else {
                    trace("jumping at velocity: " + cumulativeJumpVelocity);
                    collider.velocity.y = -cumulativeJumpVelocity;
                }
                cumulativeJumpVelocity = 0;
                float();
            case "light":
                idle();
                resetEnemiesHit();
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
            case "hit_block": collider.velocity.x = 0;
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
            } else if (FlxG.keys.justReleased.K) {
                idle();
            } else if (FlxG.keys.pressed.J) {
                parry();
            }
            return;
        }

        // otherwisd, no action is permitted when stunned
        if (stunned) {
            collider.velocity.x = 0;
            return;
        }

        var leftPressed:Bool = FlxG.keys.pressed.A;
        var rightPressed:Bool = FlxG.keys.pressed.D;
        // decides whether to initiate attack, block, or jump
        if (status == FighterStates.IDLE || status == FighterStates.WALK) {
            if (FlxG.keys.pressed.J && stamina >= 20) {
                light();
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

        // do not execute movement actions if stunned from previous decisions
        if (stunned) return;
        if ((leftPressed && rightPressed) || (!leftPressed && !rightPressed)) {
            idle();
        } else if (leftPressed) {
            setFacing(FlxDirectionFlags.LEFT);
            walk();
            Main.LOGGER.logLevelAction(LoggingActions.PLAYER_MOVE, {direction: "left"});
        } else if (rightPressed) {
            setFacing(FlxDirectionFlags.RIGHT);
            walk();
            Main.LOGGER.logLevelAction(LoggingActions.PLAYER_MOVE, {direction: "right"});
        } else {
            idle();
        }
    }

    private function hitCheck() {
        if (animation.frameIndex == 31) {
            for (i in 0...enemies.members.length) {
                if (!enemiesHit[i] && !enemies.members[i].isDead() && FlxG.pixelPerfectOverlap(hitArea, enemies.members[i], 1)) {
                    if (enemies.members[i].isParrying()) {
                        enemies.members[i].hitParry();
                        parried();
                        resetEnemiesHit();
                    } else if (enemies.members[i].isBlocking()) {
                        enemies.members[i].hitBlock();
                        enemiesHit[i] = true;
                    } else {
                        enemies.members[i].hit(20);
                        enemiesHit[i] = true;
                    }
                }
            }
        }
    }

    private function resetEnemiesHit() {
        for (i in 0...enemiesHit.length) {
            enemiesHit[i] = false;
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
        if (animation.name != "light" && animation.name != "heavy") {
            stamina = Math.min(stamina + elapsed * STAMINA_RECOVERY_RATE, 100);
        }

        // sync position to collider
        setPosition(collider.x, collider.y);

        // execute player input
        actions(elapsed);

        // check for any hit enemies
        hitCheck();

        super.update(elapsed);
        collider.update(elapsed);
    }
}