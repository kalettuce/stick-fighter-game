import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;


class Enemy extends FlxSprite {
    private static final COLLIDER_OFFSET_X:Int = 127;
    private static final COLLIDER_OFFSET_Y:Int = 104;

    private static final GRAVITY:Int = 1000;

    // to compute the collision
    public var collider:FlxSprite;

    // to detect attacks
    public var hitArea:FlxSprite;

    // whether the character can interrupt the current animation and perform other actions right now
    public var stunned:Bool;

    // enemy of the Enemy class
    public var player:Player;
    private var playerHit:Bool;

    // a random number generator for AI decisions
    private var random:FlxRandom;

    public function new (x:Int = 0, y:Int = 0) {
        super(x, y);
        random = new FlxRandom();

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
        hitArea = new FlxSprite();
        hitArea.loadGraphic("assets/images/sword_hit_area.png", true, 300, 350);
        hitArea.animation.add("idle", [0, 1, 2, 3, 4], 10);
        hitArea.animation.add("jump", [11, 12, 13], 10, false);
        hitArea.animation.add("float", [13], 10);
        hitArea.animation.add("land", [15, 16], 10, false);
        hitArea.animation.add("walk", [20, 21, 22, 23, 24, 25], 8);
        hitArea.animation.add("high_attack", [0, 0, 0, 0, 0, 34, 35, 0], 10, false);
        hitArea.animation.add("hit", [40, 41, 42, 43, 44], 12, false);
        hitArea.animation.add("parried", [40, 41, 42, 43, 44], 5, false);
        hitArea.setFacingFlip(FlxDirectionFlags.LEFT, false, false);
        hitArea.setFacingFlip(FlxDirectionFlags.RIGHT, true, false);
        hitArea.animation.play("idle");

        // other initializations
        stunned = false;
        playerHit = false;
        health = 100;
    }

    public function isParrying():Bool {
        return true;
    }

    public function setPlayer(player:Player) {
        this.player = player;
    }

    private function animationFinishCallback(name:String) {
        switch (name) {
            case "jump":
                animation.play("float");
            case "land":
                animation.play("idle");
            case "high_attack":
                stunned = false;
                playerHit = false;
                play("idle");
            case "hit":
                stunned = false;
                play("idle");
            case "parried":
                stunned = false;
                play("idle");
        }
    }

    public function play(name:String) {
        animation.play(name);
        hitArea.animation.play(name);
    }

    // should be called when "this" enemy is hit
    public function hit() {
        play("hit");
        stunned = true;
        playerHit = false;
        hurt(20);
    }

    // synchronized positions across all sprites related to the enemy class with the collider
    private function syncPositions() {
        setPosition(collider.x-COLLIDER_OFFSET_X, collider.y-COLLIDER_OFFSET_Y);
    }

    private function actions() {
        if (stunned) return;

        if (animation.name == "idle") {
            if (random.bool(3)) {
                play("high_attack");
                stunned = true;
            }
        }
    }

    private function hitCheck() {
        if (playerHit) return;
        if (animation.frameIndex == 34 || animation.frameIndex == 35) {
            if (FlxG.pixelPerfectOverlap(hitArea, player.collider)) {
                if (player.isParrying()){
                    play("parried");
                    stunned = true;
                } else {
                    playerHit = true;
                    player.hit();
                }
            }
        }
    }

    override public function setPosition(x:Float = 0, y:Float = 0) {
        super.setPosition(x, y);
        hitArea.setPosition(x, y);
        collider.setPosition(x+COLLIDER_OFFSET_X, y+COLLIDER_OFFSET_Y);
    }

    override public function update(elapsed:Float) {
        if (health <= 0) {
            kill();
        }
        actions();
        hitCheck();
        super.update(elapsed);
        syncPositions();
        collider.update(elapsed);
    }
}