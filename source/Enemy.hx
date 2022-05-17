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
    private var combatAI:CombatDecider;

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
        prevActionStatus = null;
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

    public function setCombatAI(cAI:CombatDecider) {
        combatAI = cAI;
    }

    private function animationFinishCallback(name:String) {
        switch (name) {
            case "jump":
                animation.play("float");
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
        stunned = false;
    }

    private function attack() {
        play("high_attack");
        stunned = true;
    }

    private function block() {
        play("block");
        stunned = false;
    }

    private function parry() {
        play("parry");
        stunned = true;
    }

    /********************************************* Passive Action Functions *********************************************/
    // should be called when "this" enemy is hit
    public function hit(damage:Float) {
        play("hit");
        stunned = true;
        playerHit = false;
        hurt(damage);
    }

    // should be called when "this" enemy is hit while blocking
    public function hitBlock() {
        effects.animation.play("hit_block");
        if (facing == FlxDirectionFlags.LEFT) {
            setPosition(x + 10, y);
        } else {
            setPosition(x - 10, y);
        }
    }

    // synchronized positions across all sprites related to the enemy class with the collider
    private function syncPositions() {
        setPosition(collider.x-COLLIDER_OFFSET_X, collider.y-COLLIDER_OFFSET_Y);
    }

    private function actions(elapsed:Float) {
        timeSinceLastAction += elapsed;
        if (timeSinceLastAction < ACTION_INTERVAL || stunned) {
            return;
        } else {
            timeSinceLastAction = 0;
            // execute a new action if we're ready
            if (animation.name == "idle" || animation.frameIndex == 18) { // idle or blocking
                var nextAction = combatAI.nextAction(prevActionStatus);
                switch (nextAction) {
                    case IDLE_ACTION:
                        idle();
                    case ATTACK_ACTION:
                        attack();
                    case BLOCK_ACTION:
                        block();
                    case PARRY_ACTION:
                        parry();
                }
                prevActionStatus = FAILURE;
            }
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
            if (FlxG.pixelPerfectOverlap(hitArea, player.collider)) {
                if (player.isParrying()){
                    play("parried");
                    stunned = true;
                } else if (player.isBlocking()) {
                    playerHit = true;
                    player.hitBlock();
                } else {
                    playerHit = true;
                    player.hit(10);
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
        actions(elapsed);
        hitCheck();
        super.update(elapsed);
        syncPositions();
        collider.update(elapsed);
    }
}