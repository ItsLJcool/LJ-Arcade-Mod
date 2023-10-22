//a
import AlphabetOptimized;
import logging.LogsOverlay;
import Settings;
import lime.app.Future;
import sys.Http;
import UpdateState;

function create() {
    var bg:FlxSprite = new FlxSprite(0,0, Paths.image('menuBGYoshiCrafter', 'preload'));
    bg.setGraphicSize(FlxG.width, FlxG.height);
    bg.screenCenter();
    add(bg);
    var data = null;
    var futureThread = new Future(function() {
        data = new Http("https://raw.githubusercontent.com/ItsLJcool/LJ-Arcade-Mod/releases/data/changes.txt");
        data.onError = function(msg:String) {
            data = null;
        }
        data.request(true);
    });
    if (data == null || thingsToGet == null) {
        // FlxG.switchState(new MainMenuState());
        // FlxG.camera.alpha = 0;
    }
    var text = (data == null) ? "Can't get new changelog." : data;
    var outdatedText:AlphabetOptimized = new AlphabetOptimized(100,100, text, false, 0.5);
    add(outdatedText);
    
	var update = new FlxSprite(10, 0);
	update.frames = Paths.getSparrowAtlas("outdatedAssets", "preload");
	update.animation.addByPrefix("anim", "space to check github");
	update.animation.play("anim");
	update.setGraphicSize(Std.int(update.width * 0.75));
    update.screenCenter();
    update.y = FlxG.height - update.height - 15;
    add(update);
}

function colorToShaderVec(color:Int, ?rgbUh:Bool = false) {
    if (color == null) return;
	if (rgbUh == null) rgbUh = false;
	var r = (color >> 16) & 0xff;
	var g = (color >> 8) & 0xff;
	var b = (color & 0xff);
	return (rgbUh) ? {r: r, g: g, b: b, a: (color >> 24) & 0xff} : [(r)/100, (g)/100, (b)/100];
}

var updating:Bool = false;
function update() {
    if (FlxG.keys.justPressed.SPACE && !updating) {
        FlxG.openURL('https://github.com/ItsLJcool/LJ-Arcade-Mod/tree/releases');
        FlxG.switchState(new MainMenuState());
    }
}