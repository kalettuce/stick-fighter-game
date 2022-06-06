package states;

import actions.AIAction;
import actions.ActionStatus;
import ai.ActionDecider;
import ai.MinionActionDecider;
import ai.RandomActionDecider;
import ai.SequentialActionDecider;
import ai.TerrainSolver;
import ai.TilePlatform;
import fighter.Enemy;
import fighter.Minion;
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
import flixel.math.FlxRandom;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import helder.Set;
import motion.Actuate;

class Level2 extends FlxState {
    var player:Player;
    var enemy:Enemy;
    var enemyAI:RandomActionDecider;
    var minions:Set<Minion>;
    var rand:FlxRandom;

    var map:FlxTilemap;
    var exitButton:FlxButton;
    var timerMax:Float = 5;
    var killCountText:FlxButton;
    var minKills:Float = 3;
    var minKillsText:FlxButton;
    var levelScreen:FlxSprite;
    var tween:FlxTween;
    var mapPath:String;

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
        // Log start of Level 2
        Main.LOGGER.logLevelStart(2, {version: FlxG.save.data.version});
        FlxG.save.data.minionsKilled = 0;
        FlxG.save.flush();

        // pick version A or B
        if (!FlxG.save.data.version) {
            rand = new FlxRandom();
            if (rand.bool()) {
                FlxG.save.data.version = "A";
            } else {
                FlxG.save.data.version = "B";
            }
            FlxG.save.flush();
        }

        // add the terrain
        mapPath = "assets/levels/level2A_terrain.csv";
        map = new FlxTilemap();
        map.loadMapFromCSV(mapPath, "assets/images/sf_level_tiles.png", 64, 64);
        final platforms:Array<TilePlatform> = TerrainSolver.solveCSVTerrain(mapPath, 64, 64);
        FlxG.camera.setScrollBoundsRect(0, 0, map.width, map.height);
        FlxG.worldBounds.set(0, 0, map.width, map.height);
        FlxG.camera.style = FlxCameraFollowStyle.PLATFORMER;
        add(map);

        // create the player character
        player = new Player(300, 100);
        player.setPlatforms(platforms);
        player.setCamera(FlxG.camera);

        // create enemy
        enemy = new Enemy(1000, 200, player);
        enemyAI = new RandomActionDecider(enemy, player);
        enemyAI.setAttackedWeights([30, 60, 10]);
        enemyAI.setNeutralWeights([70, 25, 5]);
        enemy.setPlayer(player);
        enemy.setCombatAI(enemyAI);
        enemy.setPlatforms(platforms);
        player.addEnemy(enemy);

        // create minions
        final xPosArr:Array<Int> = [700, 800, 900];
        final yPosArr:Array<Int> = [200, 200, 200];
        minions = new Set<Minion>();
        for (i in 0...xPosArr.length) {
            var minion:Minion = new Minion(xPosArr[i], yPosArr[i], player);
            var minionAI:ActionDecider = new MinionActionDecider(minion, player);
            minion.setCombatAI(minionAI);
            minion.setPlatforms(platforms);
            minions.add(minion);
            player.addMinion(minion);
            add(minion.hitArea);
            add(minion);
        }

        exitButton = new FlxButton(0, 0, "Return to Menu", exit);
        exitButton.scale.set(2, 2);
        exitButton.updateHitbox();
        exitButton.label.setFormat(null, 13, FlxColor.BLACK);
        exitButton.label.fieldWidth = exitButton.width;
        exitButton.label.alignment = "center";
        exitButton.label.offset.y -= 8;
        exitButton.x = 1090;
        exitButton.y = 20;

        killCountText = new FlxButton(0, 0, "Kill Count: " + FlxG.save.data.killCount);
        killCountText.loadGraphic("assets/images/transparent.png", true, 150, 20);
        killCountText.label.setFormat(null, 16, FlxColor.BLACK);
        killCountText.x = 20;
        killCountText.y = 20;

        minKillsText = new FlxButton(0, 0, "Minimum Kills: " + (minKills - FlxG.save.data.minionsKilled));
        minKillsText.loadGraphic("assets/images/transparent.png", true, 165, 20);
        minKillsText.label.setFormat(null, 16, FlxColor.BLACK);
        minKillsText.x = 20;
        minKillsText.y = 50;

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
        add(killCountText);
        add(minKillsText);

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
        Main.LOGGER.logActionWithNoLevel(LoggingActions.CLICK_EXIT, {version: FlxG.save.data.version});

        // log level end
        Main.LOGGER.logLevelEnd({won: false, version: FlxG.save.data.version});
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
        killCountText.label.text = "Kill Count: " + FlxG.save.data.killCount;
        minKillsText.label.text = "Minimum Kills: " + (minKills - FlxG.save.data.minionsKilled);
        showHealthBar(true, player.health, playerHealthBar, elapsed);
        showHealthBar(false, enemy.health, enemyHealthBar, elapsed);

        showStaminaBar(true, player.stamina, playerStaminaBar, elapsed);
        if (enemy.stamina != enemyStamina) {
                add(enemyStaminaBar);
                enemyStamina = enemy.stamina;
                enemyStaminaTimer = 0;
        } else {
            enemyStaminaTimer += elapsed;
            if (enemyStaminaTimer > timerMax) {
                remove(enemyStaminaBar);
            }
        }

        if (enemy.isDead() && enemy.animation.finished && (minKills - FlxG.save.data.minionsKilled) == 0) {
            Main.LOGGER.logLevelEnd({won: true, version: FlxG.save.data.version});
            FlxG.save.data.unlockedThree = true;
            FlxG.save.flush();

            popupComplete();
        }

        if (player.isDead() && player.animation.finished) {
            Main.LOGGER.logLevelEnd({won: false, version: FlxG.save.data.version});

            level_lost();
        }

        FlxG.collide(player.collider, map);
        FlxG.collide(enemy.collider, map);
        for (minion in minions) {
            FlxG.collide(minion.collider, map);
        }
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
