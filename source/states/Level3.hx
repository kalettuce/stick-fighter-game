package states;

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
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import motion.Actuate;

class Level3 extends FlxState {
    public static var unlocked:Bool = false;
    var player:Player;

    // for prototyping only
    var map:FlxTilemap;
    var exitButton:FlxButton;
    var healthBar:FlxBar;
    var staminaBar:FlxBar;

    // Declare nextLevel and curLevel variables
    var nextLevel:Class<FlxState>;
    var curLevel:Class<FlxState>;

    var timerMax:Float = 5;
    var killCountText:FlxButton;
    var levelScreen:FlxSprite;
    var tween:FlxTween;

    override public function create() {
        super.create();

        // add the terrain
        map = new FlxTilemap();
        map.loadMapFromCSV("assets/levels/level1_terrain.csv", "assets/images/sf_level_tiles.png", 64, 64);
        add(map);

        var placeholderText = new FlxText(250, 350, 0, "", 40);
        placeholderText.color = FlxColor.WHITE;
        placeholderText.text = "Level 3 is work in progress...";
        add(placeholderText);
        placeholderText.centerOrigin();
        placeholderText.screenCenter();

        exitButton = new FlxButton(0, 0, "Return to Menu", exit);
        exitButton.scale.set(2, 2);
        exitButton.updateHitbox();
        exitButton.label.setFormat(null, 13, FlxColor.BLACK);
        exitButton.label.fieldWidth = exitButton.width;
        exitButton.label.alignment = "center";
        exitButton.label.offset.y -= 8;
        exitButton.x = 1090;
        exitButton.y = 20;
        add(exitButton);
        
        // add the player character
        /*player = new Player();
        player.setPosition(FlxG.width / 2 - player.width / 2, FlxG.height / 2 - player.height / 2);
        add(player);

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

        nextLevel = Level4;
         
        haxe.Timer.delay(splash_screen_delay, 2000);
        */
       
    }

    function exit():Void
     {
        // log clicking "exit" button
        Main.LOGGER.logActionWithNoLevel(LoggingActions.CLICK_EXIT);

        // log level end
        Main.LOGGER.logLevelEnd({won: false});
        FlxG.switchState(new MenuState());
     }

    /*override public function update(elapsed:Float) {
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
    }*/

    private function splash_screen_delay() {
        Actuate.tween(levelScreen, 7, { alpha: 0 }); // fade out
    }

    // Call LevelComplete substate
    private function popupComplete() {
        final levelComplete = new LevelComplete(nextLevel);
        openSubState(levelComplete);
    }

    // Call LevelLose substate
    private function level_lost() {
        final lost = new LevelLose(curLevel);
        openSubState(lost);
    }
}
