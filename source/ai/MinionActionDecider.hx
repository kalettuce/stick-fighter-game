package ai;

import actions.AIAction;
import actions.ActionStatus;
import fighter.Enemy;
import fighter.FighterStates;
import fighter.Minion;
import fighter.Player;
import flixel.math.FlxRandom;
import flixel.util.FlxDirectionFlags;

class MinionActionDecider extends ActionDecider {
    // actions that can be taken when player is not attacking
    public static final ACTION_LIST:Array<AIAction> = [AIAction.IDLE_ACTION, AIAction.LIGHT_ACTION];
    private static final random:FlxRandom = new FlxRandom(); 

    private var actionWeights:Array<Float>;

    // to help maintain a pose so that there isn't too many sudden movements
    private var prevPlayerStatus:FighterStates;
    private var prevAction:AIAction;
    private var prevDuration:Float;

    private var minionSelf:Minion;


    override public function new (s:Minion, p:Player) {
        super(null, p);
        actionWeights = [50, 50];
        minionSelf = s;
        prevPlayerStatus = null;
        prevAction = null;
        prevDuration = 0;
    }

    public function setActionWeights(weights:Array<Float>) {
        actionWeights = weights;
    }

    // set the current action to last the given duration
    private function setDuration(action:AIAction, duration:Float) {
        prevPlayerStatus = player.getStatus();
        prevDuration = duration;
        prevAction = action;
    }

    override public function nextAction(prevStatus:ActionStatus, elapsed:Float):AIAction {
        patrolDecision();

        // move if not in range or patrolling
        if (patrolling || !inRange()) {
            return AIAction.MOVE_ACTION;
        }

        final playerStatus:FighterStates = player.getStatus();
        if (playerStatus != prevPlayerStatus || prevDuration < 0) {
            prevPlayerStatus = null;
            prevAction = null;
            prevDuration = 0;
        } else {
            prevDuration -= elapsed;
            return prevAction;
        }

        final action:AIAction = random.getObject(ACTION_LIST, actionWeights);
        if (action == AIAction.IDLE_ACTION) {
            setDuration(action, 1);
        }
        return action;
    }

    /* Overriding ActionDecider functions because of inheritance issues */
    override private function patrolDecision() {
        final selfIndex = minionSelf.getPlatformIndex();
        final playerIndex = player.getPlatformIndex();

        // note: should not be entering this branch because the AI
        // doesn't ask for action when mid-air
        if (selfIndex == -1) return;

        // set patrolling
        if (selfIndex != playerIndex || player.isDead()) {
            patrolling = true;
        } else {
            patrolling = false;
        }
    }

    override public function getDirection():FlxDirectionFlags {

        // patrolling platform
        if (patrolling) {
            final platform:TilePlatform = minionSelf.getPlatform();
            // turn around if on edge of platform
            if (minionSelf.facing == FlxDirectionFlags.LEFT &&
                (minionSelf.collider.x <= platform.xMin || minionSelf.collider.isTouching(FlxDirectionFlags.LEFT))) {
                return FlxDirectionFlags.RIGHT;
            } else if (minionSelf.facing == FlxDirectionFlags.RIGHT &&
                ((minionSelf.collider.x + minionSelf.collider.width) >= platform.xMax || minionSelf.collider.isTouching(FlxDirectionFlags.RIGHT))) {
                return FlxDirectionFlags.LEFT;
            } else {
                return minionSelf.facing;
            }
        }

        // chasing player
        if (minionSelf.getCenter() > player.getCenter()) {
            return FlxDirectionFlags.LEFT;
        } else {
            return FlxDirectionFlags.RIGHT;
        }
    }

    // returns true if the player is in the AI's range
    override public function inRange():Bool {
        return Math.abs(minionSelf.getCenter() - player.getCenter()) <= minionSelf.getRange();
    }

    // returns true if the enemy is in the player's range
    override public function inReverseRange():Bool {
        return Math.abs(minionSelf.getCenter() - player.getCenter()) <= player.getRange();
    }
}