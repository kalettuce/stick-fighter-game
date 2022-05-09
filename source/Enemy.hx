import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;


class Enemy extends FlxSprite {
    private static final GRAVITY:Int = 1000;


    public function new (x:Int = 0, y:Int = 0) {
        super(x, y);

        loadGraphic("assets/images/sword_sprites_render.png", true, 300, 250);
        animation.add("idle", [0, 1, 2, 3, 4], 10);
        animation.add("jump", [11, 12, 13], 10, false);
        animation.add("float", [13], 10);
        animation.add("land", [15, 16], 10, false);
        animation.add("walk", [20, 21, 22, 23, 24, 25], 8);
        animation.add("high_attack", [30, 31, 32, 33, 34, 35, 36, 37], 10, false);
        setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        setFacingFlip(FlxDirectionFlags.RIGHT, true, false);

        animation.play("idle");
        acceleration.y = GRAVITY;
        maxVelocity.y = GRAVITY;
    }
}