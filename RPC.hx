//a
import discord_rpc.DiscordRpc;
import DiscordClient;
import ModSupport;
import logging.LogsOverlay;
import mod_support_stuff.SwitchModSubstate;
import Type;
import Settings;
import lime.app.Future;
import sys.Http;
import sys.FileSystem;
import StringTools;
import Date;
import haxe.io.Path;

var ljEditing:Bool = false;
function create() {

    if (FileSystem.exists("./_cache/")) {
        for (item in FileSystem.readDirectory("./_cache/")) {
            FileSystem.deleteFile("./_cache/"+item);
        }
        FileSystem.deleteDirectory("./_cache/");
    }
    if (!LogsOverlay.hscript.variables.exists("addUpdateRPC")) {
        LogsOverlay.hscript.variables.set("updateDiscordRPC", 0);
        LogsOverlay.hscript.variables.set("addUpdateRPC", true);

        LogsOverlay.hscript.variables.set("ljArcadeVersion", StringTools.trim(Assets.getText(Paths.txt("version")).split("\n")[0]));
        if (Assets.exists(Paths.txt("ljEditing"))) {
            var txt = StringTools.trim(Assets.getText(Paths.txt("ljEditing")));
            if (txt == "true") ljEditing = true;
        }

        var data:String = Http.requestUrl('https://raw.githubusercontent.com/ItsLJcool/LJ-Arcade-Mod/staging/data/version.txt');
        data = StringTools.trim(data.split("\n")[0]);

        LogsOverlay.hscript.variables.set("isMostUpToDateArcade", Std.string(data) == LogsOverlay.hscript.variables.get("ljArcadeVersion"));

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
}

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
    // if (Type.getClassName(Type.getClass(FlxG.state)).toLowerCase() == "playstate") return;
    if (FlxG.state != FlxG.game._requestedState) {
        LogsOverlay.hscript.variables.set("updateDiscordRPC", 1.9);
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
            details: "Oops, no RPC in " + Type.getClassName(Type.getClass(FlxG.state)).toLowerCase(),
            largeImageKey: oldArcade,
            largeImageText: (LogsOverlay.hscript.variables.get("isMostUpToDateArcade")) ? "LJ Arcade" : "Outdated Arcade",
            smallImageKey: (LogsOverlay.hscript.variables.get("isMostUpToDateArcade")) ? "check_mini" : "minus_mini",
            smallImageText: StringTools.replace(isUpToData, "[ver]", LogsOverlay.hscript.variables.get("ljArcadeVersion")),
        };
        if (ljEditing) {
            rpc.details = "Ah, LJ Is making a new state. or somehow broke his game";
            rpc.smallImageKey = "minus_mini";
            rpc.smallImageText = "LJ Specific Build (known ver: "+LogsOverlay.hscript.variables.get("ljArcadeVersion")+" )";
        }
            switch(Type.getClassName(Type.getClass(FlxG.state)).toLowerCase()) {
                case "playstate":
                    var isPixel = false;
                    if (FlxG.state.noteScripts[0].metadata.noteType.split(":")[1] != null && FlxG.state.noteScripts[0].metadata.noteType.split(":")[0].toLowerCase() != null)
                        isPixel = (FlxG.state.noteScripts[0].metadata.noteType.split(":")[0].toLowerCase() == "pixel note"
                        || FlxG.state.noteScripts[0].metadata.noteType.split(":")[1].toLowerCase() == "pixel note");
                    if (FlxG.state.noteScripts[0].metadata.noteType.toLowerCase() == "pixel note") isPixel = true;
                    var thing = (isPixel) ? oldArcade + "-pixel" : oldArcade;
                    rpc.largeImageKey = thing;
                    rpc.state = "LJ Arcade";
                    if (FlxG.state.subState != null) {
                        rpc.details = "Paused |  " + StringTools.replace(FlxG.state.SONG.song.toLowerCase(), "-", " "); // bottom text
                    } else {

                        var endTimestamp = (FlxG.sound.music != null) ? FlxG.sound.music.length : 0;
    
                        var startTimestamp:Float = (FlxG.sound.music != null) ? Date.now().getTime() - FlxG.sound.music.time : 0;
    
                        if (endTimestamp > 0)  endTimestamp = startTimestamp + endTimestamp;
                        rpc.startTimestamp = Std.int(startTimestamp / 1000);
                        rpc.endTimestamp = Std.int(endTimestamp / 1000);
                        for (script in FlxG.state.scripts.scripts) {
                            if (script.fileName.toLowerCase() != "modtrack.hx") continue;
                            rpc.state = (script.getVariable("doingChallenge")) ? "LJ Arcade - Doing A Challenge" : "LJ Arcade - Freeplay";
                            break;
                        }
                        rpc.details = "Playing " + StringTools.replace(FlxG.state.SONG.song.toLowerCase(), "-", " "); // bottom text
                    }
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
                                rpc.smallImageKey = "lj_token_mini";
                                rpc.smallImageText = "LJ Tokens: " + save.data.levelSystem.tokenData.tokens;
                            }
                            switch(FlxG.state.script.getVariable("curSelectedType").toLowerCase()) {
                                case "freeplay":
                                    rpc.details = "Choosing A Song (Freeplay)";
                                case "medals":
                                    rpc.details = "Picking A Challenge";
                                default:
                                    rpc.details = "LJ Tokens: " + save.data.levelSystem.tokenData.tokens;
                            }
                        case "ratingssay":
                            rpc.state = "LJ Arcade - Ratings"; // top text
                            rpc.details = FlxG.state.script.getVariable("challengeText");
                            rpc.largeImageKey = "rating";
                            rpc.largeImageText = "LJ Arcade - "
                            + FlxG.state.script.getVariable("ratingOrder")[FlxG.state.script.getVariable("ratingInt")] + " Rating";
                        case "outdatedljarcade":
                            rpc.state = "Outdated Arcade"; // top text
                            rpc.details = (FlxG.state.script.getVariable("data") == null) ? "Unable to update (Error in Version Control)" : "Updating to the newest version (Current is " + LogsOverlay.hscript.variables.get("ljArcadeVersion") + ")";
                            rpc.largeImageKey = "installingmod";
                            rpc.largeImageText = (FlxG.state.script.getVariable("data") == null) ? "Outdated Version! Can't update (Error in Version Control)" : "Outdated Version! Updating";
                        case "updatemod":
                            rpc.state = "Updating Arcade"; // top text
                            rpc.details = "Updating to the newest version (Current is " + LogsOverlay.hscript.variables.get("ljArcadeVersion") + ")";
                            rpc.largeImageKey = "installingmod";
                            rpc.largeImageText = FlxG.state.script.getVariable("percentLabel").text;
                    }
            }
        DiscordRpc.presence(rpc);
    }
}