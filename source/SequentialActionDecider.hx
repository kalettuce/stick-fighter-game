import actions.AIAction;
import actions.ActionStatus;
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
        // move if not in range
        if (!inRange()) {
            return AIAction.MOVE_ACTION;
        }

        // get the next action in sequence if the condition is met
        if (prevStatus == conditionSequence[seqIndex]) {
            seqIndex = (seqIndex + 1) % sequence.length;
        }
        return sequence[seqIndex];
    }
}