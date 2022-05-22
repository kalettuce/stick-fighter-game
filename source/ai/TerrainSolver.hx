package ai;

import openfl.Assets;

class TerrainSolver {
    public static function solveCSVTerrain(filename:String, tileWidth:Int, tileHeight:Int):Array<TilePlatform> {
        // load the csv into a 2d array
        var rawMap:String = Assets.getText(filename);
        var mapData:Array<Array<Int>> = parseIntCSV(rawMap);
        
        var platforms:Array<TilePlatform> = [];
        var platformStart:Int = -1;
        for (i in 0...mapData.length) {
            for (j in 0...mapData[0].length) {
                // add the current tile to the platform if there's no tile above it
                if ((mapData[i][j] != 0 && (i == 0 || mapData[i-1][j] == 0))) {
                    if (platformStart == -1) {
                        platformStart = j;
                    }
                } else { // terminate the current platform and add the platform to the array otherwise
                    if (platformStart != -1) {
                        platforms.push(new TilePlatform(i*tileHeight, platformStart*tileWidth, j*tileWidth));
                        platformStart = -1;
                    }
                }

                // special case at end-of-line, but not end of platform
                if (j == mapData[0].length - 1 && platformStart != -1) {
                    platforms.push(new TilePlatform(i*tileHeight, platformStart*tileWidth, (j+1)*tileWidth));
                }
            }
            platformStart = -1;
        }

        // mark every
        return platforms;
    }

    // loads csv into an array
    private static function parseIntCSV(csvString: String):Array<Array<Int>> {
        var lines:Array<String> = csvString.split('\n');
        var map:Array<Array<String>> = [];
        for (line in lines) {
            map.push(line.split(','));
        }
        return map.map(
            function (line:Array<String>) {
                return line.map(
                    function (s:String) {
                        return Std.parseInt(s);
                    }
                );
            }
        );
    }
}