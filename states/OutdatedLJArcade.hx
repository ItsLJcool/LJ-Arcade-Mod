//a
import AlphabetOptimized;
import logging.LogsOverlay;
import Settings;
import lime.app.Future;
import sys.Http;
import StringTools;

var anims;
function create() {
    var bg:FlxSprite = new FlxSprite(0,0, Paths.image('menuBGYoshiCrafter', 'preload'));
    bg.setGraphicSize(FlxG.width, FlxG.height);
    bg.screenCenter();
    add(bg);

    var data:String = Http.requestUrl('https://raw.githubusercontent.com/ItsLJcool/LJ-Arcade-Mod/staging/data/changes.txt');
    
    var text = (data == null) ? "Can't get new changelog." : data;
    var outdatedText:AlphabetOptimized = new AlphabetOptimized(100,100, text, false, 0.5);
    add(outdatedText);

    anims = ['enter to update', 'space to check github', 'backspace to skip'];
    if (data == null) anims = ['backspace to skip'];

    for (i in 0...anims.length) {
        var b = new FlxSprite(10, 0);
        b.frames = Paths.getSparrowAtlas("outdatedAssets", "preload");
        b.animation.addByPrefix("anim", anims[i]);
        b.animation.play("anim");
        b.setGraphicSize(Std.int(b.width * 0.75));
        b.y = 710 - b.height;
        b.x = ((FlxG.width) * ((i + 0.5) / anims.length)) - (b.width / 2);
        b.antialiasing = true;
        add(b);
    }
}

function update() {
    if (FlxG.keys.justPressed.ENTER && StringTools.contains(anims, "enter to update")) {
        FlxG.switchState(new ModState("UpdateMod", mod, ["https://github.com/ItsLJcool/LJ-Arcade-Mod/releases/download/"]));
    }
    if (FlxG.keys.justPressed.SPACE && StringTools.contains(anims, "space to check github")) {
        FlxG.openURL('https://github.com/ItsLJcool/LJ-Arcade-Mod/releases');
        LogsOverlay.hscript.variables.set("skippedUpdate", true);
        FlxG.switchState(new MainMenuState());
    }
    if (FlxControls.anyJustPressed([8, 27]) && StringTools.contains(anims, "backspace to skip")) {
        LogsOverlay.hscript.variables.set("skippedUpdate", true);
        FlxG.switchState(new MainMenuState());
    }
}