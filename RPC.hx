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
import StringTools;
import sys.FileSystem;

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

        LogsOverlay.hscript.variables.set("ljArcadeVersion", Assets.getText(Paths.txt("version")).split("\n")[0]);

        var data = null;
        LogsOverlay.hscript.variables.set("isMostUpToDateArcade", false);
        var futureThread = new Future(function() {
            data = new Http("https://raw.githubusercontent.com/ItsLJcool/LJ-Arcade-Mod/staging/data/version.txt");
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
                                rpc.smallImageKey = "lj_token_mini";
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