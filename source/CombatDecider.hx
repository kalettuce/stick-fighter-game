import actions.AIAction;
import actions.ActionStatus;
import haxe.xml.Check.Attrib;

class CombatDecider {
    // myself, the enemy of the player
    private var self:Enemy;
    private var player:Player;

    public function new (s:Enemy, p:Player) {
        self = s;
        player = p;
    }

    public function nextAction(prevStatus:ActionStatus):AIAction {
        return AIAction.IDLE_ACTION;
    }
}