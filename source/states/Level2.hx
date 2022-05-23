package states;

import actions.AIAction;
import actions.ActionStatus;
import ai.ActionDecider;
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
import flixel.input.actions.FlxActionManager.ResetPolicy;
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

class Level2 extends FlxState {
    var player:Player;
    var enemy:Enemy;
    var enemyAI:ActionDecider;
    var enemy2:Enemy;
    var enemyAI2:ActionDecider;
    var enemy3:Enemy;
    var enemyAI3:ActionDecider;
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

    var enemyHealth2:Float = 100;
    var enemyHealthTimer2:Float = 0;
    var enemyHealthBar2:FlxBar;

    var enemyStamina2:Float = 100;
    var enemyStaminaTimer2:Float = 0;
    var enemyStaminaBar2:FlxBar;

    var enemyHealth3:Float = 100;
    var enemyHealthTimer3:Float = 0;
    var enemyHealthBar3:FlxBar;

    var enemyStamina3:Float = 100;
    var enemyStaminaTimer3:Float = 0;
    var enemyStaminaBar3:FlxBar;

    // Declare nextLevel and curLevel variables
    var nextLevel:Class<FlxState>;
    var curLevel:Class<FlxState>;

    override public function create() {
        // add the terrain
        map = new FlxTilemap();
        map.loadMapFromCSV("assets/levels/level3_terrain.csv", "assets/images/sf_level_tiles.png", 64, 64);
        final platforms:Array<TilePlatform> = TerrainSolver.solveCSVTerrain("assets/levels/level3_terrain.csv", 64, 64);
        FlxG.camera.setScrollBoundsRect(0, 0, map.width, map.height);
        FlxG.worldBounds.set(0, 0, map.width, map.height);
        add(map);

        // create the player character
        player = new Player();
        player.setPlatforms(platforms);

        // create the enemy
        var combatSequence:Array<AIAction> = [AIAction.LIGHT_ACTION, AIAction.LIGHT_ACTION, AIAction.HEAVY_ACTION, AIAction.BLOCK_ACTION, AIAction.PARRY_ACTION, AIAction.IDLE_ACTION];
        var statusSequence:Array<ActionStatus> = [ActionStatus.BLOCKED, ActionStatus.BLOCKED, ActionStatus.PARRIED, ActionStatus.BLOCK_HIT, ActionStatus.PARRY_HIT, ActionStatus.INTERRUPTED];
        enemy = new Enemy(1500, 0, player);
        enemyAI = new SequentialActionDecider(enemy, player, combatSequence, statusSequence);
        enemy.setPlayer(player);
        enemy.setCombatAI(enemyAI);
        enemy.setPlatforms(platforms);
        player.addEnemy(enemy);

        // create the enemy
        var combatSequence2:Array<AIAction> = [AIAction.LIGHT_ACTION, AIAction.LIGHT_ACTION, AIAction.HEAVY_ACTION, AIAction.BLOCK_ACTION, AIAction.PARRY_ACTION, AIAction.IDLE_ACTION];
        var statusSequence2:Array<ActionStatus> = [ActionStatus.BLOCKED, ActionStatus.BLOCKED, ActionStatus.PARRIED, ActionStatus.BLOCK_HIT, ActionStatus.PARRY_HIT, ActionStatus.INTERRUPTED];
        enemy2 = new Enemy(500, 0, player);
        enemyAI2 = new SequentialActionDecider(enemy2, player, combatSequence2, statusSequence2);
        enemy2.setPlayer(player);
        enemy2.setCombatAI(enemyAI2);
        enemy2.setPlatforms(platforms);
        player.addEnemy(enemy2);

        // create the enemy
        var combatSequence3:Array<AIAction> = [AIAction.LIGHT_ACTION, AIAction.LIGHT_ACTION, AIAction.HEAVY_ACTION, AIAction.BLOCK_ACTION, AIAction.PARRY_ACTION, AIAction.IDLE_ACTION];
        var statusSequence3:Array<ActionStatus> = [ActionStatus.BLOCKED, ActionStatus.BLOCKED, ActionStatus.PARRIED, ActionStatus.BLOCK_HIT, ActionStatus.PARRY_HIT, ActionStatus.INTERRUPTED];
        enemy3 = new Enemy(850, 0, player);
        enemyAI3 = new SequentialActionDecider(enemy3, player, combatSequence3, statusSequence3);
        enemy3.setPlayer(player);
        enemy3.setCombatAI(enemyAI3);
        enemy3.setPlatforms(platforms);
        player.addEnemy(enemy3);

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

        // create health bar
        enemyHealthBar2 = new FlxBar(0, 0, LEFT_TO_RIGHT, 70, 10, enemy2, "health", 0, 100, true);
        enemyHealthBar2.createFilledBar(FlxColor.WHITE, FlxColor.RED, true);
        enemyHealthBar2.trackParent(175, 0);

        // create stamina bar
        enemyStaminaBar2 = new FlxBar(0, 0, LEFT_TO_RIGHT, 70, 10, enemy2, "stamina", 0, 100, true);
        enemyStaminaBar2.createFilledBar(FlxColor.WHITE, FlxColor.GREEN, true);
        enemyStaminaBar2.trackParent(175, 20);

        // create health bar
        enemyHealthBar3 = new FlxBar(0, 0, LEFT_TO_RIGHT, 70, 10, enemy3, "health", 0, 100, true);
        enemyHealthBar3.createFilledBar(FlxColor.WHITE, FlxColor.RED, true);
        enemyHealthBar3.trackParent(175, 0);

        // create stamina bar
        enemyStaminaBar3 = new FlxBar(0, 0, LEFT_TO_RIGHT, 70, 10, enemy3, "stamina", 0, 100, true);
        enemyStaminaBar3.createFilledBar(FlxColor.WHITE, FlxColor.GREEN, true);
        enemyStaminaBar3.trackParent(175, 20);

        // set a background color
        bgColor = FlxColor.GRAY;

        // construct the scene
        add(enemy.hitArea);
        add(enemy);
        add(enemy2.hitArea);
        add(enemy2);
        add(enemy2.effects);
        add(enemy3.hitArea);
        add(enemy3);
        add(enemy3.effects);
        add(player.hitArea);
        add(player);
        add(player.effects);
        add(enemy.effects);
        add(exitButton);

        // Initialize nextLevel and curLevel variable
        nextLevel = Level3;
        curLevel = Level2;

        
        levelScreen = new FlxSprite();
        levelScreen.loadGraphic("assets/images/Level2.png");
        levelScreen.screenCenter(XY);
        levelScreen.scrollFactor.set(0, 0);
        add(levelScreen);
        

        FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON);

        haxe.Timer.delay(splash_screen_delay, 2000);

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
        if (enemy2.health != enemyHealth2) {
            add(enemyHealthBar2);
            enemyHealth2 = enemy2.health;
            enemyHealthTimer2 = 0;
        } else {
            enemyHealthTimer2 += elapsed;
            if (enemyHealthTimer2 > timerMax) {
                remove(enemyHealthBar2);
                enemyHealthTimer2 = 0;
            }
        }
        if (enemy3.health != enemyHealth3) {
            add(enemyHealthBar3);
            enemyHealth3 = enemy3.health;
            enemyHealthTimer3 = 0;
        } else {
            enemyHealthTimer3 += elapsed;
            if (enemyHealthTimer3 > timerMax) {
                remove(enemyHealthBar3);
                enemyHealthTimer3 = 0;
            }
        }

        showStaminaBar(true, player.stamina, playerStaminaBar, elapsed);
        if (enemy2.stamina != enemyStamina2) {
                add(enemyStaminaBar2);
                enemyStamina2 = enemy2.stamina;
                enemyStaminaTimer2 = 0;
        } else {
            enemyStaminaTimer2 += elapsed;
            if (enemyStaminaTimer2 > timerMax) {
                remove(enemyStaminaBar2);
            }
        }
        if (enemy3.stamina != enemyStamina3) {
                add(enemyStaminaBar3);
                enemyStamina3 = enemy3.stamina;
                enemyStaminaTimer3 = 0;
        } else {
            enemyStaminaTimer3 += elapsed;
            if (enemyStaminaTimer3 > timerMax) {
                remove(enemyStaminaBar3);
            }
        }

        remove(killCountText);
        killCountText = new FlxButton(0, 0, "Kill Count: " + FlxG.save.data.killCount.toString());
        killCountText.loadGraphic("assets/images/transparent.png", true, 150, 20);
        killCountText.label.setFormat(null, 16, FlxColor.BLACK);
        killCountText.x = 20;
        killCountText.y = 20;
        add(killCountText);

        if (enemy.health == 0 && enemy2.health == 0 && enemy3.health == 0) {
            Main.LOGGER.logLevelEnd({won: true});
            FlxG.save.data.unlockedThree = true;
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
        FlxG.collide(enemy2.collider, map);
        FlxG.collide(enemy3.collider, map);
    }

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
