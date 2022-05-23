package ai;

// every instance of this class represents a platform in a FlxTilemap
class TilePlatform {
    public final yPos:Int;
    public final xMin:Int;
    public final xMax:Int;

    public function new(y:Int, min:Int, max:Int) {
        yPos = y;
        xMin = min;
        xMax = max;
    }
}