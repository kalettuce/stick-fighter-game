package ai;

import actions.AIAction;
import actions.ActionStatus;
import fighter.Enemy;
import fighter.FighterStates;
import fighter.Player;
import flixel.math.FlxRandom;

class RandomActionDecider extends ActionDecider {
    // actions that can be taken when player is not attacking
    public static final NEUTRAL_LIST:Array<AIAction> = [AIAction.IDLE_ACTION, AIAction.LIGHT_ACTION, AIAction.HEAVY_ACTION];
    // actions that can be taken when player is attacking
    public static final ATTACKED_LIST:Array<AIAction> = [AIAction.IDLE_ACTION, AIAction.BLOCK_ACTION, AIAction.PARRY_ACTION];

    private static final random:FlxRandom = new FlxRandom(); 

    private var pendingNeutralAction:AIAction;
    private var pendingAttackedAction:AIAction;
    private var neutralWeights:Array<Float>;
    private var attackedWeights:Array<Float>;

    // to help maintain a pose so that there isn't too many sudden movements
    private var prevPlayerStatus:FighterStates;
    private var prevAction:AIAction;
    private var prevDuration:Float;


    override public function new (s:Enemy, p:Player) {
        super(s, p);
        pendingAttackedAction = null;
        pendingNeutralAction = null;
        neutralWeights = null;
        attackedWeights = null;
        prevPlayerStatus = null;
        prevAction = null;
        prevDuration = 0;
    }

    public function setNeutralWeights(weights:Array<Float>) {
        neutralWeights = weights;
    }

    public function setAttackedWeights(weights:Array<Float>) {
        attackedWeights = weights;
    }

    // based on the given array of probabilities, find the next actions
    private function getNextActions() {
        // set neutral action
        if (pendingNeutralAction == null) {
            if (neutralWeights == null) {
                pendingNeutralAction = random.getObject(NEUTRAL_LIST);
            } else {
                pendingNeutralAction = random.getObject(NEUTRAL_LIST, neutralWeights);
            }
        }

        // set attacked action
        if (pendingAttackedAction == null) {
            if (attackedWeights == null) {
                pendingAttackedAction = random.getObject(ATTACKED_LIST);
            } else {
                pendingAttackedAction = random.getObject(ATTACKED_LIST, attackedWeights);
            }
        }
    }

    // set the current action to last the given duration
    private function setDuration(duration:Float) {
        prevPlayerStatus = player.getStatus();
        prevDuration = duration;
        switch (prevPlayerStatus) {
            case FighterStates.LIGHT, FighterStates.HEAVY:
                prevAction = pendingAttackedAction;
            default:
                prevAction = pendingNeutralAction;
        }
    }

    override public function nextAction(prevStatus:ActionStatus, elapsed:Float):AIAction {
        patrolDecision();

        // move if not in range or patrolling
        if (patrolling || !inRange()) {
            return AIAction.MOVE_ACTION;
        }

        // special case, if player is parried, punish with an attack
        if (prevStatus == ActionStatus.PARRY_HIT) {
            if (player.getStatus() == FighterStates.LIGHTPARRIED) {
                return self.stamina > Enemy.HEAVY_STAMINA_USAGE ? AIAction.HEAVY_ACTION : AIAction.IDLE_ACTION;
            } else {
                return self.stamina > Enemy.LIGHT_STAMINA_USAGE ? AIAction.LIGHT_ACTION : AIAction.IDLE_ACTION;
            }
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

        if (pendingAttackedAction == null || pendingNeutralAction == null) {
            getNextActions();
        }
        
        switch (playerStatus) {
            case FighterStates.LIGHT, FighterStates.HEAVY: // player is attacking
                if (pendingAttackedAction == AIAction.PARRY_ACTION) {
                    if (random.bool(5) || player.attackImminent()) {
                        pendingAttackedAction = null;
                        return AIAction.PARRY_ACTION;
                    } else {
                        return AIAction.IDLE_ACTION;
                    }
                } else {
                    setDuration(1);
                    pendingAttackedAction = null;
                    return prevAction;
                }
            default: // player is not attacking
                if (pendingNeutralAction == AIAction.LIGHT_ACTION) {
                    if (self.stamina > Enemy.LIGHT_STAMINA_USAGE) {
                        pendingNeutralAction = null;
                        return AIAction.LIGHT_ACTION;
                    } else {
                        return AIAction.IDLE_ACTION;
                    }
                } else if (pendingNeutralAction == AIAction.HEAVY_ACTION) {
                    if (self.stamina > Enemy.HEAVY_STAMINA_USAGE) {
                        pendingNeutralAction = null;
                        return AIAction.HEAVY_ACTION;
                    } else {
                        return AIAction.IDLE_ACTION;
                    }
                } else {
                    setDuration(1);
                    pendingNeutralAction = null;
                    return prevAction;
                }
        }
    }
}