import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxSplash;
import flixel.util.FlxDirectionFlags;

class Player extends FlxSprite {
    // controls how large the player character should be relative to the screen size
    private static final WALK_VELOCITY:Int = 150;
    private static final JUMP_VELOCITY:Int = 700;
    private static final GRAVITY:Int = 1000;

    // offset of the collider relative to the rendered sprite
    private static final COLLIDER_OFFSET_X = 205;
    private static final COLLIDER_OFFSET_Y = 49;

    // the object to compute collision with, should only cover the body of the
    // player character
    public var collider:FlxSprite;

    // when attacking, this sprite is used to check if an attack could hit an enemy
    // by checking its pixel-perfect collision results with the enemy
    public var hitArea:FlxSprite;

    // when stunned, the character stops accept input
    private var stunned:Bool;

    /**
     * Constructor of a player character
     * (x,y) is the coordinates to spawn the player in.
     * Defaults to spawning at (0,0)
     */
    public function new(x:Int = 0, y:Int = 0) {
        super(x, y);

        stunned = false;

        // load the sprites for animation
        // load the rendered animation
        loadGraphic("assets/images/spear_sprites_render.png", true, 450, 200);
        animation.add("idle", [0, 1, 2, 3, 4], 10);
        animation.add("jump", [11, 12, 13], 10, false);
        animation.add("float", [13], 10);
        animation.add("land", [15, 16], 10, false);
        animation.add("walk", [20, 21, 22, 23, 24, 25], 8);
        animation.add("high_attack", [30, 31, 32, 33, 34], 10, false);
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
        hitArea.loadGraphic("assets/images/spear_hit_area.png", true, 450, 200);
        hitArea.animation.add("idle", [0, 1, 2, 3, 4], 10);
        hitArea.animation.add("jump", [11, 12, 13], 10, false);
        hitArea.animation.add("float", [13], 10);
        hitArea.animation.add("land", [15, 16], 10, false);
        hitArea.animation.add("walk", [20, 21, 22, 23, 24, 25], 8);
        hitArea.animation.add("high_attack", [30, 31, 32, 33, 34], 10, false);
        hitArea.setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        hitArea.setFacingFlip(FlxDirectionFlags.RIGHT, true, false);

        // start in idle
        animation.play("idle");
        hitArea.animation.play("idle");

        // Starting health
        health = 100;
    }

    private function actions() {
        if (stunned) return;

        // TODO UX improvement: prioritize attack so that when both the movement keys and the attack key
        // are pressed, attack is launched but not the movement
        if (FlxG.keys.pressed.J && (animation.name == "idle" || animation.name == "walking" || animation.name == "land")) {
            animation.play("high_attack");
            hitArea.animation.play("high_attack");
            stunned = true;
        }

        // horizontal movements
        var leftPressed:Bool = FlxG.keys.pressed.A;
        var rightPressed:Bool = FlxG.keys.pressed.D;
        if ((leftPressed && rightPressed) || stunned) {
            collider.velocity.x = 0;
        } else if (leftPressed) {
            facing = FlxDirectionFlags.LEFT;
            hitArea.facing = FlxDirectionFlags.LEFT;
            collider.velocity.x = -WALK_VELOCITY;
        } else if (rightPressed) {
            facing = FlxDirectionFlags.RIGHT;
            hitArea.facing = FlxDirectionFlags.RIGHT;
            collider.velocity.x = WALK_VELOCITY;
        } else {
            collider.velocity.x = 0;
        }
        setPosition(collider.x-COLLIDER_OFFSET_X, collider.y-COLLIDER_OFFSET_Y);
    }

    private function animationFinishCallback(name:String) {
        if (name == "jump") {
            animation.play("float");
        } else if (name == "land") {
            animation.play("idle");
        } else if (name == "high_attack") {
            stunned = false;
            hitArea.animation.play("idle");
        }
    }

    private function animationFrameCallback(name:String, frameNumber:Int, frameIndex:Int) {
        if (collider.velocity.y == 0 && (name == "jump" || name == "float")) {
            animation.play("land");
        }
    }

    // handles jumping, needs to be called before super.update()
    private function jump() {
        if (stunned) return;
        if (FlxG.keys.justPressed.SPACE && collider.isTouching(FlxDirectionFlags.FLOOR)) {
            collider.velocity.y = -JUMP_VELOCITY * 1.2;
            animation.play("jump", true);
        }
    }

    override public function setPosition(x:Float = 0, y:Float = 0) {
        super.setPosition(x, y);
        hitArea.setPosition(x, y);
        collider.setPosition(x+COLLIDER_OFFSET_X, y+COLLIDER_OFFSET_Y);
    }

    override public function update(elapsed:Float) {
        jump();
        actions();

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