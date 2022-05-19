import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.system.FlxSplash;
import flixel.tile.FlxTilemap;
import flixel.util.FlxCollision;
import flixel.util.FlxDirectionFlags;
import openfl.geom.Point;

class Player extends FlxSprite {
    private static final WALK_VELOCITY:Int = 230;
    private static final JUMP_VELOCITY:Int = 700;
    private static final GRAVITY:Int = 1000;
    private static final ATTACK_RANGE:Int = 219;

    // offset of the collider relative to the rendered sprite
    private static final COLLIDER_OFFSET_X = 205;
    private static final COLLIDER_OFFSET_Y = 152;

    // the object to compute collision with, should only cover the body of the
    // player character
    public var collider:FlxSprite;

    // when attacking, this sprite is used to check if an attack could hit an enemy
    // by checking its pixel-perfect collision results with the enemy
    public var hitArea:FlxSprite;
    // the effects is used to store effects layer independent of the character sprite
    public var effects:FlxSprite;

    public var stamina:Float;

    public var enemies:FlxTypedGroup<Enemy>;
    private var enemiesHit:Array<Bool>;

    // when stunned, the character stops accept input
    private var stunned:Bool;

    // true when the player is dead
    private var dead:Bool;

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
        animation.add("jump", [10, 11], 10, false);
        animation.add("float", [11], 10);
        animation.add("land", [10], 10, false);
        animation.add("walk", [20, 21, 22, 23, 0], 10);
        animation.add("high_attack", [0, 30, 31, 32, 0], 10, false);
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
        hitArea.animation.add("high_attack", [0, 30, 31, 32, 0], 10, false);
        hitArea.setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        hitArea.setFacingFlip(FlxDirectionFlags.RIGHT, true, false);

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
        animation.play("idle");
        hitArea.animation.play("idle");
        effects.animation.play("idle");

        // other initializations
        setFacing(FlxDirectionFlags.RIGHT);
        health = 100;
        stamina = 100;
        dead = false;
    }

    /********************************************* Public Functions *********************************************/
    public function addEnemy(enemy:Enemy) {
        enemies.add(enemy);
        enemiesHit.push(false);
    }

    public function isParrying():Bool {
        return animation.frameIndex == 5 || animation.frameIndex == 6;
    }

    public function isBlocking():Bool {
        return animation.frameIndex == 18;
    }

    public function isDead():Bool {
        return dead;
    }

    public function hit(damage:Float) {
        animation.play("hit");
        hitArea.animation.play("idle");
        stunned = true;
        collider.velocity.x = 0;
        collider.velocity.y = 0;
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

    // return the x coordinate of center point of the sprite
    public function getCenter():Float {
        return collider.x + (collider.width / 2);
    }

    // return the range of the sprite's attack
    public function getRange():Int {
        return ATTACK_RANGE;
    }

    /********************************************* Animation Callbacks *********************************************/
    private function animationFinishCallback(name:String) {
        // Note that switch statements in Haxe does not "fall through"
        switch (name) {
            case "jump":
                animation.play("float");
            case "land":
                animation.play("idle");
            case "high_attack":
                stunned = false;
                resetEnemiesHit();
                hitArea.animation.play("idle");
            case "hit":
                stunned = false;
                hitArea.animation.play("idle");
            case "parry":
                stunned = false;
                hitArea.animation.play("idle");
            case "parried":
                stunned = false;
                hitArea.animation.play("idle");
        }
    }

    private function animationFrameCallback(name:String, frameNumber:Int, frameIndex:Int) {
        if (collider.velocity.y == 0 && (name == "jump" || name == "float")) {
            animation.play("land");
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
    private function actions() {
        if (stunned && animation.name == "block") {
            if (FlxG.keys.justReleased.K) {
                animation.play("idle");
                stunned = false;
            } else if (FlxG.keys.pressed.J) {
                animation.play("parry");
                stunned = true; // might not be necessary but just in case
            }
        }

        // sync position to collider
        setPosition(collider.x-COLLIDER_OFFSET_X, collider.y-COLLIDER_OFFSET_Y);

        if (stunned) return;

        // TODO: UX improvement - prioritize attack so that when both the movement keys and the attack key
        // are pressed, attack is launched but not the movement
        if (animation.name == "idle" || animation.name == "walking" || animation.name == "land") {
            if (FlxG.keys.pressed.J && stamina >= 20) {
                animation.play("high_attack");
                hitArea.animation.play("high_attack");
                stunned = true;
                stamina -= 20;
            } else if (FlxG.keys.pressed.K) {
                animation.play("block");
                stunned = true;
            }

            // log move "high attack"
            Main.LOGGER.logLevelAction(LoggingActions.PLAYER_ATTACK, {direction: "high attack"});

        }

        // horizontal movements
        var leftPressed:Bool = FlxG.keys.pressed.A;
        var rightPressed:Bool = FlxG.keys.pressed.D;
        if ((leftPressed && rightPressed) || stunned) {
            collider.velocity.x = 0;

            // Log invalid action when left & right key pressed together
            Main.LOGGER.logLevelAction(LoggingActions.PLAYER_MOVE, {direction: "Invalid action"});
        } else if (leftPressed) {
            setFacing(FlxDirectionFlags.LEFT);
            collider.velocity.x = -WALK_VELOCITY;

            // log move "left"
            Main.LOGGER.logLevelAction(LoggingActions.PLAYER_MOVE, {direction: "left"});

        } else if (rightPressed) {
            setFacing(FlxDirectionFlags.RIGHT);
            collider.velocity.x = WALK_VELOCITY;

            // log move "right"
            Main.LOGGER.logLevelAction(LoggingActions.PLAYER_MOVE, {direction: "right"});

        } else {
            collider.velocity.x = 0;
        }
    }

    private function setFacing(direction:FlxDirectionFlags) {
        facing = direction;
        hitArea.facing = direction;
        effects.facing = direction;
    }

    private function hitCheck() {
        if (animation.frameIndex == 31) {
            for (i in 0...enemies.members.length) {
                if (!enemiesHit[i] && !enemies.members[i].isDead() && FlxCollision.pixelPerfectCheck(hitArea, enemies.members[i], 1)) {
                    if (enemies.members[i].isParrying()) {
                        enemies.members[i].hitParry();
                        animation.play("parried");
                        hitArea.animation.play("idle");
                        stunned = true;
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

    // handles jumping, needs to be called before super.update()
    private function jump() {
        if (stunned) return;
        if (FlxG.keys.justPressed.SPACE && collider.isTouching(FlxDirectionFlags.FLOOR)) {
            collider.velocity.y = -JUMP_VELOCITY * 1.2;
            animation.play("jump", true);

            // log move "jump"
            Main.LOGGER.logLevelAction(LoggingActions.PLAYER_MOVE, {direction: "jump"});
        }
    }

    /********************************************* Overriden Functions *********************************************/
    override public function kill() {
        animation.play("death");
        stunned = true;
        dead = true;
    }

    override public function setPosition(x:Float = 0, y:Float = 0) {
        super.setPosition(x, y);
        hitArea.setPosition(x, y);
        collider.setPosition(x+COLLIDER_OFFSET_X, y+COLLIDER_OFFSET_Y);
        effects.setPosition(x, y);
    }

    override public function update(elapsed:Float) {
        stamina = Math.min(stamina + elapsed * 13, 100);
        jump();
        actions();
        hitCheck();

        // animation decision, only handles the case when player is on the ground
        // and not have a vertical velocity
        // TODO: we can possibly optimize these if conditions
        if (collider.isTouching(FlxDirectionFlags.FLOOR)) {
            if (collider.velocity.y == 0 && animation.name != "float" && animation.name != "land" && !stunned) {
                if (Math.abs(collider.velocity.x) > 0) {
                    animation.play("walk");
                } else {
                    animation.play("idle");
                }
            }
        } else if (animation.name == "walk" || animation.name == "idle") {
            animation.play("float");
        }

        super.update(elapsed);
        collider.update(elapsed);
    }
}