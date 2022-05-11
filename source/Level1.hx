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
    var enemyHealth:FlxBar;
    var enemyStamina:FlxBar;

    override public function create() {
        // add the terrain
        map = new FlxTilemap();
        map.loadMapFromCSV("assets/levels/level1_terrain.csv", "assets/images/sf_level_tiles.png", 64, 64);
        FlxG.camera.setScrollBoundsRect(0, 0, map.width, map.height);
        FlxG.worldBounds.set(0, 0, map.width, map.height);
        add(map);

        // add the player character
        player = new Player();
        add(player.hitArea);
        add(player);

        // add the enemy
        enemy = new Enemy(700, 0);
        add(enemy.hitArea);
        add(enemy);
        enemy.setPlayer(player);
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

        // create health bar
        enemyHealth = new FlxBar(0, 0, LEFT_TO_RIGHT, 100, 10, enemy, "health", 0, 100, true);
        enemyHealth.createFilledBar(FlxColor.RED, FlxColor.GREEN, true);
        enemyHealth.trackParent(175, 0);
        add(enemyHealth);

        // create stamina bar
        enemyStamina = new FlxBar(0, 0, LEFT_TO_RIGHT, 100, 10, enemy, "stamina", 0, 100, true);
        enemyStamina.createFilledBar(FlxColor.BLUE, FlxColor.YELLOW, true);
        enemyStamina.trackParent(175, 20);
        add(enemyStamina);

        // set a background color
        bgColor = FlxColor.GRAY;

        FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON);

        super.create();
    }

    function exit():Void
 	{
	    // log clicking "exit" button
        //Main.LOGGER.logActionWithNoLevel(LoggingActions.CLICK_EXIT);

        // log level end
        //Main.LOGGER.logLevelEnd({won: false});
        FlxG.switchState(new Level1());
 	}



    override public function update(elapsed:Float) {
        /*
        var atkPressed:Bool = FlxG.keys.pressed.K;
        if (atkPressed) {
            if (player.health < -1)
            {

                // PLACEHOLDER!!

                // For the time being until logic is fully implemented
                // Log player losing all health and losing the game
                //Main.LOGGER.logLevelEnd({won: false});

                player.health = 100;
                player.revive();
            }
            else {

                // PLACEHOLDER!!

                // For the time being until logic is fully implemented
                // log "simulated" enemy hit
                //Main.LOGGER.logLevelAction(LoggingActions.ENEMY_ATTACK, {direction: "high attack"});
                player.hurt(2);
            }
        }*/
        super.update(elapsed);

        FlxG.collide(player.collider, map);
        FlxG.collide(enemy.collider, map);
    }
}
