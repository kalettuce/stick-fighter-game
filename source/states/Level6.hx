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

class Level6 extends FlxState {
    var player:Player;
    var enemy:Enemy;
    var enemyAI:RandomActionDecider;
    var enemy2:Enemy;
    var enemyAI2:RandomActionDecider;
    var enemy3:Enemy;
    var enemyAI3:RandomActionDecider;
    var minions:Set<Minion>;
    var map:FlxTilemap;
    var doors:FlxTilemap;
    var doorsRemoved:Bool = false;
    var exitButton:FlxButton;
    var timerMax:Float = 5;
    var killCountText:FlxButton;
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
        if (FlxG.save.data.version == "A") {
            mapPath = "assets/levels/level6A_terrain.csv";
        } else {
            mapPath = "assets/levels/level6B_terrain.csv";
            doors = new FlxTilemap();
            doors.loadMapFromCSV("assets/doors/level6B_doors.csv", "assets/images/sf_level_tiles.png", 64, 64);
            add(doors);
        }
        map = new FlxTilemap();
        map.loadMapFromCSV(mapPath, "assets/images/sf_level_tiles.png", 64, 64);
        final platforms:Array<TilePlatform> = TerrainSolver.solveCSVTerrain(mapPath, 64, 64);
        FlxG.camera.setScrollBoundsRect(0, 0, map.width, map.height);
        FlxG.worldBounds.set(0, 0, map.width, map.height);
        add(map);

        // create the player character
        player = new Player(300, 100);
        player.setPlatforms(platforms);

        // create enemy#1
        enemy = new Enemy(1627, 200, player);
        enemyAI = new RandomActionDecider(enemy, player);
        enemyAI.setAttackedWeights([30, 60, 10]);
        enemyAI.setNeutralWeights([70, 25, 5]);
        enemy.setPlayer(player);
        enemy.setCombatAI(enemyAI);
        enemy.setPlatforms(platforms);
        player.addEnemy(enemy);

        // create enemy#2
        enemy2 = new Enemy(600, 200, player);
        enemyAI2 = new RandomActionDecider(enemy2, player);
        enemyAI2.setAttackedWeights([30, 60, 10]);
        enemyAI2.setNeutralWeights([70, 25, 5]);
        enemy2.setPlayer(player);
        enemy2.setCombatAI(enemyAI2);
        enemy2.setPlatforms(platforms);
        player.addEnemy(enemy2);

        // create the enemy
        enemy3 = new Enemy(950, 700, player);
        enemyAI3 = new RandomActionDecider(enemy3, player);
        enemyAI3.setAttackedWeights([30, 60, 10]);
        enemyAI3.setNeutralWeights([70, 25, 5]);
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

        killCountText = new FlxButton(0, 0, "Kill Count: " + FlxG.save.data.killCount.toString());
        killCountText.loadGraphic("assets/images/transparent.png", true, 150, 20);
        killCountText.label.setFormat(null, 16, FlxColor.BLACK);
        killCountText.x = 20;
        killCountText.y = 20;

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

        // create minions
        final xPosArr:Array<Int> = [1700, 1800, 1900, 700, 800, 900, 100, 300, 500, 1150, 1250, 1350, 1050, 1150, 1250, 1800, 2000];
        final yPosArr:Array<Int> = [200, 200, 200, 200, 200, 200, 700, 900, 700, 700, 700, 700, 1400, 1400, 1400, 700, 700];
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
        add(killCountText);

        // Initialize nextLevel and curLevel variable
        nextLevel = MenuState;
        curLevel = Level6;

        levelScreen = new FlxSprite();
        // levelScreen.loadGraphic("assets/images/Level6.png");
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
        killCountText.label.text = "Kill Count: " + FlxG.save.data.killCount.toString();
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

        if (enemy2.isDead() && enemy3.isDead() && FlxG.save.data.version == "B" && !doorsRemoved) {
            remove(doors);
            doorsRemoved = true;
        }

        if (enemy.isDead() && enemy.animation.finished &&
            enemy2.isDead() && enemy2.animation.finished &&
            enemy3.isDead() && enemy3.animation.finished) {
            Main.LOGGER.logLevelEnd({won: true, version: FlxG.save.data.version});

            popupComplete();
        }

        if (player.isDead() && player.animation.finished) {
            Main.LOGGER.logLevelEnd({won: false, version: FlxG.save.data.version});

            level_lost();
        }

        FlxG.collide(player.collider, map);
        FlxG.collide(enemy.collider, map);
        FlxG.collide(enemy2.collider, map);
        FlxG.collide(enemy3.collider, map);
        for (minion in minions) {
            FlxG.collide(minion.collider, map);
        }

        if (FlxG.save.data.version == "B" && !doorsRemoved) {
            FlxG.collide(player.collider, doors);
            FlxG.collide(enemy.collider, doors);
            FlxG.collide(enemy2.collider, doors);
            FlxG.collide(enemy3.collider, doors);
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
