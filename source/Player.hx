import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;

class Player extends FlxSprite {
    // controls how large the player character should be relative to the screen size
    static final SIZE_FACTOR_Y:Float = 0.15;

    static final WALK_VELOCITY:Int = 150;
    static final JUMP_VELOCITY:Int = 600;
    static final GRAVITY:Int = 600;

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
        animation.add("jump", [10, 11, 12, 13, 14], 10);
        animation.add("walk", [20, 21, 22, 23, 24, 25], 8);
        setFacingFlip(FlxObject.LEFT, false, false);
        setFacingFlip(FlxObject.RIGHT, true, false);

        // load the collider
        collider = new FlxSprite(x+205, y+49);
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
        setPosition(collider.x-205, collider.y-49);
    }

    // handles jumping, needs to be called before super.update()
    private function jump() {
        if (FlxG.keys.justPressed.SPACE && collider.isTouching(FlxObject.FLOOR)) {
            collider.velocity.y = -JUMP_VELOCITY;
        }
    }

    override public function setPosition(x:Float = 0, y:Float = 0) {
        super.setPosition(x, y);
        collider.setPosition(x+205, y+49);
    }

    override public function update(elapsed:Float) {
        jump();
        super.update(elapsed);
        collider.update(elapsed);
        movement();

        // animation decision
        if (Math.abs(collider.velocity.x) > 0) {
            animation.play("walk");
            collider.animation.play("walk");
        } else {
            animation.play("idle");
            collider.animation.play("idle");
        }
    }
}