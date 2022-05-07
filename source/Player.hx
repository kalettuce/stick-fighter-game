import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;

class Player extends FlxSprite {
    // controls how large the player character should be relative to the screen size
    private static final WALK_VELOCITY:Int = 150;
    private static final JUMP_VELOCITY:Int = 600;
    private static final GRAVITY:Int = 600;

    // offset of the collider relative to the rendered sprite
    private static final COLLIDER_OFFSET_X = 205;
    private static final COLLIDER_OFFSET_Y = 49;
    public var collider:FlxSprite;

    /**
     * Constructor of a player character
     * (x,y) is the coordinates to spawn the player in.
     * Defaults to spawning at (0,0)
     */
    public function new(x:Int = 0, y:Int = 0) {
        super(x, y);

        // load the sprites for animation
        // load the rendered animation
        loadGraphic("assets/images/spear_sprites_render.png", true, 450, 200);
        animation.add("idle", [0, 1, 2, 3, 4], 10);
        animation.add("jump", [11, 12, 13], 1);
        animation.add("float", [13], 1);
        animation.add("land", [15, 16], 10, false);
        animation.add("walk", [20, 21, 22, 23, 24, 25], 8);
        animation.callback = animationFrameCallback;
        animation.finishCallback = animationFinishCallback;
        setFacingFlip(FlxObject.LEFT, false, false);
        setFacingFlip(FlxObject.RIGHT, true, false);

        // load the collider
        collider = new FlxSprite(x+COLLIDER_OFFSET_X, y+COLLIDER_OFFSET_Y);
        collider.loadGraphic("assets/images/spear_sprites_collider.png", false);

        collider.acceleration.y = GRAVITY;
        collider.active = false; // prevents collider.update() from being automatically called
    }

    private function movement() {
        // horizontal movements
        var leftPressed:Bool = FlxG.keys.pressed.A;
        var rightPressed:Bool = FlxG.keys.pressed.D;
        if (leftPressed && rightPressed) {
            collider.velocity.x = 0;
        } else if (leftPressed) {
            facing = FlxObject.LEFT;
            collider.velocity.x = -WALK_VELOCITY;
        } else if (rightPressed) {
            facing = FlxObject.RIGHT;
            collider.velocity.x = WALK_VELOCITY;
        } else {
            collider.velocity.x = 0;
        }
        setPosition(collider.x-COLLIDER_OFFSET_X, collider.y-COLLIDER_OFFSET_Y);
    }

    private function animationFinishCallback(animationName:String) {
        if (animationName == "jump") {
            trace("animationFinishCallback calling float");
            animation.play("float");
        } else if (animationName == "land") {
            trace("animationFinishCallback calling idle");
            animation.play("idle");
        }
    }

    private function animationFrameCallback(name:String, frameNumber:Int, frameIndex:Int) {
        if (collider.isTouching(FlxObject.DOWN) && (name == "jump" || name == "float")) {
            trace("playing land");
            animation.play("land");
        }
    }

    // handles jumping, needs to be called before super.update()
    private function jump() {
        if (FlxG.keys.justPressed.SPACE && collider.isTouching(FlxObject.FLOOR)) {
            collider.velocity.y = -JUMP_VELOCITY;
            animation.play("jump", true);
        }
    }

    override public function setPosition(x:Float = 0, y:Float = 0) {
        super.setPosition(x, y);
        collider.setPosition(x+COLLIDER_OFFSET_X, y+COLLIDER_OFFSET_Y);
    }

    override public function update(elapsed:Float) {
        jump();
        super.update(elapsed);
        collider.update(elapsed);
        movement();

        // animation decision, only handles the case when player is on the ground
        if (collider.isTouching(FlxObject.FLOOR)) {
            if (Math.abs(collider.velocity.x) > 0) {
                animation.play("walk");
            } else {
                animation.play("idle");
            }
        }
    }
}