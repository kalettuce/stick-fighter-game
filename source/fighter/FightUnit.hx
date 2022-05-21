package fighter;
import flixel.FlxSprite;
import flixel.util.FlxDirectionFlags;

// an abstract class, but offers no compile-time checking since Haxe does not
// support an abstract class.
// most methods are expected to be overriden when extending from this class
class FightUnit extends FlxSprite {
    // layers
    public var collider:FlxSprite; // to compute collision
    public var hitArea:FlxSprite; // to compute hitbox collision
    public var effects:FlxSprite; // to show other visual effects

    // whether the character is in an un-interruptable animation
    private var stunned:Bool;

    // true if the character is considered "dead"
    private var dead:Bool;
    private var status:FighterStates;

    // constructor, spawns the unit at the given coordinates.
    // Needs to be overriden to initialize all layers
    public function new(x:Int = 0, y:Int = 0) {
        super(x, y);
        stunned = false;
        dead = false;
        status = FighterStates.IDLE;
    }

    /* --------------------- Queries ------------------- */

    // note, this is different from (status == FighterStates.PARRY)
    // the PARRY state only means that the unit is in the "parry" animation
    // but this function should only return true when this unit is in the correct
    // frames when the parry is active
    // i.e. if this unit is hit when this function returns true, the attacker
    // will be parried and put off balance
    public function isParrying():Bool {
        return false;
    }

    public function isBlocking():Bool {
        return status == FighterStates.BLOCK;
    }

    public function isDead():Bool {
        return dead;
    }

    // retunrs the x-coordinate of the center of this unit
    public function getCenter():Float {
        return collider.x + (collider.width / 2);
    }

    // returns the attack range of this unit (computed from the center)
    public function getRange():Float {
        return 0;
    }

    public function getStatus():FighterStates {
        return status;
    }

    /* -------------------- Internal helper functions ---------------- */

    // plays the given animation on "this", also plays on the hitArea layer
    // if the status of this unit is any form of attack (LIGHT or HEAVY)
    private function play(name:String) {
        animation.play(name);
        if (status == FighterStates.LIGHT || status == FighterStates.HEAVY) {
            hitArea.animation.play(name);
        }
    }

    private function setFacing(direction:FlxDirectionFlags) {
        facing = direction;
        hitArea.facing = direction;
        effects.facing = direction;
    }
}