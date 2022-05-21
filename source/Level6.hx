package;

import fighter.Enemy;
import fighter.Player;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;

class Level6 extends FlxState {
    public static var unlocked:Bool = false;
    var player:Player;

    // for prototyping only
    var map:FlxTilemap;
    var exitButton:FlxButton;
    var healthBar:FlxBar;
    var staminaBar:FlxBar;

    override public function create() {
        super.create();

        // add the terrain
        map = new FlxTilemap();
        map.loadMapFromCSV("assets/levels/level6_terrain.csv", "assets/images/sf_level_tiles.png", 64, 64);
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
        FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON);
    }

    function exit():Void
     {
        // log clicking "exit" button
        Main.LOGGER.logActionWithNoLevel(LoggingActions.CLICK_EXIT);

        // log level end
        Main.LOGGER.logLevelEnd({won: false});
        FlxG.switchState(new MenuState());
     }

    override public function update(elapsed:Float) {
        var atkPressed:Bool = FlxG.keys.pressed.K;
        if (atkPressed) {
            if (player.health < -1)
            {

                // PLACEHOLDER!!

                // For the time being until logic is fully implemented
                // Log player losing all health and losing the game
                Main.LOGGER.logLevelEnd({won: false});

                player.health = 100;
                player.revive();
            }
            else {

                // PLACEHOLDER!!

                // For the time being until logic is fully implemented
                // log "simulated" enemy hit
                Main.LOGGER.logLevelAction(LoggingActions.ENEMY_ATTACK, {direction: "high attack"});
                player.hurt(2);
            }
        }

        super.update(elapsed);
        FlxG.collide(player.collider, map);
    }
}
