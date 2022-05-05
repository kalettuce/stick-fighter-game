package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.util.FlxAxes;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;

class PlayState extends FlxState {
    var player:Player;

    // for prototyping only
    var cameraBound:FlxGroup;
    var map:FlxTilemap;
    var healthText:FlxText;

    override public function create() {
        super.create();

        // add the terrain
        map = new FlxTilemap();
        map.loadMapFromCSV("assets/levels/level1_terrain.csv", "assets/images/sf_level_tiles.png", 64, 64);
        map.screenCenter();
        add(map);

        // add the player character
        player = new Player();
        player.setPosition(FlxG.width / 2 - player.width / 2, FlxG.height / 2 - player.height / 2);
        add(player);

        // set a background color
        bgColor = FlxColor.GRAY;

        // make a collision boundary based on camera boundary
        cameraBound = FlxCollision.createCameraWall(FlxG.camera, false, 20);

        player.health = 5;

        healthText = new FlxText();
        healthText.size = 16;
        healthText.text = "Health: 100";
        healthText.autoSize = false;
        healthText.wordWrap = false;
        healthText.fieldWidth = FlxG.width;
        healthText.color = FlxColor.BLACK;
        healthText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.WHITE, 2, 1);
        healthText.alignment = FlxTextAlign.CENTER;
        healthText.screenCenter(FlxAxes.X);
        healthText.y = 8;
        add(healthText);
    }

    override public function update(elapsed:Float) {
        var atkPressed:Bool = FlxG.keys.pressed.K;
        if (atkPressed) {
            if (player.health < -1)
            {
                player.health = 5;
                player.revive();
            }
            else
                player.hurt(elapsed * 5);

            if (player.health > 0)
                healthText.text = "Health: " + Std.string(Math.ceil(player.health * 20));
            else
                healthText.text = "DEAD!";
        }
        super.update(elapsed);
        FlxG.collide(player.collider, cameraBound);
        FlxG.collide(player.collider, map);
    }
}
