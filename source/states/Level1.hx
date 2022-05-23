package states;

import actions.AIAction;
import actions.ActionStatus;
import ai.SequentialActionDecider;
import ai.TerrainSolver;
import ai.TilePlatform;
import fighter.Enemy;
import fighter.Player;
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
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import motion.Actuate;

class Level1 extends FlxState {
    var player:Player;
    var enemy:Enemy;
    var map:FlxTilemap;
    var exitButton:FlxButton;
    var timerMax:Float = 5;
    var killCountText:FlxButton;
    var levelScreen:FlxSprite;
    var tween:FlxTween;


    var playerHealth:Float = 100;
    var playerHealthTimer:Float = 0;
    var playerHealthBar:FlxBar;

    var playerStamina:Float = 100;
    var playerStaminaTimer:Float = 0;
    var playerStaminaBar:FlxBar;

    var enemyHealth:Float = 100;
    var enemyHealthTimer:Float = 0;
    var enemyHealthBar:FlxBar;

    var enemyStamina:Float = 100;
    var enemyStaminaTimer:Float = 0;
    var enemyStaminaBar:FlxBar;

    // Declare nextLevel and curLevel variables
    var nextLevel:Class<FlxState>;
    var curLevel:Class<FlxState>;

    override public function create() {
        // add the terrain
        map = new FlxTilemap();
        map.loadMapFromCSV("assets/levels/level1_terrain.csv", "assets/images/sf_level_tiles.png", 64, 64);
        final platforms:Array<TilePlatform> = TerrainSolver.solveCSVTerrain("assets/levels/level1_terrain.csv", 64, 64);
        FlxG.camera.setScrollBoundsRect(0, 0, map.width, map.height);
        FlxG.worldBounds.set(0, 0, map.width, map.height);
        add(map);

        // create the player character
        player = new Player();
        player.setPlatforms(platforms);

        // create the enemy
        var combatSequence:Array<AIAction> = [AIAction.LIGHT_ACTION, AIAction.LIGHT_ACTION, AIAction.HEAVY_ACTION, AIAction.BLOCK_ACTION, AIAction.PARRY_ACTION, AIAction.IDLE_ACTION];
        var statusSequence:Array<ActionStatus> = [ActionStatus.BLOCKED, ActionStatus.BLOCKED, ActionStatus.PARRIED, ActionStatus.BLOCK_HIT, ActionStatus.PARRY_HIT, ActionStatus.INTERRUPTED];
        enemy = new Enemy(700, 0, player);
        enemy.setPlayer(player);
        enemy.setCombatAI(new SequentialActionDecider(enemy, player, combatSequence, statusSequence));
        enemy.setPlatforms(platforms);
        player.addEnemy(enemy);

        exitButton = new FlxButton(0, 0, "Return to Menu", exit);
        exitButton.scale.set(2, 2);
        exitButton.updateHitbox();
        exitButton.label.setFormat(null, 13, FlxColor.BLACK);
        exitButton.label.fieldWidth = exitButton.width;
        exitButton.label.alignment = "center";
        exitButton.label.offset.y -= 8;
        exitButton.x = 1090;
        exitButton.y = 20;

        // create health bar
        playerHealthBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 70, 10, player, "health", 0, 100, true);
        playerHealthBar.createFilledBar(FlxColor.WHITE, FlxColor.RED, true);
        playerHealthBar.trackParent(175, 0);

        // create stamina bar
        playerStaminaBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 70, 10, player, "stamina", 0, 100, true);
        playerStaminaBar.createFilledBar(FlxColor.WHITE, FlxColor.GREEN, true);
        playerStaminaBar.trackParent(175, 20);

        // create health bar
        enemyHealthBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 70, 10, enemy, "health", 0, 100, true);
        enemyHealthBar.createFilledBar(FlxColor.WHITE, FlxColor.RED, true);
        enemyHealthBar.trackParent(175, 0);

        // create stamina bar
        enemyStaminaBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 70, 10, enemy, "stamina", 0, 100, true);
        enemyStaminaBar.createFilledBar(FlxColor.WHITE, FlxColor.GREEN, true);
        enemyStaminaBar.trackParent(175, 20);

        // set a background color
        bgColor = FlxColor.GRAY;

        // construct the scene
        add(enemy.hitArea);
        add(enemy);
        add(player.hitArea);
        add(player);
        add(player.effects);
        add(enemy.effects);
        add(exitButton);

        

        // Initialize nextLevel and curLevel variable
        nextLevel = Level2;
        curLevel = Level1;

        // Initialize kill count
        FlxG.save.data.killCount = 0;
        FlxG.save.flush();


        levelScreen = new FlxSprite();
        levelScreen.loadGraphic("assets/images/Level1.png");
        levelScreen.screenCenter(XY);
        add(levelScreen);

        FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON);

        Actuate.tween (levelScreen, 7, { alpha: 0 }); // fade out
        
        super.create();
    }

    function exit():Void
     {
        // log clicking "exit" button
        Main.LOGGER.logActionWithNoLevel(LoggingActions.CLICK_EXIT);

        // log level end
        Main.LOGGER.logLevelEnd({won: false});
        FlxG.switchState(new MenuState());
     }

    private function showHealthBar(isPlayer:Bool, characterHealth:Float, healthBar: FlxBar, elapsed: Float) {
        if (isPlayer) {
            if (characterHealth != playerHealth) {
                add(healthBar);
                playerHealth = characterHealth;
                playerHealthTimer = 0;
            } else {
                playerHealthTimer += elapsed;
                if (playerHealthTimer > timerMax) {
                    remove(healthBar);
                    playerHealthTimer = 0;
                }
            }
        } else {
            if (characterHealth != enemyHealth) {
                add(healthBar);
                enemyHealth = characterHealth;
                enemyHealthTimer = 0;
            } else {
                enemyHealthTimer += elapsed;
                if (enemyHealthTimer > timerMax) {
                    remove(healthBar);
                    enemyHealthTimer = 0;
                }
            }
        }
    }

    private function showStaminaBar(isPlayer:Bool, characterStamina:Float, staminaBar: FlxBar, elapsed: Float) {
        if (isPlayer) {
            if (characterStamina != playerStamina) {
                add(staminaBar);
                playerStamina = characterStamina;
                playerStaminaTimer = 0;
            } else {
                playerStaminaTimer += elapsed;
                if (playerStaminaTimer > timerMax) {
                    remove(staminaBar);
                }
            }
        } else {
            if (characterStamina != enemyStamina) {
                add(staminaBar);
                enemyStamina = characterStamina;
                enemyStaminaTimer = 0;
            } else {
                enemyStaminaTimer += elapsed;
                if (enemyStaminaTimer > timerMax) {
                    remove(staminaBar);
                }
            }
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        showHealthBar(true, player.health, playerHealthBar, elapsed);
        showHealthBar(false, enemy.health, enemyHealthBar, elapsed);

        showStaminaBar(true, player.stamina, playerStaminaBar, elapsed);
        showStaminaBar(false, enemy.stamina, enemyStaminaBar, elapsed);

        remove(killCountText);
        killCountText = new FlxButton(0, 0, "Kill Count: " + FlxG.save.data.killCount.toString());
        killCountText.loadGraphic("assets/images/transparent.png", true, 125, 20);
        killCountText.label.setFormat(null, 16, FlxColor.BLACK);
        killCountText.x = 20;
        killCountText.y = 20;
        add(killCountText);

        if (enemy.health == 0) {
            Main.LOGGER.logLevelEnd({won: true});
            FlxG.save.data.unlockedTwo = true;
            FlxG.save.flush();

            // Wait 5 seconds to play "death" animation
            haxe.Timer.delay(popupComplete, 500);
        }

        if (player.health == 0) {
            Main.LOGGER.logLevelEnd({won: false});

            // Wait 5 seconds to play "death" animation
            haxe.Timer.delay(level_lost, 500);
        }

        FlxG.collide(player.collider, map);
        FlxG.collide(enemy.collider, map);
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
