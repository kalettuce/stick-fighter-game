package ai;

import actions.AIAction;
import actions.ActionStatus;
import fighter.Enemy;
import fighter.FighterStates;
import fighter.Player;

class SequentialActionDecider extends ActionDecider {
    private var seqIndex:Int;
    public var sequence:Array<AIAction>;
    public var conditionSequence:Array<ActionStatus>;
    private var seqFinished:Bool;

    override public function new (s:Enemy, p:Player, seq:Array<AIAction>, condSeq:Array<ActionStatus>) {
        super(s, p);
        sequence = seq;
        seqIndex = 0;
        seqFinished = false;
        conditionSequence = condSeq;
    }

    // returns true if this combat decider has finished its sequence
    public function finished():Bool {
        return seqFinished;
    }

    public function getSeqIndex():Int {
        return seqIndex;
    }

    override public function nextAction(prevStatus:ActionStatus):AIAction {
        // progress in the sequence if the condition is met
        if (prevStatus == conditionSequence[seqIndex]) {
            seqIndex = (seqIndex + 1) % sequence.length;
            if (seqIndex == 0) {
                seqFinished = true;
            }
        }

        patrolDecision();

        // move if not in range
        if (patrolling || !inRange()) {
            return AIAction.MOVE_ACTION;
        }

        // special case, if player is parried, punish with an attack
        if (prevStatus == PARRY_HIT) {
            if (player.getStatus() == FighterStates.LIGHTPARRIED) {
                return AIAction.HEAVY_ACTION;
            } else {
                return AIAction.LIGHT_ACTION;
            }
        }

        switch (sequence[seqIndex]) {
            case AIAction.PARRY_ACTION:
                // TODO: make a function: attackImminent(), in Player
                if (player.animation.frameIndex == 30) {
                    return sequence[seqIndex];
                } else {
                    return AIAction.IDLE_ACTION;
                }
            case AIAction.LIGHT_ACTION:
                if (self.stamina >= Enemy.LIGHT_STAMINA_USAGE) {
                    return AIAction.LIGHT_ACTION;
                } else {
                    return AIAction.IDLE_ACTION;
                }
            case AIAction.HEAVY_ACTION:
                if (self.stamina >= Enemy.HEAVY_STAMINA_USAGE) {
                    return AIAction.HEAVY_ACTION;
                } else {
                    return AIAction.IDLE_ACTION;
                }
            default: return sequence[seqIndex];
        }
        return sequence[seqIndex];
    }
}