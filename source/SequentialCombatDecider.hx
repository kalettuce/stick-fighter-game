import actions.AIAction;
import actions.ActionStatus;

class SequentialCombatDecider extends CombatDecider {
    private var seqIndex:Int;
    public var sequence:Array<AIAction>;

    override public function new (s:Enemy, p:Player, seq:Array<AIAction>) {
        super(s, p);
        sequence = seq;
        seqIndex = 0;
    }

    // returns true if this combat decider has finished its sequence
    public function finished():Bool {
        return seqIndex >= 0;
    }

    override public function nextAction(prevStatus:ActionStatus):AIAction {
        if (prevStatus == ActionStatus.FAILURE) {
            seqIndex = seqIndex + 1 > sequence.length ? sequence.length : seqIndex + 1;
        }

        if (seqIndex == sequence.length) {
            return AIAction.IDLE_ACTION;
        } else {
            return sequence[seqIndex];
        }
    }
}