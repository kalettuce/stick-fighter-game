package fighter;

import actions.AIAction;
import actions.ActionStatus;
import ai.ActionDecider;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxDirectionFlags;

class Minion extends FightUnit {
    private static final GRAVITY:Int = 1000;
    private static final ATTACK_RANGE:Int = 100;
    private static final MOVE_VELOCITY:Int = 150;
    private static final ACTION_INTERVAL:Float = 2;
    private static final COLLIDER_OFFSET_X:Int = 104;
    private static final COLLIDER_OFFSET_Y:Int = 58;

    public var player:Player;
    private var playerHit:Bool;

    private var combatAI:ActionDecider;
    private var timeSinceLastAction:Float;
    private var prevActionStatus:ActionStatus;

    override public function new(x:Int = 0, y:Int = 0, player:Player) {
        super(x-COLLIDER_OFFSET_X, y-COLLIDER_OFFSET_Y);
        this.player = player;

        // rendered image
        loadGraphic("assets/images/minion_sprites_render.png", true, 250, 200);
        animation.add("idle", [0, 1], 6);
        animation.add("float", [0, 1], 3);
        animation.add("light", [30, 31, 32, 33, 34, 35, 0], 10, false);
        animation.add("walk", [20, 21, 22, 23, 0], 10);
        animation.add("light-hit", [40, 41, 42], 10, false);
        animation.add("heavy-hit", [40, 41, 42], 7, false);
        animation.add("parried", [40, 40, 40, 41, 41, 42, 42], 7, false);
        animation.add("death", [24, 25, 26], 10, false);
        setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        setFacingFlip(FlxDirectionFlags.RIGHT, true, false);
        animation.play("idle");
        animation.callback = animationFrameCallback;
        animation.finishCallback = animationFinishCallback;

        // collider
        collider = new FlxSprite(x, y);
        collider.loadGraphic("assets/images/minion_sprites_collider.png");
        collider.acceleration.y = GRAVITY;
        collider.maxVelocity.y = GRAVITY;
        collider.active = false;

        // hit detection sprite
        hitArea = new FlxSprite(x-COLLIDER_OFFSET_X, y-COLLIDER_OFFSET_Y);
        hitArea.loadGraphic("assets/images/minion_hit_area.png", true, 250, 200);
        hitArea.animation.add("idle", [0], 10);
        hitArea.animation.add("light", [0, 0, 0, 0, 0, 35, 0], 10, false);
        hitArea.setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        hitArea.setFacingFlip(FlxDirectionFlags.RIGHT, true, false);
        hitArea.alpha = 0.01;

        // effects (leave empty for now)

        // other initializations
        setFacing(FlxDirectionFlags.LEFT);
        stunned = false;
        playerHit = false;
        health = 40;
        timeSinceLastAction = 0.0;
        prevActionStatus = ActionStatus.NEUTRAL;
        dead = false;
        platformIndex = 0;
    }

    /* -------------------------- Queries ------------------------ */
    // minion cannot parry
    override public function isParrying():Bool {
        return false;
    }

    // return the range of this sprite's attack
    override public function getRange():Int {
        return ATTACK_RANGE;
    }

    public function setPlayer(player:Player) {
        this.player = player;
    }

    public function setCombatAI(cAI:ActionDecider) {
        combatAI = cAI;
    }

    private function animationFrameCallback(name:String, frameNumber:Int, frameIndex:Int) {
        if ((status == FighterStates.IDLE || status == FighterStates.WALK) && collider.velocity.y > 0) {
            float();
        } else if (collider.isTouching(FlxDirectionFlags.FLOOR) && collider.velocity.y == 0 && status == FighterStates.AIR) {
            play("idle");
            status = FighterStates.IDLE;
            updatePlatformIndex();
        }
    }

    private function animationFinishCallback(name:String) {
        switch (name) {
            case "light":
                idle();
                playerHit = false;
                status = FighterStates.IDLE;
            case "death":
                dead = true;
            default:
                idle();
                status = FighterStates.IDLE;
        }
    }

    /* ---------------------------------- Actions Functions --------------------------------- */
    private function idle() {
        if (collider.isTouching(FlxDirectionFlags.FLOOR)) {
            play("idle");
            status = FighterStates.IDLE;
        } else if (collider.velocity.y > 0) {
            float();
        }
        collider.velocity.x = 0;
        stunned = false;
    }

    // float in air
    private function float() {
        play("float");
        status = FighterStates.AIR;
        stunned = false;
    }

    private function light() {
        status = FighterStates.LIGHT;
        play("light");
        collider.velocity.x = 0;
        collider.velocity.y = 0;
        stunned = true;
    }

    private function parried() {
        prevActionStatus = ActionStatus.PARRIED;
        play("parried");
        collider.velocity.x = 0;
        stunned = true;
        status = FighterStates.LIGHTPARRIED;
        Main.LOGGER.logLevelAction(LoggingActions.ENEMY_ATTACK_PARRIED, {event: "MINION light attack PARRIED", version: FlxG.save.data.version});
    }

    private function move() {
        play("walk");
        stunned = false;
        if (facing == FlxDirectionFlags.LEFT) {
            collider.velocity.x = -MOVE_VELOCITY;
        } else {
            collider.velocity.x = MOVE_VELOCITY;
        }
        status = FighterStates.WALK;
    }

    /********************************************* Passive Action Functions *********************************************/
    public function lightHit(damage:Float) {
        Main.LOGGER.logLevelAction(LoggingActions.PLAYER_ATTACK_HIT, {event: "PLAYER light attack HIT MINION", version: FlxG.save.data.version});
        status = FighterStates.HITSTUNLIGHT;
        play("light-hit");
        if (prevActionStatus == ActionStatus.NEUTRAL) {
            prevActionStatus = ActionStatus.INTERRUPTED;
        }
        collider.velocity.x = 0;
        collider.velocity.y = 0;
        stunned = true;
        playerHit = false;
        hurt(damage);
    }

    public function heavyHit(damage:Float) {
        Main.LOGGER.logLevelAction(LoggingActions.PLAYER_ATTACK_HIT, {event: "PLAYER heavy attack HIT MINION", version: FlxG.save.data.version});
        status = FighterStates.HITSTUNHEAVY;
        play("heavy-hit");
        if (prevActionStatus == ActionStatus.NEUTRAL) {
            prevActionStatus = ActionStatus.INTERRUPTED;
        }
        collider.velocity.x = 0;
        collider.velocity.y = 0;
        stunned = true;
        playerHit = false;
        hurt(damage);
    }

    public function hitBlocking() {
        prevActionStatus = ActionStatus.BLOCKED;
    }

    public function actions(elapsed:Float) {
        if (stunned || !collider.isTouching(FlxDirectionFlags.FLOOR)) {
            return;
        } else {
            var nextAction = combatAI.nextAction(prevActionStatus, elapsed);
            prevActionStatus = ActionStatus.NEUTRAL;
            switch (nextAction) {
                case AIAction.IDLE_ACTION:
                    idle();
                case AIAction.LIGHT_ACTION:
                    light();
                case AIAction.MOVE_ACTION:
                    move();
                default:
                    idle();
            }
            setFacing(combatAI.getDirection());
        }
    }

    private function hitCheck() {
        if (playerHit || player.isDead()) return;
        if (hitArea.animation.frameIndex != 0) {
            if (FlxG.pixelPerfectOverlap(hitArea, player.collider, 1)) {
                if (player.isParrying()) {
                    parried();
                } else if (player.isBlocking() && status == FighterStates.LIGHT && player.facing != facing) {
                    playerHit = true;
                    player.hitBlock();
                    hitBlocking();
                } else {
                    playerHit = true;
                    player.lightHit(2);
                }
            }
        }
    }

    override public function kill() {
        animation.play("death");
        stunned = true;
        dead = true;
        FlxG.save.data.killCount += 1;
        FlxG.save.data.minionsKilled += 1;
        FlxG.save.flush();
        Main.LOGGER.logLevelAction(LoggingActions.ENEMY_KILLED, {event: "minion killed", version: FlxG.save.data.version});
    }

    // sets the collider to the given location and the other layers to their
    // matching location as well
    override public function setPosition(x:Float = 0, y:Float = 0) {
        final originalX:Float = x - COLLIDER_OFFSET_X;
        final originalY:Float = y - COLLIDER_OFFSET_Y;
        super.setPosition(originalX, originalY);
        hitArea.setPosition(originalX, originalY);
        collider.setPosition(x, y);
    }

    override public function update(elapsed:Float) {
        setPosition(collider.x, collider.y);
        if (!dead) {
            actions(elapsed);
            hitCheck();
        }
        super.update(elapsed);
        collider.update(elapsed);
    }
}