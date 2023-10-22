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

entirelyCustom = true;

var bg:FlxSprite;

var installedMods:Array<String> = FileSystem.readDirectory(Paths.get_modsPath());

var modImages:FlxTypedGroup<FlxSprite>;
var modText:FlxTypedGroup<FlxText>;
var modBG:FlxTypedGroup<FlxSprite>;

var sections:Int = 0;

/**
    @:optional var state   : String;
    @:optional var details : String;
    @:optional var startTimestamp : Int;
    @:optional var endTimestamp   : Int;
    @:optional var largeImageKey  : String;
    @:optional var largeImageText : String;
    @:optional var smallImageKey  : String;
    @:optional var smallImageText : String;
    @:optional var partyID   : String;
    @:optional var partySize : Int;
    @:optional var partyMax  : Int;
    @:optional var matchSecret    : String;
    @:optional var spectateSecret : String;
    @:optional var joinSecret     : String;
    @:optional var instance : Int;
    @:optional var button1Label:String;
    @:optional var button1Url:String;
    @:optional var button2Label:String;
    @:optional var button2Url:String;
**/

function doRPCupdate() {
    if (Type.getClassName(Type.getClass(FlxG.state)).toLowerCase() == "playstate") return;
    if (FlxG.state != FlxG.game._requestedState) {
        LogsOverlay.hscript.variables.set("updateDiscordRPC", 2);
    }
    var update = LogsOverlay.hscript.variables.get("updateDiscordRPC");
    LogsOverlay.hscript.variables.set("updateDiscordRPC", update + FlxG.elapsed);
    if (update >= 2) {
        LogsOverlay.hscript.variables.set("updateDiscordRPC", 0);
        var oldArcade = (LogsOverlay.hscript.variables.get("isMostUpToDateArcade") == true) ? "arcadegaming" : "oldarcadebuild";
        var isUpToData = "";
        if (LogsOverlay.hscript.variables.get("isMostUpToDateArcade") == null) {
            isUpToData = "Unable to check version control. Current Known Version: [ver]";
        } else {
            isUpToData = (LogsOverlay.hscript.variables.get("isMostUpToDateArcade"))
            ? "Most Updated Version of LJ Arcade ([ver])" : "Outdated Version! ([ver])";
        }
        var rpc = {
            state: "YoshiCrafterEngine - LJ Arcade",
            details: "Stating at something (because i forgot to add a case for whatever State I am in)",
            largeImageKey: oldArcade,
            largeImageText: "LJ Arcade",
            smallImageKey: (LogsOverlay.hscript.variables.get("isMostUpToDateArcade")) ? "check_mini" : "minus_mini",
            smallImageText: StringTools.replace(isUpToData, "[ver]", LogsOverlay.hscript.variables.get("ljArcadeVersion")),
        };
            switch(Type.getClassName(Type.getClass(FlxG.state)).toLowerCase()) {
                case "titlestate":
                    rpc.state = "YoshiCrafterEngine - LJ Arcade"; // top text
                    rpc.details = "Looking at the Intro"; // bottom text
                case "mainmenustate":
                    rpc.state = "LJ Arcade - Mod Selector";
                    rpc.details = "Selecting A YCE Mod to play";
                case "mod_support_stuff.modstate":
                    switch(FlxG.state._scriptName.toLowerCase()) {
                        case "modediting":
                            rpc.state = "LJ Arcade - Playing " + FlxG.state.script.getVariable("editingMod");
                            if (FlxG.state.script.getVariable("curSelectedType").toLowerCase() != "menu") {
                                rpc.smallImageKey = "lj_token";
                                rpc.smallImageText = "LJ Tokens: " + save.data.ljTokens;
                            }
                            switch(FlxG.state.script.getVariable("curSelectedType").toLowerCase()) {
                                case "freeplay":
                                    rpc.details = "Choosing A Song (Freeplay)";
                                case "medals":
                                    rpc.details = "Picking A Challenge";
                                case "menu":
                                    rpc.details = "LJ Tokens: " + save.data.ljTokens;
                            }
                        case "ratingssay":
                            rpc.state = "LJ Arcade - Ratings"; // top text
                            rpc.details = FlxG.state.script.getVariable("challengeText");
                            rpc.largeImageKey = "rating";
                            rpc.largeImageText = "LJ Arcade"
                            + FlxG.state.script.getVariable("ratingOrder")[FlxG.state.script.getVariable("ratingInt")] + " Rating";
                        case "outdatedljarcade":
                            rpc.largeImageKey = "installingmod";
                            rpc.largeImageText = "Outdated Version! Updating";
                            
                    }
            }

        DiscordRpc.presence(rpc);
    }
}
function create() {
    if (!LogsOverlay.hscript.variables.exists("addUpdateRPC")) {
        LogsOverlay.hscript.variables.set("updateDiscordRPC", 0);
        LogsOverlay.hscript.variables.set("addUpdateRPC", true);
        
        LogsOverlay.hscript.variables.set("ljArcadeVersion", Assets.getText(Paths.txt("version")));

        //https://raw.githubusercontent.com/ItsLJcool/LJ-s-Arcade-Mod/main/data/version.txt
        var data = null;
        LogsOverlay.hscript.variables.set("isMostUpToDateArcade", false);
        var futureThread = new Future(function() {
            data = new Http("https://raw.githubusercontent.com/ItsLJcool/LJ-Arcade-Mod/releases/data/version.txt");
            data.onError = function(msg:String) {
                data = null;
            }
            data.request(true);
        });
        if (data == null) LogsOverlay.hscript.variables.set("isMostUpToDateArcade", null);
        else LogsOverlay.hscript.variables.set("isMostUpToDateArcade", Std.string(data) == LogsOverlay.hscript.variables.get("ljArcadeVersion"));

        FlxG.signals.preUpdate.add(function() {
            if (FlxG.state.subState == null
                && (!LogsOverlay.hscript.variables.exists("usingLJarcade") || !LogsOverlay.hscript.variables.get("usingLJarcade"))
                && Settings.engineSettings.data.selectedMod != mod) {
                    LogsOverlay.hscript.variables.remove("addUpdateRPC");
                    FlxG.signals.preUpdate.removeAll();
            }
            doRPCupdate();
        });
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