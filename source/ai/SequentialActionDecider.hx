package ai;

import actions.AIAction;
import actions.ActionStatus;
import fighter.Enemy;
import fighter.Player;
import flixel.input.actions.FlxActionManager.ActionSetJson;

class SequentialActionDecider extends ActionDecider {
    private var seqIndex:Int;
    public var sequence:Array<AIAction>;
    public var conditionSequence:Array<ActionStatus>;

    override public function new (s:Enemy, p:Player, seq:Array<AIAction>, condSeq:Array<ActionStatus>) {
        super(s, p);
        sequence = seq;
        seqIndex = 0;
        conditionSequence = condSeq;
    }

    // returns true if this combat decider has finished its sequence
    public function finished():Bool {
        return seqIndex >= 0;
    }

    override public function nextAction(prevStatus:ActionStatus):AIAction {
        // progress in the sequence if the condition is met
        if (prevStatus == conditionSequence[seqIndex]) {
            seqIndex = (seqIndex + 1) % sequence.length;
        }

        patrolDecision();

        // move if not in range
        if (patrolling || !inRange()) {
            return AIAction.MOVE_ACTION;
        }

        // special case, if player is parried, punish with an attack
        if (prevStatus == PARRY_HIT) {
            return AIAction.ATTACK_ACTION;
        }

        switch (sequence[seqIndex]) {
            case AIAction.PARRY_ACTION:
                // TODO: make a function: attackImminent(), in Player
                if (player.animation.frameIndex == 30) {
                    return sequence[seqIndex];
                } else {
                    return AIAction.IDLE_ACTION;
                }
            default: return sequence[seqIndex];
        }
        return sequence[seqIndex];
    }
}