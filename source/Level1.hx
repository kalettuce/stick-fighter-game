package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.input.actions.FlxAction.FlxActionAnalog;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

class Level1 extends FlxState {
    var player:Player;
    var enemy:Enemy;
    var map:FlxTilemap;
    var exitButton:FlxButton;
    var healthBar:FlxBar;
    var staminaBar:FlxBar;

    override public function create() {
        // add the terrain
        map = new FlxTilemap();
        map.loadMapFromCSV("assets/levels/level1_terrain.csv", "assets/images/sf_level_tiles.png", 64, 64);
        map.screenCenter();
        FlxG.camera.setScrollBoundsRect(0, 0, map.width, map.height);
        FlxG.worldBounds.set(0, 0, map.width, map.height);
        add(map);

        // add the player character
        player = new Player();
        player.setPosition(FlxG.width / 2 - player.width / 2, FlxG.height / 2 - player.height / 2);
        add(player);
        add(player.hitArea);

        // add the enemy
        enemy = new Enemy();
        enemy.setPosition(FlxG.width / 2 - enemy.width / 2, FlxG.height / 2 - enemy.height);
        add(enemy);
        player.addEnemy(enemy);

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

        FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON);


        super.create();

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

        FlxG.collide(player.collider, map);
        FlxG.collide(enemy, map);
    }
}
