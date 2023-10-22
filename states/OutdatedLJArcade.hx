//a
import AlphabetOptimized;
import logging.LogsOverlay;
import Settings;
import lime.app.Future;
import sys.Http;

function create() {
    var bg:FlxSprite = new FlxSprite(0,0, Paths.image('menuBGYoshiCrafter', 'preload'));
    bg.setGraphicSize(FlxG.width, FlxG.height);
    bg.screenCenter();
    add(bg);
    var futureThread = new Future(function() {
        data = new Http("https://raw.githubusercontent.com/ItsLJcool/LJ-s-Arcade-Mod/main/data/changes.txt");
        data.onError = function(msg:String) {
            data = null;
        }
        data.request(true);
    });
    //ItsLJcool/LJ-s-Arcade-Mod/blob/main/data/changes.txt
    var outdatedText:AlphabetOptimized = new AlphabetOptimized(100,100, "PH", false, 0.5);
    add(outdatedText);
}