package states;

import actions.AIAction;
import actions.ActionStatus;
import ai.ActionDecider;
import ai.RandomActionDecider;
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
import motion.Actuate;

class Level1 extends FlxState {
    var player:Player;
    var enemy:Enemy;
    var enemyAI:ActionDecider;
    var map:FlxTilemap;
    var exitButton:FlxButton;
    var timerMax:Float = 5;
    var killCountText:FlxButton;
    var levelScreen:FlxSprite;
    var tween:FlxTween;
    var rand:FlxRandom;

    // to prompt according to the sequence
    var prevSeqIndex:Int;
    var promptText:FlxText;
    var promptTimer:Float = 0;

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

    var paused:Bool;

    override public function create() {
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

        paused = false;
        // add the terrain
        map = new FlxTilemap();
        map.loadMapFromCSV("assets/levels/level1_terrain.csv", "assets/images/sf_level_tiles.png", 64, 64);
        final platforms:Array<TilePlatform> = TerrainSolver.solveCSVTerrain("assets/levels/level1_terrain.csv", 64, 64);
        FlxG.camera.setScrollBoundsRect(0, 0, map.width, map.height);
        FlxG.worldBounds.set(0, 0, map.width, map.height);
        add(map);

        // create the player character
        player = new Player(400, 100);
        player.setPlatforms(platforms);

        // create the enemy
        var combatSequence:Array<AIAction> = [AIAction.LIGHT_ACTION, AIAction.LIGHT_ACTION, AIAction.LIGHT_ACTION, AIAction.HEAVY_ACTION, AIAction.HEAVY_ACTION, AIAction.HEAVY_ACTION,
                                              AIAction.BLOCK_ACTION, AIAction.BLOCK_ACTION, AIAction.PARRY_ACTION, AIAction.PARRY_ACTION];
        var statusSequence:Array<ActionStatus> = [ActionStatus.BLOCKED, ActionStatus.BLOCKED, ActionStatus.BLOCKED, ActionStatus.PARRIED, ActionStatus.PARRIED, ActionStatus.PARRIED,
                                                  ActionStatus.INTERRUPTED, ActionStatus.INTERRUPTED, ActionStatus.PARRY_MISS, ActionStatus.PARRY_MISS];
        enemy = new Enemy(1100, 100, player);
        enemyAI = new SequentialActionDecider(enemy, player, combatSequence, statusSequence);
        enemy.setPlayer(player);
        enemy.setCombatAI(enemyAI);
        enemy.setPlatforms(platforms);
        player.addEnemy(enemy);

        // both characters should be invincible until the sequence tutorial is finished
        player.invincible = true;
        enemy.invincible = true;

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

        prevSeqIndex = -1;
        promptText = new FlxText();
        promptText.text = "Welcome to Stick Fighter!";
        promptText.color = FlxColor.BLACK;
        promptText.size = 20;
        promptText.screenCenter(FlxAxes.X);
        promptText.y = 200;

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
        add(promptText);

        // Initialize nextLevel and curLevel variable
        nextLevel = Level2;
        curLevel = Level1;

        // Initialize kill count
        if (!FlxG.save.data.killCount) {
            FlxG.save.data.killCount = 0;
            FlxG.save.flush();
        }

        levelScreen = new FlxSprite();
        levelScreen.loadGraphic("assets/images/Level1.png");
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

    private function pause() {
        paused = true;
        player.active = false;
        player.effects.active = false;
        player.hitArea.active = false;
        enemy.active = false;
        enemy.effects.active = false;
        enemy.hitArea.active = false;
    }

    private function unpause() {
        paused = false;
        player.active = true;
        player.effects.active = true;
        player.hitArea.active = true;
        enemy.active = true;
        enemy.effects.active = true;
        enemy.hitArea.active = true;
    }

    override public function update(elapsed:Float) {
        if (paused && FlxG.keys.justPressed.P) {
            unpause();
            promptText.color = FlxColor.BLACK;
            if (!player.invincible) {
                remove(promptText);
            }
        }
        super.update(elapsed);

        if (player.invincible && cast(enemyAI, SequentialActionDecider).finished()) {
            player.invincible = false;
            enemy.invincible = false;

            promptText.text = "Now face the enemy with what you learned!";
            promptText.color = FlxColor.RED;
            pause();

            final newAI:RandomActionDecider = new RandomActionDecider(enemy, player);
            newAI.setAttackedWeights([30, 60, 10]);
            newAI.setNeutralWeights([70, 25, 5]);
            enemy.setCombatAI(newAI);
        }

        killCountText.label.text = "Kill Count: " + FlxG.save.data.killCount.toString();
        showHealthBar(true, player.health, playerHealthBar, elapsed);
        showHealthBar(false, enemy.health, enemyHealthBar, elapsed);

        showStaminaBar(true, player.stamina, playerStaminaBar, elapsed);
        showStaminaBar(false, enemy.stamina, enemyStaminaBar, elapsed);

        promptTimer += elapsed;
        if (promptTimer >= 2 && player.invincible) {
            final curSeqIndex = cast(enemyAI, SequentialActionDecider).getSeqIndex();
            switch (curSeqIndex) {
                case 0:
                    promptText.text = "The enemy is approaching!\nPress [K] to block incoming attacks (1/3)\nhint: press [P] to unpause the game";
                case 1:
                    promptText.text = "The enemy is approaching!\nPress [K] to block incoming attacks (2/3)";
                case 2:
                    promptText.text = "The enemy is approaching!\nPress [K] to block incoming attacks (3/3)";
                case 3:
                    promptText.text = "The enemy is trying to break through your block with a heavy attack!\nPress [J] while blocking to parry (1/3)";
                case 4:
                    promptText.text = "The enemy is trying to break through your block with a heavy attack!\nPress [J] while blocking to parry (2/3)";
                case 5:
                    promptText.text = "The enemy is trying to break through your block with a heavy attack!\nPress [J] while blocking to parry (3/3)";
                case 6:
                    promptText.text = "The enemy is trying to recover stamina\nPress [I] to break through the block with your own heavy attack (1/2)";
                case 7:
                    promptText.text = "The enemy is trying to recover stamina\nPress [I] to break through the block with your own heavy attack (2/2)";
                case 8:
                    promptText.text = "The enemy learned your moves and is ready to parry you!\nInitiate a heavy attack, and press [E] to cancel to bait the parry (1/2)";
                case 9:
                    promptText.text = "The enemy learned your moves and is ready to parry you!\nInitiate a heavy attack, and press [E] to cancel to bait the parry (2/2)";
            }

            if (prevSeqIndex != curSeqIndex && (curSeqIndex == 0 || curSeqIndex == 3 || curSeqIndex == 6 || curSeqIndex == 8)) {
                pause();
                promptText.color = FlxColor.RED;
            }
            prevSeqIndex = curSeqIndex;
            promptText.screenCenter(FlxAxes.X);
        }

        if (enemy.isDead() && enemy.animation.finished) {
            Main.LOGGER.logLevelEnd({won: true});
            FlxG.save.data.unlockedTwo = true;
            FlxG.save.flush();

            popupComplete();
        }

        if (player.isDead() && player.animation.finished) {
            Main.LOGGER.logLevelEnd({won: false});

            level_lost();
        }

        FlxG.collide(player.collider, map);
        FlxG.collide(enemy.collider, map);
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
