import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;

class Player extends FlxSprite {
    // controls how large the player character should be relative to the screen size
    static final SIZE_FACTOR_Y:Float = 0.15;

    static final WALK_VELOCITY:Int = 150;
    static final JUMP_VELOCITY:Int = 600;
    static final GRAVITY:Int = 600;

    /**
     * Constructor of a player character
     * (x,y) is the coordinates to spawn the player in.
     * Defaults to spawning at (0,0)
     */
    public function new(x:Int = 0, y:Int = 0) {
        super(x, y);
        // loadGraphic("assets/images/sword_char.png", false, cast(FlxG.width*SIZE_FACTOR_WIDTH, Int),
        //                                                    cast(FlxG.height*SIZE_FACTOR_HEIGHT, Int));
        loadGraphic("assets/images/sword_char.png");
        setGraphicSize(0, Std.int(FlxG.height * SIZE_FACTOR_Y));
        updateHitbox();

        setFacingFlip(FlxObject.LEFT, false, false);
        setFacingFlip(FlxObject.RIGHT, true, false);

        acceleration.y = GRAVITY;
    }

    private function movement() {
        // horizontal movements
        var leftPressed:Bool = FlxG.keys.pressed.A;
        var rightPressed:Bool = FlxG.keys.pressed.D;
        if (leftPressed && rightPressed) {
            velocity.x = 0;
        } else if (leftPressed) {
            facing = FlxObject.LEFT;
            velocity.x = -WALK_VELOCITY;
        } else if (rightPressed) {
            facing = FlxObject.RIGHT;
            velocity.x = WALK_VELOCITY;
        } else {
            velocity.x = 0;
        }
    }

    // handles jumping, needs to be called before super.update()
    private function jump() {
        if (FlxG.keys.justPressed.SPACE && isTouching(FlxObject.FLOOR)) {
            velocity.y = -JUMP_VELOCITY;
        }
    }

    override public function update(elapsed:Float) {
        jump();
        super.update(elapsed);
        movement();
    }
}