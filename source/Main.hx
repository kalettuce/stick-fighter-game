package;

import cse481d.logging.CapstoneLogger;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite {

    // A bit of an ugly hack, basically using a global variable so it can be
	// fetched in any arbitrary class.
	public static var LOGGER:CapstoneLogger;

    public function new() {

        super();

        var gameId:Int = 202207;
		var gameKey:String = "32c8e061c36aee1dc674f96480b7f130";
		var gameName:String = "stick";

        // Category 1: for debugging
        // Category 2: for release to friends/family
        // Category 3: for release to public
		var categoryId:Int = 1;
		var useDev:Bool = true;
		Main.LOGGER = new CapstoneLogger(gameId, gameName, gameKey, categoryId, useDev);
		
		// Retrieve the user (saved in local storage for later)
		var userId:String = Main.LOGGER.getSavedUserId();
		if (userId == null)
		{
			userId = Main.LOGGER.generateUuid();
			Main.LOGGER.setSavedUserId(userId);
		}
		Main.LOGGER.startNewSession(userId, this.onSessionReady);
    }

    private function onSessionReady(sessionRecieved:Bool):Void
	{
		addChild(new FlxGame(0, 0, MenuState, 1, 60, 60, true));
	}

}


