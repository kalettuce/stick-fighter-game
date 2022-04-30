package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import flixel.util.FlxCollision;

class PlayState extends FlxState {
    var sprite:Player;

    // for prototyping only
    var cameraBound:FlxGroup;

    override public function create() {
        super.create();

        // add the player character
        sprite = new Player();
        sprite.setPosition();
        sprite.x = FlxG.width / 2 - sprite.width / 2;
        sprite.y = FlxG.height / 2 - sprite.height / 2;
        add(sprite);

        // set a background color
        bgColor = FlxColor.GRAY;
        
        // make a collision boundary based on camera boundary
        cameraBound = FlxCollision.createCameraWall(FlxG.camera, false, 20);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        FlxG.collide(sprite, cameraBound);
    }
}
