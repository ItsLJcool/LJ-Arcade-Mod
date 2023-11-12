//a
import sys.FileSystem;
import sys.io.File;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.group.FlxTypedGroup;
import haxe.io.Path;
import StringTools;
import Sys;
import CoolUtil;
import flixel.math.FlxMath;
import flixel.text.FlxTextBorderStyle;
import flixel.group.FlxTypedSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import Conductor;
import PlayState;
import MusicBeatState;
import Reflect;
import openfl.utils.Assets;
import openfl.utils.AssetCache;
import openfl.system.System;
import FreeplayState;
import Type;
import discord_rpc.DiscordRpc;
import logging.LogsOverlay;
import Settings;
import lime.app.Future;
import sys.Http;
import ModSupport;
import flixel.effects.FlxFlicker;
import Script;

entirelyCustom = true;

var bgNow:FlxSprite;
var bgNext:FlxSprite;

var installedMods:Array<String> = FileSystem.readDirectory(Paths.get_modsPath());

// var modTabs:FlxTypedSpriteGroup = new FlxTypedSpriteGroup();
var modTabs:Array<Dynamic> = [];
function create() {
    RPCScript = Script.create(Paths.modsPath + "/" + mod + "/RPC.hx");
    ModSupport.setScriptDefaultVars(RPCScript, mod, {});
    if (RPCScript == null) RPCScript = new DummyScript();

    RPCScript.setVariable("create", function() {});
    RPCScript.setVariable("mod", mod);
    RPCScript.loadFile();
    RPCScript.executeFunc("create");
    
    if (LogsOverlay.hscript.variables.get("isMostUpToDateArcade") != true 
        && !LogsOverlay.hscript.variables.exists("skippedUpdate")) {
        FlxG.camera.alpha = 0;
        FlxG.switchState(new ModState("OutdatedLJArcade", mod, []));
    }

    CoolUtil.playMenuMusic(true);
    var toRemove:Array<Dynamic> = [];
    for (item in installedMods) {
        if (Path.extension(item) != ""
        || StringTools.contains(item.toLowerCase(), "yoshicrafterengine")
        || StringTools.contains(item.toLowerCase(), "crumbcat") // bro really?
        || StringTools.contains(item.toLowerCase(), mod.toLowerCase()))
            toRemove.push(item);
    }
    for (item in toRemove) installedMods.remove(item);
    
    nextBG = new FlxSprite(0,0, existsInMods("images/menuDesat.png", Paths.image("menuDesat")));
    nextBG.setGraphicSize(FlxG.width, FlxG.height);
    nextBG.screenCenter();
    
    bgArcade = new FlxSprite(0, 0, existsInMods("images/menuDesat.png", Paths.image("menuDesat")));
    bgArcade.setGraphicSize(FlxG.width, FlxG.height);
    bgArcade.screenCenter();
    add(bgArcade);

    
    for (i in 0...installedMods.length) {
        tab = new FlxTypedSpriteGroup();

        var barSprite = new FlxUI9SliceSprite(0,0, Paths.image("SquareShit"), new Rectangle(0,0, FlxG.width, 120), [20, 20, 460, 460]);
        barSprite.setPosition(0 - FlxG.width/2, (barSprite.height + 15)*(i));
        barSprite.alpha = 0.35; // .55 | .35
        tab.add(barSprite);
        
        var modIconPath = Paths.getLibraryPathForce("modIcon.png", "mods/"+installedMods[i]);
        if (!Assets.exists(modIconPath)) modIconPath = Paths.image("modEmptyIcon");
        var icon = new FlxSprite(0,0, modIconPath);
        icon.setGraphicSize(120, 120);
        icon.scale.set(Math.min(icon.scale.x, icon.scale.y), Math.min(icon.scale.x, icon.scale.y));
        icon.updateHitbox();
        icon.setPosition(barSprite.x + FlxG.width/2 + 5, barSprite.y + barSprite.height/2 - icon.height/2);
        tab.add(icon);
        
		var modTitle:AlphabetOptimized = new AlphabetOptimized(0,0, installedMods[i], false, Math.min(0.65, ((barSprite.width - FlxG.width/2) - 225) / (32 * installedMods[i].length)));
        modTitle.setPosition(icon.x + icon.width + 15, barSprite.y + barSprite.height/2 - modTitle.height/2 - 12);
        modTitle.textColor = 0xFF000000;
        modTitle.alpha = 0.65;
        tab.add(modTitle);
        
        add(tab);
        modTabs.push(tab);
    }
    
    arroer = new FlxSprite(0,0, Paths.image("menuState/Arrow"));
    add(arroer);

    var theBars = new FlxSprite(0,0, Paths.image("menuState/Black Bars"));
    theBars.setGraphicSize(FlxG.width, FlxG.height);
    theBars.screenCenter();
    add(theBars);
    
    changeSect(0);
}

var curSelection:Int = 0;
var currentColor = 0xFF22BE0D;
var noMovement:Bool = false;
var prevSel:Int = curSelection;
var timerHold:FlxTimer;

var bgTween:FlxTween;
function changeSect(hur:Int = 0) {
    if (noMovement) return;
    curSelection = CoolUtil.wrapInt(curSelection + hur, 0, installedMods.length);
    prevSel = curSelection;
    if (timerHold != null) timerHold.cancel();
    timerHold = new FlxTimer().start(0.5, function(tmr) {
        nextBG = new FlxSprite(0,0, existsInMods("images/menuDesat.png", Paths.image("menuDesat")));
        nextBG.setGraphicSize(FlxG.width, FlxG.height);
        nextBG.screenCenter();
        insert(members.indexOf(bgArcade), nextBG);
        FlxTween.tween(bgArcade, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut, onComplete: function() {
            bgArcade.destroy();
            bgArcade.kill();
            remove(bgArcade);
            bgArcade = nextBG;
        }});
    });
}
function update(elapsed:Float) {

    if (CoolUtil.isDevMode() && FlxG.keys.justPressed.SEVEN) {
        FlxG.switchState(new dev_toolbox.ToolboxMain());
    }

    if (FlxControls.anyJustPressed([37, 65])) changeSect(-1);
    if (FlxControls.anyJustPressed([39, 68])) changeSect(1);

    if (FlxG.keys.justPressed.ENTER) {
        noMovement = true;
        FlxG.sound.play(existsInMods("sounds/confirmMenu.ogg", Paths.sound("confirmMenu")));
        FlxFlicker.flicker(arroer, 1, 0.06, true, false, function(flick:FlxFlicker) {
            FlxG.sound.music.fadeOut(0.5, 0, function() {
                FlxG.sound.music.stop();
                FlxG.switchState(new ModState("ModEditing", mod, [installedMods[curSelection]]));
            });
        });
    }
    
    for (i in 0...modTabs.length) {
        var tab = modTabs[i];
        var theX = (i == curSelection) ? 150 : 0;
        var theAlpha = (i == curSelection) ? 0.55 : 0.35;
        tab.members[0].alpha = FlxMath.lerp(tab.members[0].alpha, theAlpha, elapsed*10);
        tab.x = FlxMath.lerp(tab.x, theX, elapsed*10);
        tab.y = FlxMath.lerp(tab.y, (-120 - 15)*(curSelection - 2.25), elapsed*10);
    }
    arroer.setPosition(Math.abs(modTabs[curSelection].members[0].x) + arroer.width + 250, Math.abs(modTabs[curSelection].members[0].y) + arroer.height/8);

    if (bgArcade != null) bgArcade.color = FlxColor.interpolate(bgArcade.color, currentColor, elapsed*5);
    if (nextBG != null) nextBG.color = FlxColor.interpolate(nextBG.color, currentColor, elapsed*5);

    if (FlxG.keys.justPressed.O) {
        FlxG.switchState(new options.screens.OptionMain());
    }

    if (FlxControls.anyJustPressed([82])) {
        curSelection = FlxG.random.int(0, installedMods.length-1);
        changeSect(0);
    }
}

function existsInMods(targeted:String, default:String, ?sparrow:Bool = false) {
	if (!Assets.exists(default) && !sparrow) return trace("This default doesn't exist! : " + default);
    if (sparrow) {
        if (!Assets.exists(Paths.image(default))) return trace("This default doesn't exist!");
        else default = Paths.getSparrowAtlas(default);
    }
	targeted = Paths.getLibraryPathForce(targeted, "mods/" + installedMods[curSelection]);
	return (Assets.exists(targeted)) ? targeted : default;
}