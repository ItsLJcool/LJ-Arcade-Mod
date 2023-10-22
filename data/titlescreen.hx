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

var crafterEngineLogo:FlxSprite = null;
var gfDancing:FlxSprite = null;
function create() {
    DiscordClient.initialize();
	gfDancing = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
	gfDancing.frames = Paths.getSparrowAtlas('titlescreen/gfDanceTitle');
	gfDancing.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
	gfDancing.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
	gfDancing.animation.play('danceLeft', true);
	gfDancing.antialiasing = true;
	add(gfDancing);

	crafterEngineLogo = new FlxSprite(-50, -35);
	crafterEngineLogo.frames = Paths.getSparrowAtlas('titlescreen/logoBumpin');
	crafterEngineLogo.antialiasing = true;
	crafterEngineLogo.animation.addByPrefix('bump', 'logo bumpin', 24);
	crafterEngineLogo.animation.play('bump');
	crafterEngineLogo.updateHitbox();
	crafterEngineLogo.scale.x = crafterEngineLogo.scale.y = 0.95;
	add(crafterEngineLogo);

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
}

function onUpdateCheck() {

    // for now
    // if (LogsOverlay.hscript.variables.get("isMostUpToDateArcade") != true) {
    //     FlxG.switchState(new ModState("OutdatedLJArcade", mod, []));
    // }
}

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

function beatHit() {
	if (gfDancing != null)
		gfDancing.animation.play((gfDancing.animation.curAnim.name == "danceLeft") ? "danceRight" : "danceLeft");
}
var updateDiscordRPC:Float = 2;
function update(elapsed:Float) {
    updateDiscordRPC += elapsed;
    if (updateDiscordRPC >= 2) {
        updateDiscordRPC = 0;
        ModSupport.refreshDiscordRpc();
    }
}