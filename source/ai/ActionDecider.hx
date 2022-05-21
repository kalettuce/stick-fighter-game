package ai;

import actions.AIAction;
import actions.ActionStatus;
import fighter.Enemy;
import fighter.Player;
import flixel.util.FlxDirectionFlags;
import haxe.xml.Check.Attrib;

class ActionDecider {
    // myself, the enemy of the player
    private var self:Enemy;
    private var player:Player;

    public function new (s:Enemy, p:Player) {
        self = s;
        player = p;
    }

    public function nextAction(prevStatus:ActionStatus):AIAction {
        // move until player is in range 
        if (!inRange()) {
            return AIAction.MOVE_ACTION;
        } else {
            return AIAction.IDLE_ACTION;
        }
    }

    public function getDirection():FlxDirectionFlags {
        if (self.getCenter() > player.getCenter()) {
            return FlxDirectionFlags.LEFT;
        } else {
            return FlxDirectionFlags.RIGHT;
        }
    }

    // returns true if the player is in the AI's range
    public function inRange():Bool {
        return Math.abs(self.getCenter() - player.getCenter()) <= self.getRange();
    }

    // returns true if the enemy is in the player's range
    public function inReverseRange():Bool {
        return Math.abs(self.getCenter() - player.getCenter()) <= player.getRange();
    }

    public function print() {
        trace("enemy: " + self.getCenter());
        trace("player: " + player.getCenter());
        trace("diff: " + Math.abs(self.getCenter() - player.getCenter()));
        trace("range: " + self.getRange());
    }
}