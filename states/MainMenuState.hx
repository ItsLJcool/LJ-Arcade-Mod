//a
import sys.FileSystem;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.group.FlxTypedGroup;
import haxe.io.Path;
import StringTools;
import Sys;
import CoolUtil;
import flixel.math.FlxMath;
import flixel.text.FlxTextBorderStyle;
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
import Script;

entirelyCustom = true;

var bg:FlxSprite;

var installedMods:Array<String> = FileSystem.readDirectory(Paths.get_modsPath());

var modImages:FlxTypedGroup<FlxSprite>;
var modText:FlxTypedGroup<FlxText>;
var modBG:FlxTypedGroup<FlxSprite>;

var sections:Int = 0;
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
        FlxG.switchState(new ModState("OutdatedLJArcade", mod, []));
    }
    
    if (save.data.ljTokens == null) {
        save.data.ljTokens = 0;
        save.flush();
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
    
    bg = new FlxSprite(0,0, Paths.image("menuBGYoshiCrafter_"));
    bg.setGraphicSize(FlxG.width, FlxG.height);
    add(bg);
    
    modBG = new FlxTypedGroup();
    add(modBG);

    modText = new FlxTypedGroup();
    add(modText);

    modImages = new FlxTypedGroup();
    add(modImages);

    for (i in 0...installedMods.length) {
        var item = installedMods[i];
        if (installedMods[i] == null) item = "test";
        var sprBG = new FlxUI9SliceSprite(0,0, Paths.image("SquareShit"),
        new Rectangle(0, 0, (FlxG.width / 2) - 25, (FlxG.height / 6) - 5), [20, 20, 460, 460]);
        sprBG.color = 0xFFFFFFFF;
        sprBG.alpha = 0.15;
        if (i % 12 == 0 && i != 0) {
            sections++;
            sprBG.y = 5;
        } else {
            if (modBG.members[i-1] != null) sprBG.y = modBG.members[i-1].y;
            if (i % 2 == 0 && i != 0) sprBG.y += modBG.members[i-1].height + 5;
        }
        sprBG.x = (FlxG.width/2 + 25)*(i % 2) + ((FlxG.width + 25) * sections);
        if (i == 0) sprBG.y += 5;
        sprBG.x += 5;
        sprBG.ID = sections;
        FlxMouseEventManager.add(sprBG, function(){}, function(){
            if (FlxG.mouse.overlaps(sprBG)) {
                FlxG.sound.music.fadeOut(0.5, 0, function() {
                    FlxG.sound.music.stop();
                    FlxG.switchState(new ModState("ModEditing", mod, [item]));
                });
            }
        }, function(){
            // hover
        }, function(){});
        modBG.add(sprBG);

        var modIconPath = Paths.getLibraryPathForce("modIcon.png", "mods/"+item);
        if (!Assets.exists(modIconPath)) modIconPath = Paths.image("modEmptyIcon");
        var modIcon:FlxSprite = new FlxSprite(0,0, modIconPath);
        modIcon.setGraphicSize(90, 90);
        modIcon.scale.set(Math.min(modIcon.scale.x, modIcon.scale.y), Math.min(modIcon.scale.x, modIcon.scale.y)); // Thanks math :dies of horrable math death:
        modIcon.updateHitbox();
        // modIcon.alpha = 0.5;
        modIcon.x = sprBG.x + modIcon.width/4 + 15;
        modIcon.y = sprBG.y + sprBG.height/2 - modIcon.height/2;
        modIcon.ID = sections;
        modImages.add(modIcon);
        // sprBG.stamp(modIcon, 0,0);

        var daText:FlxText = new FlxText(0,0, sprBG.width - modIcon.width + modIcon.width/4 - 55, item, 20);
        daText.setGraphicSize(sprBG.width - modIcon.width + modIcon.width/4 - 55, daText.height);
        daText.scale.set(Math.min(daText.scale.x, daText.scale.y), Math.min(daText.scale.x, daText.scale.y)); // Thanks math :dies of horrable math death:
        daText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2);
        daText.x = modIcon.x + modIcon.width + 10;
        daText.y = sprBG.y + sprBG.height/2 - daText.height/2;
        daText.ID = sections;
        modText.add(daText);
    }
    createPost();
}

var curSection:Int = 0;
function changeSect(hur:Int = 0) {
    curSection = CoolUtil.wrapInt(curSection + hur, 0, sections+1);
}
function update(elapsed:Float) {

    if (CoolUtil.isDevMode() && FlxG.keys.justPressed.SEVEN) {
        FlxG.switchState(new dev_toolbox.ToolboxMain());
    }

    if (FlxControls.anyJustPressed([37, 65])) changeSect(-1);
    if (FlxControls.anyJustPressed([39, 68])) changeSect(1);
    
    if (FlxG.keys.justPressed.O) {
        FlxG.switchState(new options.screens.OptionMain());
    }

    if (FlxControls.anyJustPressed([82])) {
        var item = FlxG.random.int(0, installedMods.length-1);
        FlxG.sound.music.fadeOut(0.5, 0, function() {
            FlxG.sound.music.stop();
            FlxG.switchState(new ModState("ModEditing", mod, [installedMods[item]]));
        });
    }

    for (i in 0...modBG.length) {
        var daModBG = modBG.members[i];
        var daModImages = modImages.members[i];
        var daModText = modText.members[i];
        var calc = (FlxG.width/2 + 25)*(i % 2) + (FlxG.width + 25) * (daModBG.ID - curSection);

        daModBG.visible = !(daModBG.x < (-daModBG.width*1.2) || (daModBG.x*1.2) > FlxG.width);
        daModBG.active = !(daModBG.x < (-daModBG.width*1.2) || (daModBG.x*1.2) > FlxG.width);
        
        daModImages.visible = !(daModImages.x < (-daModImages.width*1.2) || (daModImages.width*1.2) > FlxG.width);
        daModImages.active = !(daModImages.x < (-daModImages.width*1.2) || (daModImages.width*1.2) > FlxG.width);
        
        daModText.visible = !(daModText.x < (-daModText.width*1.2) || (daModText.x*1.2) > FlxG.width);
        daModText.active = !(daModText.x < (-daModText.width*1.2) || (daModText.x*1.2) > FlxG.width);

        daModImages.x = daModBG.x + daModImages.width/4;
        daModImages.y = daModBG.y + daModBG.height/2 - daModImages.height/2;
        
        daModText.x = daModImages.x + daModImages.width + 15;
        daModText.y = daModBG.y + daModBG.height/2 - daModText.height/2;
        
        daModBG.x = FlxMath.lerp(daModBG.x, calc, elapsed*10);
    }
}