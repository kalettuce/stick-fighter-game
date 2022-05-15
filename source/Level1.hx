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
    var timerMax:Float = 8;

    var playerHealth:Float = 100;
    var playerHealthTimer:Float = 0;
    var playerHealthBar:FlxBar;

    var playerStaminaTimer:Float = 0;
    var playerStaminaBar:FlxBar;

    var enemyHealth:Float = 100;
    var enemyHealthTimer:Float = 0;
    var enemyHealthBar:FlxBar;

    var enemyStaminaTimer:Float = 0;
    var enemyStaminaBar:FlxBar;

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
        add(player.collider);
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
        playerHealthBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 100, 10, player, "health", 0, 100, true);
        playerHealthBar.createFilledBar(FlxColor.RED, FlxColor.GREEN, true);
        playerHealthBar.trackParent(175, 0);

        // create stamina bar
        playerStaminaBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 100, 10, player, "stamina", 0, 100, true);
        playerStaminaBar.createFilledBar(FlxColor.BLUE, FlxColor.YELLOW, true);
        playerStaminaBar.trackParent(175, 20);

        // create health bar
        enemyHealthBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 100, 10, enemy, "health", 0, 100, true);
        enemyHealthBar.createFilledBar(FlxColor.RED, FlxColor.GREEN, true);
        enemyHealthBar.trackParent(175, 0);
        add(enemyHealthBar);

        // create stamina bar
        enemyStaminaBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 100, 10, enemy, "stamina", 0, 100, true);
        enemyStaminaBar.createFilledBar(FlxColor.BLUE, FlxColor.YELLOW, true);
        enemyStaminaBar.trackParent(175, 20);
        add(enemyStaminaBar);

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

    private function showHealthBar(isPlayer:Bool, characterHealth:Float, healthBar: FlxBar) {
        if (characterHealth != playerHealth) {
            add(healthBar);
            if (isPlayer) {
                playerHealth = characterHealth;
            } else {
                enemyHealth = characterHealth;
            }
        } else {
            if (isPlayer) {
                if (playerHealthTimer > timerMax) {
                    remove(healthBar);
                    playerHealthTimer = 0;
                }
            } else {
                if (enemyHealthTimer > timerMax) {
                    remove(healthBar);
                    enemyHealthTimer = 0;
                }
            }
        }
    }

    private function showStaminaBar(isPlayer:Bool, characterStamina:Float, staminaBar: FlxBar, elapsed:Float) {
        if (characterStamina < 1) {
            add(staminaBar);
        } else if (characterStamina == 100) {
            if (isPlayer) {
                playerStaminaTimer += elapsed;
                if (playerStaminaTimer > timerMax) {
                    remove(staminaBar);
                    playerStaminaTimer = 0;
                }
            } else {
                enemyStaminaTimer += elapsed;
                if (enemyStaminaTimer > timerMax) {
                    remove(staminaBar);
                    enemyStaminaTimer = 0;
                }
            }
        }
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

        playerHealthTimer += elapsed;
        showHealthBar(true, player.health, playerHealthBar);
        enemyHealthTimer += elapsed;
        showHealthBar(false, enemy.health, enemyHealthBar);

        showStaminaBar(true, player.stamina, playerStaminaBar, elapsed);
        // showStaminaBar(false, enemy.stamina, enemyStaminaBar);

        FlxG.collide(player.collider, map);
        FlxG.collide(enemy.collider, map);
    }
}
