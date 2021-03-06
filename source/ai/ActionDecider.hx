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

    // true if the enemy is not on the same platform as the player
    // so the enemy simply patrols the platform
    private var patrolling:Bool;

    public function new (s:Enemy, p:Player) {
        self = s;
        player = p;
    }

    public function nextAction(prevStatus:ActionStatus, elapsed:Float):AIAction {
        // move until player is in range 
        if (!inRange()) {
            return AIAction.MOVE_ACTION;
        } else {
            return AIAction.IDLE_ACTION;
        }
    }

    private function patrolDecision() {
        final selfIndex = self.getPlatformIndex();
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

    public function getDirection():FlxDirectionFlags {

        // patrolling platform
        if (patrolling) {
            final platform:TilePlatform = self.getPlatform();
            // turn around if on edge of platform
            if (self.facing == FlxDirectionFlags.LEFT &&
                (self.collider.x <= platform.xMin || self.collider.isTouching(FlxDirectionFlags.LEFT))) {
                return FlxDirectionFlags.RIGHT;
            } else if (self.facing == FlxDirectionFlags.RIGHT &&
                ((self.collider.x + self.collider.width) >= platform.xMax || self.collider.isTouching(FlxDirectionFlags.RIGHT))) {
                return FlxDirectionFlags.LEFT;
            } else {
                return self.facing;
            }
        }

        // chasing player
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