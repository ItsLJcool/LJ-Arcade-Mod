//a
import FreeplayState;
import MainMenuState;
import Settings;
import GameOverSubstate;
import flixel.FlxCamera;
import HealthIcon;
import flixel.text.FlxTextBorderStyle;
import ModSupport;
import Conductor;
import flixel.group.FlxTypedGroup;
import PauseSubState;
import ScoreText;
import DiscordClient;
import StringTools;

var theChallengeWasCompleted:Array<Dynamic> = { hasCompleted: false };

var tokenMultiplier:Int = 1;
var challengeScript = null;

function onOpenSubstate(SubState) {
    if (Std.isOfType(SubState, PauseSubState)) {
        if (SubState.menuItems[2].toLowerCase() == "developer options") {
            SubState.menuItems.remove(SubState.menuItems[2]);
            SubState.grpMenuShit.remove(SubState.grpMenuShit.members[2], true);
            SubState.changeSelection();
        }
    }
}

function create() {
    FlxG.signals.postUpdate.removeAll();
    FlxG.signals.postUpdate.add(function() {
        if ((Std.isOfType(FlxG.game._requestedState, FreeplayState) || Std.isOfType(FlxG.game._requestedState, MainMenuState)) && FlxG.game._requestedState != FlxG.state) {
            Settings.engineSettings.data.selectedMod = loadedMod;
            FlxG.save.flush();
            if (!songEnded || PlayState.chartTestMode) {
                if (Assets.exists(Paths.getLibraryPathForce("states/ModEditing.hx", "mods/"+loadedMod)))
                    FlxG.switchState(new ModState("ModEditing", Settings.engineSettings.data.selectedMod, [PlayState.songMod, theChallengeWasCompleted]));
                return;
            }
            if (Assets.exists(Paths.getLibraryPathForce("states/RatingsSay.hx", "mods/"+loadedMod))) {
                FlxG.switchState(new ModState("RatingsSay", Settings.engineSettings.data.selectedMod, [{
                        mod: PlayState.songMod,
                        songLength: PlayState.songLength,
                        songScore: PlayState.songScore,
                        numberOfArrowNotes: PlayState.numberOfArrowNotes,
                        numberOfNotes: PlayState.numberOfNotes,
                        theChallengeWasCompleted: theChallengeWasCompleted,
                        tokenMult: (challengeScript != null) ? challengeScript.getVariable("tokenMultiplier") : 1,
                        challData: challengeID,
                        doingChallenge: doingChallenge,
                        song: PlayState.SONG.song,
                        acc: [PlayState.accuracy, ScoreText.generateAccuracy(PlayState)],
                        misses: [PlayState.misses, ScoreText.generateMisses(PlayState)],
                        blueballAmount: PlayState.blueballAmount,
                        rating: [ScoreText.generateRating(PlayState), ScoreText.getRating(PlayState.accuracy)],
                        canDie: PlayState.canDie,
                        validScore: PlayState.validScore,
                    }
                ]));
            }
        }
    });
    var theMod = editingMod;
    if (!Assets.exists(Paths.getLibraryPathForce("ljArcade/editData/ChallengesData.hx"), theMod)) theMod = loadedMod;
    if (doingChallenge) {
    FlxG.state.scripts.addScript(theMod + "/ljArcade/editData/ChallengesData.hx");
    challengeScript = FlxG.state.scripts.scripts[FlxG.state.scripts.scripts.length-1];
    challengeScript.setVariable("create", function() {});
    challengeScript.setVariable("loadedMod", loadedMod);
    challengeScript.setVariable("editingMod", editingMod);
    challengeScript.setVariable("doingChallenge", doingChallenge);
    challengeScript.setVariable("saveChallengesData", saveChallengesData);
    challengeScript.setVariable("challengeID", challengeID);
    challengeScript.setVariable("tokenMultiplier", tokenMultiplier);
    challengeScript.setVariable("challengeComplete", function(id:Dynamic) {
        trace(id);
        trace(challengeID);
        if (id.songSpecific == null) id.songSpecific = false;
        if (id == null || !doingChallenge || ModSupport.modSaves[loadedMod].data.challengesData.get(editingMod).data[challengeID.itemID].vars.daData.get("hasCompletedChallenge")) return;
        if (challengeID.challengeID == id.challengeID
        || (challengeID.songSpecific == id.songSpecific
        && challengeID.challengeID == id.challengeID
        && challengeID.songID == id.songID)) {
            trace("D");
        theChallengeWasCompleted = { hasCompleted: true, dataID: challengeID };
        ModSupport.modSaves[loadedMod].data.challengesData.get(editingMod).data[challengeID.itemID].vars.daData.set("hasCompletedChallenge", true);
        saveChallengesData.data[challengeID.itemID].vars.daData.set("hasCompletedChallenge", true);
        ModSupport.modSaves[loadedMod].flush();

        var newGroup = new FlxTypedGroup();
        var completedCamera = new FlxCamera();
        completedCamera.bgColor = 0;
        FlxG.cameras.add(completedCamera, false);

        var text:FlxText = new FlxText(0,0,0, "Challenge Completed", 26);
        text.cameras = [completedCamera];
        text.updateHitbox();
        text.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2);
    
        var icon:HealthIcon = new HealthIcon(saveChallengesData.data[challengeID.itemID].vars.daData.get("icon"), false, editingMod);
        icon.auto = false;
        icon.cameras = [completedCamera];
        icon.updateHitbox();
    
        var check:FlxSprite = new FlxSprite(0,0, Paths.getLibraryPathForce("images/Checkmark.png", "mods/"+loadedMod));
        check.setGraphicSize(icon.frameWidth - 50, icon.frameWidth - 50);
        check.cameras = [completedCamera];
        check.updateHitbox();
        check.visible = false;
    
        var cool:FlxSprite = new FlxSprite().makeGraphic(text.width + icon.width + 50, 150, 0xFF000000);
        cool.setPosition(FlxG.width + cool.width + 5, 15);
        cool.cameras = [completedCamera];
        cool.alpha = 0.3;
        PlayState.add(cool);
        PlayState.add(newGroup);
    
        icon.setPosition(cool.x + 5, cool.y + cool.height/2 - icon.height/2);
        newGroup.add(icon);
        
        check.setPosition(icon.x + icon.width/2 - check.width/2, icon.y + icon.height/2 - check.height/2);
        PlayState.add(check);
        
        text.setPosition(icon.x + icon.width + 5, cool.y + cool.height/2 - text.height/2);
        PlayState.add(text);
        
        FlxTween.tween(cool, {x: FlxG.width - cool.width}, 1, {ease: FlxEase.quadInOut, onUpdate: function() {
            icon.setPosition(cool.x + 5, cool.y + cool.height/2 - icon.height/2);
            check.setPosition(icon.x + icon.width/2 - check.width/2, icon.y + icon.height/2 - check.height/2);
            text.setPosition(icon.x + icon.width + 5, cool.y + cool.height/2 - text.height/2);
        }, onComplete: function() {
            new FlxTimer().start(1, function() {
                check.visible = true;
            });
            var resetX = check.scale.x; var resetY = check.scale.y;
            check.scale.set(1.25,1.25);
            FlxTween.tween(check.scale, {x: resetX, y: resetY}, 0.5, {startDelay: 1, ease:FlxEase.backOut});
            FlxTween.tween(cool, {x: FlxG.width + cool.width + 5}, 1, {startDelay: 3, ease: FlxEase.quadInOut, onUpdate: function() {
                icon.setPosition(cool.x + 5, cool.y + cool.height/2 - icon.height/2);
                check.setPosition(icon.x + icon.width/2 - check.width/2, icon.y + icon.height/2 - check.height/2);
                text.setPosition(icon.x + icon.width + 5, cool.y + cool.height/2 - text.height/2);
            }, onComplete: function() {
                for (item in [text, icon, check, cool]) {
                    item.destroy();
                    item.kill();
                    PlayState.remove(item, true);
                }
            }});
        }});
        }
    });
    challengeScript.loadFile();
    challengeScript.executeFunc("create", []);
    }
    DiscordClient.switchRPC("1165102365037301881");
}

var songEnded:Bool = false;
function musicstart() {
    ModSupport.modSaves[loadedMod].data.challengesData.get(editingMod).data[challengeID].vars.daData.set("hasCompletedChallenge", false);
    ModSupport.modSaves[loadedMod].flush();
}

function onPreUpdatePresence() {
    return false;
}

function onPreEndSong() {
    tokenMultiplier = (challengeScript != null) ? challengeScript.getVariable("tokenMultiplier") : 1;
    songEnded = true;
}