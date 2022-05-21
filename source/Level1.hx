
import actions.AIAction;
import actions.ActionStatus;
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
    var timerMax:Float = 5;

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

    override public function create() {
        // add the terrain
        map = new FlxTilemap();
        map.loadMapFromCSV("assets/levels/level1_terrain.csv", "assets/images/sf_level_tiles.png", 64, 64);
        FlxG.camera.setScrollBoundsRect(0, 0, map.width, map.height);
        FlxG.worldBounds.set(0, 0, map.width, map.height);
        add(map);

        // create the player character
        player = new Player();

        // create the enemy
        var combatSequence:Array<AIAction> = [AIAction.ATTACK_ACTION, AIAction.ATTACK_ACTION, AIAction.ATTACK_ACTION, AIAction.BLOCK_ACTION, AIAction.PARRY_ACTION, AIAction.IDLE_ACTION];
        var statusSequence:Array<ActionStatus> = [ActionStatus.BLOCKED, ActionStatus.BLOCKED, ActionStatus.PARRIED, ActionStatus.BLOCK_HIT, ActionStatus.PARRY_HIT, ActionStatus.INTERRUPTED];
        enemy = new Enemy(700, 0, player);
        enemy.setPlayer(player);
        enemy.setCombatAI(new SequentialActionDecider(enemy, player, combatSequence, statusSequence));
        //enemy.setCombatAI(new ActionDecider(enemy, player));
        player.addEnemy(enemy);

        exitButton = new FlxButton(0, 0, "Exit", exit);
        exitButton.scale.set(3, 3);
        exitButton.updateHitbox();
        exitButton.label.setFormat(null, 18, FlxColor.BLACK);
        exitButton.label.fieldWidth = exitButton.width;
        exitButton.label.alignment = "center";
        exitButton.label.offset.y -= 15;
        exitButton.screenCenter(X);
        exitButton.y = 40;

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

        // create stamina bar
        enemyStaminaBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 100, 10, enemy, "stamina", 0, 100, true);
        enemyStaminaBar.createFilledBar(FlxColor.BLUE, FlxColor.YELLOW, true);
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

        FlxG.camera.follow(player, FlxCameraFollowStyle.LOCKON);

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

        showHealthBar(true, player.health, playerHealthBar, elapsed);
        showHealthBar(false, enemy.health, enemyHealthBar, elapsed);

        showStaminaBar(true, player.stamina, playerStaminaBar, elapsed);
        // showStaminaBar(false, enemy.stamina, enemyStaminaBar, elapsed);

        if (enemy.health == 0) {
            Main.LOGGER.logLevelEnd({won: true});
            FlxG.save.data.unlockedTwo = true;
            FlxG.save.flush();
            FlxG.switchState(new Level2());
        }

        if (player.health == 0) {
            Main.LOGGER.logLevelEnd({won: false});
            FlxG.switchState(new MenuState());
        }

        FlxG.collide(player.collider, map);
        FlxG.collide(enemy.collider, map);
    }
}
