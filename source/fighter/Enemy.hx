package fighter;

import actions.AIAction;
import actions.ActionDecider;
import actions.ActionStatus;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;

class Enemy extends FightUnit {
    private static final GRAVITY:Int = 1000;
    private static final ATTACK_RANGE:Int = 145;
    private static final MOVE_VELOCITY:Int = 200;
    private static final ACTION_INTERVAL:Float = 2;
    private static final STAMINA_RECOVERY_RATE:Int = 16;

    private static final COLLIDER_OFFSET_X:Int = 127;
    private static final COLLIDER_OFFSET_Y:Int = 104;

    public var stamina:Float;

    // enemy of the Enemy class
    public var player:Player;
    private var playerHit:Bool;

    /************************* Combat AI ****************************/
    private var combatAI:ActionDecider;

    // help compute the time to advance to next action
    private var timeSinceLastAction:Float;
    private var prevActionStatus:ActionStatus;

    override public function new(x:Int = 0, y:Int = 0, player:Player) {
        super(x, y);

        // rendered image
        loadGraphic("assets/images/sword_sprites_render.png", true, 300, 350);
        animation.add("idle", [1, 2, 3, 0], 10);
        animation.add("parry", [4, 5, 6, 7, 8, 9], 10, false);
        animation.add("jump", [0, 10, 11], 10, false);
        animation.add("float", [11], 10);
        animation.add("land", [10, 0], 10, false);
        animation.add("walk", [20, 21, 22, 23, 0], 10);
        animation.add("light", [0, 30, 31, 32, 33, 34, 35, 0], 10, false);
        animation.add("hit", [40, 41, 42, 0], 10, false);
        animation.add("parried", [12, 13, 14, 15, 16, 17, 0], 5, false);
        animation.add("block", [18], 10);
        animation.add("death", [24, 25, 26], 10, false);
        setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        setFacingFlip(FlxDirectionFlags.RIGHT, true, false);
        animation.play("idle");
        animation.finishCallback = animationFinishCallback;

        // collider
        collider = new FlxSprite(x+COLLIDER_OFFSET_X, y+COLLIDER_OFFSET_Y);
        collider.loadGraphic("assets/images/sword_sprites_collider.png");

        collider.acceleration.y = GRAVITY;
        collider.maxVelocity.y = GRAVITY;
        collider.active = false;

        // hit detection sprite
        hitArea = new FlxSprite(x, y);
        hitArea.loadGraphic("assets/images/sword_hit_area.png", true, 300, 350);
        hitArea.animation.add("idle", [0], 10);
        hitArea.animation.add("light", [0, 0, 0, 0, 0, 34, 35, 0], 10, false);
        hitArea.setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        hitArea.setFacingFlip(FlxDirectionFlags.RIGHT, true, false);
        hitArea.animation.play("idle");
        hitArea.alpha = 0.01;

        // effects
        effects = new FlxSprite(x, y);
        effects.loadGraphic("assets/images/sword_effect.png", true, 300, 350);
        effects.animation.add("idle", [0], 10);
        effects.animation.add("hit_block", [1, 2, 3, 4, 5, 6, 7], 25, false);
        effects.animation.callback = effectsAnimationFrameCallback;
        effects.animation.finishCallback = effectsAnimationFinishCallback;
        effects.setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        effects.setFacingFlip(FlxDirectionFlags.RIGHT, true, false);
        effects.animation.play("idle");

        // other initializations
        setFacing(FlxDirectionFlags.LEFT);
        stunned = false;
        playerHit = false;
        health = 100;
        stamina = 100;
        timeSinceLastAction = 0.0;
        prevActionStatus = ActionStatus.NEUTRAL;
        dead = false;
    }

    /* -------------------------- Queries ------------------------ */
    override public function isParrying():Bool {
        return animation.frameIndex == 5 || animation.frameIndex == 6;
    }
    
    // return the range of the sprite's attack
    override public function getRange():Int {
        return ATTACK_RANGE;
    }

    public function setPlayer(player:Player) {
        this.player = player;
    }

    public function setCombatAI(cAI:ActionDecider) {
        combatAI = cAI;
    }


    private function animationFinishCallback(name:String) {
        switch (name) {
            case "jump":
                animation.play("float");
                stunned = true;
                status = FighterStates.AIR;
            case "light":
                idle();
                playerHit = false;
                status = FighterStates.IDLE;
            default:
                idle();
                status = FighterStates.IDLE;
        }
    }
    private function effectsAnimationFrameCallback(name:String, frameNumber:Int, frameIndex:Int) {
        switch (name) {
            case "hit_block": collider.velocity.x = 0;
            default:
        }
    }

    private function effectsAnimationFinishCallback(name:String) {
       effects.animation.play("idle");
    }

    /********************************************* Actions Functions *********************************************/
    private function idle() {
        play("idle");
        collider.velocity.x = 0;
        stunned = false;
        status = FighterStates.IDLE;
    }

    private function light() {
        status = FighterStates.LIGHT;
        play("light");
        collider.velocity.x = 0;
        stunned = true;
    }

    private function block() {
        play("block");
        collider.velocity.x = 0;
        stunned = false;
        status = FighterStates.BLOCK;
    }

    private function parry() {
        play("parry");
        collider.velocity.x = 0;
        stunned = true;
        status = FighterStates.PARRY;
    }

    private function parried() {
        prevActionStatus = ActionStatus.PARRIED;
        play("parried");
        collider.velocity.x = 0;
        stunned = true;
        if (status == FighterStates.LIGHT) {
            status = FighterStates.LIGHTPARRIED;
        } else {
            status = FighterStates.HEAVYPARRIED;
        }
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
    // should be called when "this" enemy is hit
    public function hit(damage:Float) {
        play("hit");
        prevActionStatus = ActionStatus.INTERRUPTED;
        collider.velocity.x = 0;
        stunned = true;
        playerHit = false;
        hurt(damage);
    }

    // should be called when "this" enemy is hit while blocking
    public function hitBlock() {
        effects.animation.play("hit_block");
        prevActionStatus = ActionStatus.BLOCK_HIT;
        if (facing == FlxDirectionFlags.LEFT) {
            collider.velocity.x = 150;
        } else {
            collider.velocity.x = -150;
        }
    }

    // should be called when "this" enmemy hits the player while blocking
    public function hitBlocking() {
        prevActionStatus = ActionStatus.BLOCKED;
    }

    public function hitParry() {
        prevActionStatus = ActionStatus.PARRY_HIT;
    }

    // synchronized positions across all sprites related to the enemy class with the collider
    private function syncPositions() {
        setPosition(collider.x, collider.y);
    }

    private function actions(elapsed:Float) {
        if (stunned || !collider.isTouching(FlxDirectionFlags.FLOOR)) {
            return;
        } else {
            // execute a new action if we're ready
            var nextAction = combatAI.nextAction(prevActionStatus);
            switch (nextAction) {
                case AIAction.IDLE_ACTION:
                    idle();
                case AIAction.ATTACK_ACTION:
                    light();
                case AIAction.BLOCK_ACTION:
                    block();
                case AIAction.PARRY_ACTION:
                    parry();
                case AIAction.MOVE_ACTION:
                    move();
            }
            setFacing(combatAI.getDirection());
            prevActionStatus = ActionStatus.NEUTRAL;
        }
    }

    private function hitCheck() {
        if (playerHit || player.isDead()) return;
        trace("hit checking");
        if (animation.frameIndex == 34 || animation.frameIndex == 35) {
            trace("at hit check frame");
            trace("HA index: " + hitArea.animation.frameIndex);
            trace("Anim index: " + animation.frameIndex);
            if (FlxG.pixelPerfectOverlap(hitArea, player.collider, 1)) {
                trace("collision confirmed");
                if (player.isParrying()){
                    trace("s1");
                    parried();
                } else if (player.isBlocking()) {
                    trace("s2");
                    playerHit = true;
                    player.hitBlock();
                    hitBlocking();
                } else {
                    trace("s3");
                    playerHit = true;
                    player.lightHit(10);
                }
            }
        }
    }

    // sets the collider to the given location and the other layers to their
    // matching location as well
    override public function setPosition(x:Float = 0, y:Float = 0) {
        final originalX:Float = x - COLLIDER_OFFSET_X;
        final originalY:Float = y - COLLIDER_OFFSET_Y;
        super.setPosition(originalX, originalY);
        hitArea.setPosition(originalX, originalY);
        effects.setPosition(originalX, originalY);
        collider.setPosition(x, y);
    }

    override public function kill() {
        animation.play("death");
        stunned = true;
        dead = true;
    }

    override public function update(elapsed:Float) {
        if (FlxG.keys.justPressed.U) {
            combatAI.print();
        }
        
        // recovers stamina if not attacking
        if (animation.name != "light" && animation.name != "heavy") {
            stamina = Math.min(stamina + elapsed * STAMINA_RECOVERY_RATE, 100);
        }
        setPosition(collider.x, collider.y);
        actions(elapsed);
        hitCheck();
        super.update(elapsed);
        collider.update(elapsed);
    }
}