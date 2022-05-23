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

    override public function new (s:Enemy, p:Player) {
        super(s, p);
        pendingAttackedAction = null;
        pendingNeutralAction = null;
        neutralWeights = null;
        attackedWeights = null;
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

    override public function nextAction(prevStatus:ActionStatus):AIAction {
        patrolDecision();

        // move if not in range or patrolling
        if (patrolling || !inRange()) {
            return AIAction.MOVE_ACTION;
        }

        // special case, if player is parried, punish with an attack
        if (prevStatus == ActionStatus.PARRY_HIT) {
            if (player.getStatus() == FighterStates.LIGHTPARRIED) {
                return AIAction.HEAVY_ACTION;
            } else {
                return AIAction.LIGHT_ACTION;
            }
        }

        if (pendingAttackedAction == null || pendingNeutralAction == null) {
            getNextActions();
        }
        
        final playerStatus:FighterStates = player.getStatus();
        switch (playerStatus) {
            case FighterStates.LIGHT, FighterStates.HEAVY:
                if (pendingAttackedAction == AIAction.PARRY_ACTION) {
                    if (random.bool(5) || player.attackImminent()) {
                        pendingAttackedAction = null;
                        return AIAction.PARRY_ACTION;
                    } else {
                        return AIAction.IDLE_ACTION;
                    }
                } else {
                    final temp = pendingAttackedAction;
                    pendingAttackedAction = null;
                    return temp;
                }
            default:
                final temp = pendingNeutralAction;
                pendingNeutralAction = null;
                return temp;
        }
    }
}