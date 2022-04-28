package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;

class PlayState extends FlxState
{
	var text:FlxText;

	override public function create()
	{
		super.create();
		text = new FlxText(0, 0, FlxG.width, "hello, world", 128);
		add(text);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
