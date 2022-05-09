package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.input.actions.FlxActionManager.ResetPolicy;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;

class Level2 extends FlxState {
    var player:Player;

    // for prototyping only
    var cameraBound:FlxGroup;
    var map:FlxTilemap;
    var exitButton:FlxButton;
    var healthBar:FlxBar;
    var staminaBar:FlxBar;

    override public function create() {
        super.create();

        // add the terrain
        map = new FlxTilemap();
        map.loadMapFromCSV("assets/levels/level2_terrain.csv", "assets/images/sf_level_tiles.png", 64, 64);
        map.screenCenter();
        add(map);

        // add the player character
        player = new Player();
        player.setPosition(FlxG.width / 2 - player.width / 2, FlxG.height / 2 - player.height / 2);
        add(player);

        exitButton = new FlxButton(0, 0, "Exit", exit);
        exitButton.screenCenter(X);
        exitButton.y = 10;
        add(exitButton);

        // create health bar
        healthBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 100, 10, player, "health", 0, 100, true);
        healthBar.createFilledBar(FlxColor.RED, FlxColor.GREEN, true);
        healthBar.trackParent(175, 0);
        add(healthBar);

        // create stamina bar
        staminaBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 100, 10, player, "stamina", 0, 100, true);
        staminaBar.createFilledBar(FlxColor.BLUE, FlxColor.YELLOW, true);
        staminaBar.trackParent(175, 20);
        add(staminaBar);

        // set a background color
        bgColor = FlxColor.GRAY;

        // make a collision boundary based on camera boundary
        cameraBound = FlxCollision.createCameraWall(FlxG.camera, false, 20);
        FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON);
    }

    function exit():Void
 	{
        FlxG.switchState(new MenuState());
 	}

    override public function update(elapsed:Float) {
        var atkPressed:Bool = FlxG.keys.pressed.K;
        if (atkPressed) {
            if (player.health < -1)
            {
                player.health = 100;
                player.revive();
            }
            else {
                player.hurt(2);
            }
        }
        super.update(elapsed);
        FlxG.collide(player.collider, cameraBound);
        FlxG.collide(player.collider, map);
    }
}
