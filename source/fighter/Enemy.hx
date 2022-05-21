package fighter;

import actions.AIAction;
import actions.ActionStatus;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;

class Enemy extends FlxSprite {
    private static final COLLIDER_OFFSET_X:Int = 127;
    private static final COLLIDER_OFFSET_Y:Int = 104;
    private static final GRAVITY:Int = 1000;
    private static final ATTACK_RANGE:Int = 145;
    private static final MOVE_VELOCITY:Int = 200;
    private static final ACTION_INTERVAL:Float = 2;

    // to compute the collision
    public var collider:FlxSprite;

    // to detect attacks
    public var hitArea:FlxSprite;

    // effects layer independent of the character sprites
    public var effects:FlxSprite;

    // whether the character can interrupt the current animation and perform other actions right now
    public var stunned:Bool;

    // enemy of the Enemy class
    public var player:Player;
    private var playerHit:Bool;

    // true if "this" enemy is dead
    private var dead:Bool;

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
        animation.add("high_attack", [0, 30, 31, 32, 33, 34, 35, 0], 10, false);
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
        hitArea.animation.add("high_attack", [0, 0, 0, 0, 0, 34, 35, 0], 10, false);
        hitArea.setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        hitArea.setFacingFlip(FlxDirectionFlags.RIGHT, true, false);
        hitArea.animation.play("idle");
        hitArea.alpha = 0.01;

        // effects
        effects = new FlxSprite(x, y);
        effects.loadGraphic("assets/images/sword_effect.png", true, 300, 350);
        effects.animation.add("idle", [0], 10);
        effects.animation.add("hit_block", [1, 2, 3, 4, 5, 6, 7], 25, false);
        effects.animation.finishCallback = function(name:String) {effects.animation.play("idle");};
        effects.setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        effects.setFacingFlip(FlxDirectionFlags.RIGHT, true, false);
        effects.animation.play("idle");

        // other initializations
        setFacing(FlxDirectionFlags.LEFT);
        stunned = false;
        playerHit = false;
        health = 100;
        timeSinceLastAction = 0.0;
        prevActionStatus = ActionStatus.NEUTRAL;
        dead = false;
    }

    public function isBlocking():Bool {
        return animation.frameIndex == 18;
    }

    public function isParrying():Bool {
        return animation.frameIndex == 5 || animation.frameIndex == 6;
    }

    public function isDead():Bool {
        return dead;
    }

    public function setPlayer(player:Player) {
        this.player = player;
    }

    public function setCombatAI(cAI:ActionDecider) {
        combatAI = cAI;
    }

    // return the x coordinate of center point of the sprite
    public function getCenter():Float {
        return collider.x + (collider.width / 2);
    }

    // return the range of the sprite's attack
    public function getRange():Int {
        return ATTACK_RANGE;
    }

    private function animationFinishCallback(name:String) {
        switch (name) {
            case "jump":
                animation.play("float");
                stunned = true;
            case "land":
                idle();
            case "high_attack":
                idle();
                playerHit = false;
            case "hit":
                idle();
            case "parry":
                idle();
            case "parried":
                idle();
        }
    }

    public function play(name:String) {
        animation.play(name);
        if (name == "high_attack") {
            hitArea.animation.play(name);
        } else {
            hitArea.animation.play("idle");
        }
    }

    /********************************************* Actions Functions *********************************************/
    private function idle() {
        play("idle");
        collider.velocity.x = 0;
        stunned = false;
    }

    private function attack() {
        play("high_attack");
        collider.velocity.x = 0;
        stunned = true;
    }

    private function block() {
        play("block");
        collider.velocity.x = 0;
        stunned = false;
    }

    private function parry() {
        play("parry");
        collider.velocity.x = 0;
        stunned = true;
    }

    private function parried() {
        prevActionStatus = ActionStatus.PARRIED;
        play("parried");
        collider.velocity.x = 0;
        stunned = true;
    }

    private function move() {
        play("walk");
        stunned = false;

        if (facing == FlxDirectionFlags.LEFT) {
            collider.velocity.x = -MOVE_VELOCITY;
        } else {
            collider.velocity.x = MOVE_VELOCITY;
        }
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
            setPosition(x + 10, y);
        } else {
            setPosition(x - 10, y);
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
        setPosition(collider.x-COLLIDER_OFFSET_X, collider.y-COLLIDER_OFFSET_Y);
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
                    attack();
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

    private function setFacing(direction:FlxDirectionFlags) {
        facing = direction;
        hitArea.facing = direction;
        effects.facing = direction;
    }

    private function hitCheck() {
        if (playerHit || player.isDead()) return;
        if (animation.frameIndex == 34 || animation.frameIndex == 35) {
            if (FlxG.pixelPerfectOverlap(hitArea, player.collider, 1)) {
                if (player.isParrying()){
                    parried();
                } else if (player.isBlocking()) {
                    playerHit = true;
                    player.hitBlock();
                    hitBlocking();
                } else {
                    playerHit = true;
                    player.lightHit(10);
                }
            }
        }
    }

    override public function setPosition(x:Float = 0, y:Float = 0) {
        super.setPosition(x, y);
        hitArea.setPosition(x, y);
        effects.setPosition(x, y);
        collider.setPosition(x+COLLIDER_OFFSET_X, y+COLLIDER_OFFSET_Y);
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

        actions(elapsed);
        hitCheck();
        super.update(elapsed);
        syncPositions();
        collider.update(elapsed);
    }
}