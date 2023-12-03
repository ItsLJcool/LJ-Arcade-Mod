// a
import MainMenuState;
import haxe.io.Path;
import haxe.Json;
import flixel.group.FlxTypedGroup;
import CoolUtil;
import AlphabetOptimized;
import FreeplayState;
import SongMetadata;
import HealthIcon;
import StringTools;
import flixel.math.FlxMath;
import PlayState;
import MenuMessage;
import Settings;
import LoadingState;
import MusicBeatState;
import sys.io.File;
import flixel.text.FlxTextBorderStyle;
import Highscore;
import Reflect;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxRect;
import flixel.addons.ui.FlxUI9SliceSprite;
import Date;
import Sys;
import Script;
import DummyScript;
import ModSupport;
import Array;
import sys.FileSystem;
import logging.LogsOverlay;
import flixel.group.FlxTypedSpriteGroup;
import flixel.FlxCamera;

var editingMod:String = "";
var menuStuff:FlxTypedGroup<FlxSprite>;

var configMod = Json.parse(File.getContent("mods/" + mod + "/config.json"));
var jsonContent = null;

var ChallengesDataScript:Script = null;
var modChallengeJust:Array<Dyanimc> = {hasCompleted: false};
/**
    [1.0.1] - Changed how save.data is stored, and added version control. | Added Custom Song Challenges
    [1.0.2] - functionality for Custom Song Challenges testing
    [1.1.0] - Custom Song Challenges seems to work, fixed saving issues.
    [2.0.0] - fucking redid how data is saved. (fixed in 2.0 :trollface:)
    [2.0.1] - I think the save.data is good yipee
    [2.1.0] - Fixed an issue with challenges for some reason not wanting to complete ;-;
    [2.1.1] - oops i suck at coding
    [2.1.2] - quick reset on saveData.

    # Upcomming
    [2.2.0] - Might want to make an "XP" System instead of just tokens.
    Basically Tokens are only gratned from challenges
    (might also allow them to set how much the challenge gives in tokens. WITH LIMITS)
    50 - 300 tokens maybe.
    XP unlocks more challenges, like you can only do 1 challenge a day unless you get like
    level 10, then you can do 2, level 15 -> 3.

    Levels can be used for the "Battle pass", basically just a roadmap of what you will get
    with each level. A shop would be cool too.

    Maybe end song whenever you complete challenge option? or wait until user has left the song.
    Can be edited within the mod or smth.

    [Still `2.2.0`]
    XP System should be the "Mods" tab (i might even re-do the ModEditing UI lol)
    You can see the Milestones ahead of time, max level should be capped at lvl 50
    It should take like 5 - 10 songs to level up once
    or a system like
    `lvl 1 - 5`: 2-3 songs to level up
    `lvl 6 - 20`: 4-5 songs to level up
    `lvl 21 - 40`: 5-6 songs to level up
    `lvl 41 - 59`: 8-10 songs to level up

    Each 10 Marker Milestone will unlock something new in the Menu maybe
    `level 1` - Shop unlock (Buy items)
    `Level 2` - Unlock Challenges menu
    `level 5` - Unlock 2nd Challenge
    `level 15` - Unlock 3rd Challenge (might make it 10)
    `level 20` - idk (???)

**/
var challengesVersion:String = "2.1.2";

var installedMods:Array<String> = FileSystem.readDirectory(Paths.get_modsPath());
function new(modYay:String, ?_modChallengeJust:Dyanimc) {
    var toRemove:Array<Dynamic> = [];
    for (item in installedMods) {
        if (!FileSystem.isDirectory("mods/"+item)
        || StringTools.contains(item.toLowerCase(), "yoshicrafterengine")
        || StringTools.contains(item.toLowerCase(), "crumbcat") // bro really?
        || StringTools.contains(item.toLowerCase(), mod.toLowerCase()))
            toRemove.push(item);
    }
    for (item in toRemove) installedMods.remove(item);
    if (_modChallengeJust != null) modChallengeJust = _modChallengeJust;

	if (modYay != null) editingMod = modYay;
    
	var p = Paths.json('freeplaySonglist', 'mods/'+modYay);
	if (Assets.exists(p)) {
        jsonContent = Json.parse(Assets.getText(p));
		if (jsonContent.songs != null)
			for (song in jsonContent.songs) freeplaySongs.push(SongMetadata.fromFreeplaySong(song, modYay));
	}
    if (jsonContent != null && jsonContent.songs == []) jsonContent = null;
    FlxG.mouse.visible = true;
    var theMod = editingMod;
    if (!Assets.exists(Paths.getLibraryPathForce("ljArcade/editData/ChallengesData.hx", "mods/" + theMod))) {
        theMod = mod;
    }
    ChallengesDataScript = Script.create(Paths.modsPath + "/" + mod + "/ljArcade/editData/ChallengesData.hx");
    ModSupport.setScriptDefaultVars(ChallengesDataScript, mod, {});
    if (ChallengesDataScript == null) ChallengesDataScript = new DummyScript();

    ChallengesDataScript.setVariable("create", function() {});
    ChallengesDataScript.setVariable("modEditingCreate", function() {});
    ChallengesDataScript.setVariable("setSongDataValues", function() {return false;});
    ChallengesDataScript.setVariable("loadedMod", mod);
    ChallengesDataScript.setVariable("accessingMod", editingMod);
    ChallengesDataScript.loadFile();

    var _contain = ChallengesDataScript.getVariable("containables");
    var _challengesData = ChallengesDataScript.getVariable("challengesData");
    var _disableGloablChallenges = ChallengesDataScript.getVariable("disableGloablChallenges");
    var _randomPercentDiff = ChallengesDataScript.getVariable("randomPercentDiff");
    if (_challengesData != null) challengesData = _challengesData;
    if (_contain != null) containables = _contain;
    if (_disableGloablChallenges != null) disableGloablChallenges = _disableGloablChallenges;
    if (_randomPercentDiff != null) randomPercentDiff = _randomPercentDiff;

    ChallengesDataScript.executeFunc("modEditingCreate", []);
}

var bg:FlxSprite;
var bgScale:Float = 1;

var ljRanks:FlxTypedGroup;

var tokenText:FlxText;
var tokenBG:FlxUI9SliceSprite;
var bgRect:FlxRect;

var menuItemsType = [ "freeplay", "shop", "challenges", "options", ];

var ljTokenTweens:Array<FlxTweens> = [];
function create(modThing:String, ?_modChallengeJust:Dyanimc) {
    FlxG.signals.postStateSwitch.removeAll();
    FlxG.signals.postUpdate.removeAll();
    LogsOverlay.hscript.variables.set("usingLJarcade", true);
    FlxG.signals.postStateSwitch.add(function() { // THIS IS BEFORE CREATE FOR THE SCRIPTS!!
        if (!Std.isOfType(FlxG.game._requestedState, PlayState)) return;

        FlxG.state.scripts.addScript(mod + "/states/ModTrack.hx");
        var laScript = FlxG.state.scripts.scripts[FlxG.state.scripts.scripts.length-1];
        laScript.setVariable("create", function() {});
        laScript.setVariable("loadedMod", mod);
        laScript.setVariable("editingMod", editingMod);
        laScript.setVariable("saveChallengesData", save.data.challengesData.get(editingMod));
        laScript.setVariable("challengeID", challengeID);
        laScript.setVariable("doingChallenge", doingChallenge);
        laScript.loadFile();
        laScript.executeFunc("create", []);
    });
    
	camHUD = new FlxCamera();
	camHUD.bgColor = 0;
	FlxG.cameras.add(camHUD, false);

	if (FlxG.sound.music == null || !FlxG.sound.music.playing)
        FlxG.sound.playMusic(existsInMods("music/freakyMenu.ogg", Paths.music("freakyMenu")));
    
	bg = new FlxSprite(0, 0, existsInMods("images/menuDesat.png", Paths.image("menuDesat")));
	bg.setGraphicSize(FlxG.width, FlxG.height);
    bgScale = bg.scale.x;
	bg.screenCenter();
    bg.alpha -= 0.15;
	add(bg);
    
	ljRanks = new FlxTypedGroup();
    ljRanks.cameras = [camHUD];
	add(ljRanks);
    
	menuStuff = new FlxTypedGroup();
	add(menuStuff);
    
	var modName = new FlxText(0, 0, 0, "Current Mod: " + editingMod, 24);
	modName.font = Paths.font("Funkin - No Outline.ttf");
	modName.scrollFactor.set();
	modName.updateHitbox();
    modName.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 1.5);
    modName.setPosition(150, 15);
    modName.cameras = [camHUD];
    add(modName);

    for (i in 0...menuItemsType.length) {
        var name = menuItemsType[i];
        var item = new FlxSprite(0,0, Paths.image("ModEditing/"+name));
        switch(name.toLowerCase()) {
            case "freeplay": item.setPosition(225, 100);
            case "shop": item.setPosition(175, 325);
            case "options": item.setPosition(575, 500);
            case "challenges":
                item.scale.set(0.85, 0.85);
                item.updateHitbox();
                item.setPosition(500, 330);
        }
        item.ID = i;
        FlxMouseEventManager.add(item, function(){}, function(){
            selection();
        }, function(){
            if (curSel == item.ID || curSelectedType.toLowerCase() == "") return;
            FlxG.sound.play(existsInMods("sounds/scrollMenu.ogg", Paths.sound("scrollMenu")));
            curSel = item.ID;
            changeSelMenu(0);
        }, function() {}, true, true, false);
        menuStuff.add(item);
    }
    nothingHere = new FlxText(0,0,0, "There is nothing here at the moment", 32);
    nothingHere.screenCenter();
    nothingHere.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 1.5);
    nothingHere.alpha = 0.0001;
    add(nothingHere);

    changeSelMenu(0);
    if (jsonContent != null) {
        makeFreeplayData();
        makeSaveData();
        makeNewChallengeCards(-1, true);
    }
    makeShopItems();
    
	colorOmogo = new CustomShader(Paths.shader("amongSus", mod));
	setOmogusShador(colorOmogo, {
		fill: 0xFFBBFF00,
		outline: 0xFF00FF00,
		gradientData: {
			gradient: true,
			coloredGradient: true,

			fillCap: {min: 0, max: 3},
			outlineCap: {min: 0, max: 3},

			fillGrad: 0xFFBBFF00,
			outlineGrad: 0xFF043104,
		}
	});
    otherOmogo = new CustomShader(Paths.shader("amongSus", mod));
	setOmogusShador(otherOmogo, {
		fill: 0xFF004a00,
		outline: 0xFF004a00,
		gradientData: {
			gradient: true,
			coloredGradient: true,

			fillCap: {min: 0, max: 2},
			outlineCap: {min: 0, max: 2},

			fillGrad: 0xFF004a19,
			outlineGrad: 0xFF004a19,
		}
	});

    var rankBG = new FlxSprite(0,0, Paths.image("ModEditing/RankBar"));
    rankBG.scale.set(0.9,0.9);
    rankBG.updateHitbox();
    rankBG.setPosition(FlxG.width - rankBG.width, 0);
    rankBG.antialiasing = true;
    ljRanks.add(rankBG);
    
    var ljTokenImage = new FlxSprite(0,0, Paths.image("ljtoken"));
    ljTokenImage.setGraphicSize(65, 65);
    ljTokenImage.scale.set(Math.min(ljTokenImage.scale.x, ljTokenImage.scale.y), Math.min(ljTokenImage.scale.x, ljTokenImage.scale.y)); // Thanks math :dies of horrable math death:
    ljTokenImage.updateHitbox();
    ljTokenImage.setPosition(FlxG.width - ljTokenImage.width - 7, rankBG.y);
    ljTokenImage.antialiasing = true;
    ljRanks.add(ljTokenImage);

	var ljTokens = new FlxText(0, 0, 0, condenseInt(save.data.levelSystem.tokenData.tokens).toLowerCase(), 32);
	ljTokens.font = Paths.font("Funkin - No Outline.ttf");
	ljTokens.scrollFactor.set();
    ljTokens.alignment = "right";
    // ljTokens.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 1);
	ljTokens.updateHitbox();
    ljTokens.setPosition(ljTokenImage.x - ljTokenImage.width - ljTokens.width/2 + 8, ljTokenImage.y + ljTokenImage.height/2 - ljTokens.height/2);
    ljRanks.add(ljTokens);
    
    var ranky = "RANK: ";
    if (save.data.levelSystem.xpData.level < save.data.levelSystem.xpData.capLevel) ranky += Std.string(save.data.levelSystem.xpData.level);
    else if (save.data.levelSystem.xpData.level >= save.data.levelSystem.xpData.capLevel) ranky += Std.string(save.data.levelSystem.xpData.level) + " (Max)";
	var rankThing = new FlxText(0, 0, 0, ranky, 28);
	rankThing.font = Paths.font("Funkin - No Outline.ttf");
	rankThing.scrollFactor.set();
    rankThing.alignment = "right";
    // rankThing.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 1);
	rankThing.updateHitbox();
    rankThing.setPosition(rankBG.x + 60, 0);
    ljRanks.add(rankThing);

    var xpBrr = Std.string(save.data.levelSystem.xpData.xp) + "xp / " + Std.string(save.data.levelSystem.xpData.xpToLevelUp)+"xp";
	var xpStuff = new FlxText(0, 0, 0, xpBrr.toLowerCase(), 16);
	xpStuff.font = Paths.font("Funkin - No Outline.ttf");
	xpStuff.scrollFactor.set();
    xpStuff.alignment = "center";
    // xpStuff.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 1);
	xpStuff.updateHitbox();
    xpStuff.setPosition(rankBG.x + 190, rankThing.y + 15);
    ljRanks.add(xpStuff);

    var percent = save.data.levelSystem.xpData.xp/save.data.levelSystem.xpData.xpToLevelUp;

    var barLevelWhite = new FlxUI9SliceSprite(0,0, Paths.image("ModEditing/barLevel"), new Rectangle(0,0, 500, 35), [72, 0, 77, 35]);
    barLevelWhite.scale.set(0.5,0.5);
    barLevelWhite.updateHitbox();
    barLevelWhite.setPosition(rankBG.x + 65, rankBG.y + rankBG.height/2 - barLevelWhite.height/2 + 10);
    barLevelWhite.antialiasing = true;
    barLevelWhite.flipX = true;
    barLevelWhite.shader = otherOmogo;
    ljRanks.add(barLevelWhite);
    
    var barLevelFilled = new FlxUI9SliceSprite(0,0, Paths.image("ModEditing/barLevel"), new Rectangle(0,0, 500, 35), [72, 0, 77, 35]);
    barLevelFilled.scale.set(0.5,0.5);
    barLevelFilled.updateHitbox();
    barLevelFilled.setPosition(rankBG.x + 65, rankBG.y + rankBG.height/2 - barLevelFilled.height/2 + 10);
    barLevelFilled.antialiasing = true;
	bgRect = new FlxRect(0, 0, barLevelFilled.frameWidth*(percent + 0.001), barLevelFilled.frameHeight);
    barLevelFilled.clipRect = bgRect;
    barLevelFilled.shader = colorOmogo;
    ljRanks.add(barLevelFilled);

    if (modChallengeJust.hasCompleted) {
        if (save.data.challengesData.get(editingMod).data[modChallengeJust.dataID.itemID].vars.daData.get("hasCompletedChallenge"))
            hasCompletedChallenge();
    }
    Conductor.changeBPM(configMod.intro.bpm); // L Config File
}

function condenseInt(inted:Int) {
    inted = Std.parseInt(inted);
    if (inted < 999) return Std.string(inted);
    else {
        if (Math.floor(roundToDecimals(inted/1000000000, 2)) >= 1) {
            return roundToDecimals(inted/1000000000, 2) + "B"; // how?
        }
        if (Math.floor(roundToDecimals(inted/1000000, 2)) >= 1) {
            return roundToDecimals(inted/1000000, 2) + "M";
        }
        return roundToDecimals(inted/1000, 2) + "K";
    }
    return "a number, sorry lol";
}
function roundToDecimals(value:Float, decimalPlaces:Int):Float {
    var multiplier:Float = Math.pow(10, decimalPlaces);
    return Math.floor(value * multiplier) / multiplier;
}

function hasCompletedChallenge() {
    curSelectedType = "";
    dontChangeItem = modChallengeJust.dataID.itemID;
    menuStuff.forEach(function(item) {
        item.x = 0 - item.width - 90;
    });
    for (item in challengesBGstuff) {
        item.y = (item.height + 5)*(item.ID+1) - 75;
    }
    var icon = challengeGroupArray[modChallengeJust.dataID.itemID][2];
    
    var check:FlxSprite = new FlxSprite(0,0, existsInMods("ljArcade/images/checkmark.png", Paths.image("Checkmark")));
    check.setGraphicSize(icon.frameWidth - 50, icon.frameWidth - 50);
    check.updateHitbox();
    check.visible = false;
    check.setPosition(icon.x + icon.width/2 - check.width/2, icon.y + icon.height/2 - check.height/2);
    add(check);
    var resetX = check.scale.x; var resetY = check.scale.y;
    check.scale.set(1.25,1.25);
    FlxTween.tween(check.scale, {x: resetX, y: resetY}, 0.5, {startDelay: 0.5, ease:FlxEase.backOut, onStart: function() {
        check.setPosition(icon.x + icon.width/2 - check.width/2, icon.y + icon.height/2 - check.height/2);
        check.visible = true;
    }});
    var theChallengeBG = challengesBGstuff[modChallengeJust.dataID.itemID];
    FlxTween.tween(theChallengeBG, {x: FlxG.width + theChallengeBG.width + 10}, 1, {startDelay: 3, ease:FlxEase.quadInOut, onComplete: function() {
        changeData(modChallengeJust.dataID.itemID);
        check.destroy();
        check.kill();
        remove(check, true);
        theChallengeBG.x = 0 - theChallengeBG.width - 20;
        FlxTween.tween(theChallengeBG, {x: FlxG.width/2 - theChallengeBG.width/2}, 1, {ease:FlxEase.quadOut, onComplete: function() {
            curSelectedType = "challenges";
            canSelectChallenge = true;
            dontChangeItem = -1;
        }});
        
    }, onUpdate: function() {
        check.setPosition(icon.x + icon.width/2 - check.width/2, icon.y + icon.height/2 - check.height/2);
    }});
    checkTimeOnChallenges();
}

var curSel:Int = 0;
function changeSelMenu(hur:Int = 0) {
    curSel = CoolUtil.wrapInt(curSel + hur, 0, menuItemsType.length);
    menuStuff.forEach(function(item) {
        // item.animation.play(((item.ID == curSel) ? "selected" : "normal"), true);
        if (item.ID == curSel) {
            switch(item.ID) {
                case 0,2:
                    if (jsonContent == null) {
                        item.colorTransform.redMultiplier = 0.25;
                        item.colorTransform.greenMultiplier = 0.5;
                        item.colorTransform.blueMultiplier = 0.25;
                    } else {
                        item.colorTransform.redMultiplier = 0.25;
                        item.colorTransform.greenMultiplier = 1;
                        item.colorTransform.blueMultiplier = 0.25;
                    }
                default:
                    item.colorTransform.redMultiplier = 0.25;
                    item.colorTransform.greenMultiplier = 1;
                    item.colorTransform.blueMultiplier = 0.25;
            }
            // item.shader = invert;
        }
        else {
            switch(item.ID) {
                case 0,2:
                    if (jsonContent == null) {
                        item.colorTransform.redMultiplier = 0;
                        item.colorTransform.greenMultiplier = 0;
                        item.colorTransform.blueMultiplier = 0;
                    } else {
                        item.colorTransform.redMultiplier = 1;
                        item.colorTransform.greenMultiplier = 1;
                        item.colorTransform.blueMultiplier = 1;
                    }
                default:
                    item.colorTransform.redMultiplier = 1;
                    item.colorTransform.greenMultiplier = 1;
                    item.colorTransform.blueMultiplier = 1;
            }
            // item.shader = null;
        }
    });
}
function menuSel() {
    curSelectedType = "";
    if (jsonContent == null) {
        switch(menuItemsType[curSel].toLowerCase()) {
            case "freeplay", "challenges":
                FlxG.sound.play(existsInMods("sounds/disabledMenu.ogg", Paths.sound("disabledMenu")));
                new FlxTimer().start(0.25, function() {
                    curSelectedType = "menu";
                });
                return;
        }
    }

    menuStuff.forEach(function(item) {
        if (item.ID == curSel) {
            new FlxTimer().start(0.075, function(tmr) {
                item.colorTransform.redMultiplier = (tmr.loopsLeft % 2 == 0) ? 1 : 0.25;
                item.colorTransform.greenMultiplier = 1;
                item.colorTransform.blueMultiplier = (tmr.loopsLeft % 2 == 0) ? 1 : 0.25;
                if (tmr.loopsLeft == 0) {
                    new FlxTimer().start(0.5, function() {
                        switch(menuItemsType[item.ID].toLowerCase()) {
                            case "freeplay": if (jsonContent != null) freeplayInit(menuItemsType[item.ID].toLowerCase());
                            case "challenges": if (jsonContent != null) challengesEnter(menuItemsType[item.ID].toLowerCase());
                            case "shop": doShop();
                            default: 
                                curSelectedType = menuItemsType[item.ID].toLowerCase();
                                FlxTween.tween(nothingHere, {alpha: 1}, 0.75, {ease: FlxEase.quadInOut});
                        }
                    });
                }
            }, 10);
        }
        switch(item.ID) {
            case 0: FlxTween.tween(item, {y: 0 - item.height - 10}, 0.5, {startDelay: 0.75, ease: FlxEase.quadIn});
            case 1: FlxTween.tween(item, {x: 0 - item.width - 10}, 0.5, {startDelay: 0.75, ease: FlxEase.quadIn});
            case 2: FlxTween.tween(item, {x: FlxG.width + item.width + 10}, 0.5, {startDelay: 0.75, ease: FlxEase.quadIn});
            case 3: FlxTween.tween(item, {y: FlxG.height + item.height + 10}, 0.5, {startDelay: 0.75, ease: FlxEase.quadIn});
        }
    });
    FlxG.sound.play(existsInMods("sounds/confirmMenu.ogg", Paths.sound("confirmMenu")));
}

var grpSongs:FlxTypedGroup<AlphabetOptimized>;
var iconArray:Array<FlxSprite> = [];

var scoreText:FlxText;
var diffText:FlxText;
var scoreBG:FlxSprite;
function makeFreeplayData() {
	grpSongs = new FlxTypedGroup();
	add(grpSongs);
    
	scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
	scoreText.setFormat(Paths.font("vcr.ttf"), 32, 0xFFFFFFFF, "right");
	scoreText.antialiasing = true;
    scoreText.x = FlxG.width + scoreText.width + 5;

	scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 99, 0xFF000000, true);
    scoreBG.x = FlxG.width + scoreText.width + 5;
	scoreBG.alpha = 0.6;

	diffText = new FlxText(scoreText.x, scoreText.y + 36, FlxG.width - scoreText.x, "placeHolder", 24);
    diffText.x = FlxG.width + scoreText.width + 5;
	diffText.font = scoreText.font;
	diffText.alignment = "center";
	diffText.antialiasing = true;

    add(scoreBG);
    add(diffText);
    add(scoreText);
    for (s in freeplaySongs) _freeplaySongs.push(s);
    refreshFreeplaySongs();
}

var freeplaySongs:Array<Dynamic> = [];
var _freeplaySongs:Array<Dynamic> = [];
function refreshFreeplaySongs() {
    curFreeplaySel = 0;
    grpSongs.forEach(function(s) {
        s.destroy();
        grpSongs.remove(s, true);
        remove(s);
    });
    remove(grpSongs);
    
    grpSongs = new FlxTypedGroup();
    add(grpSongs);
    for(e in iconArray) {
        e.destroy();
        remove(e);
    }
    _freeplaySongs = CoolUtil.filterNulls(_freeplaySongs); // no more **null**
    iconArray = [];
    if (_freeplaySongs.length <= 0) {
        var md = new SongMetadata('No soundtrack', editingMod, 'unknown');
        md.difficulties = ["-"];
        md.disabled = true;
        _freeplaySongs.push(md);
    } else {
        for (i in 0..._freeplaySongs.length) {
            var songName = _freeplaySongs[i].songName;
            if (_freeplaySongs[i].displayName != null) songName = _freeplaySongs[i].displayName;
            var t = StringTools.replace(songName, "-", " ");
            var songText:AlphabetOptimized = new AlphabetOptimized(0, (70 * i) + 30, t, Math.min(1, (FlxG.width - 256) / (51 * t.length)));
            // songText.isMenuItem = true;
            songText.targetY = i;
            songText.ID = i;
            if (_freeplaySongs[i].disabled) songText.textColor = 0xFF888888;
            grpSongs.add(songText);
            var icon:HealthIcon = new HealthIcon(_freeplaySongs[i].songCharacter, false, _freeplaySongs[i].mod);
            icon.sprTracker = songText;
            iconArray.push(icon);
            add(icon);
        }
    }
    freeplaySel(0);
    freeplayDiff(0);
}

function freeplayInit(type:String) {
    curSelectedType = type;
    FlxTween.tween(scoreText, {x: FlxG.width * 0.7, y: 5}, 0.5, {onUpdate: function() {
        scoreBG.x = scoreText.x - 6;
        diffText.setPosition(scoreText.x, scoreText.y + 36);
    }, ease:FlxEase.quadInOut});
}

var curFreeplaySel:Int = 0;
function freeplaySel(hur:Int = 0) {
    curFreeplaySel = CoolUtil.wrapInt(curFreeplaySel + hur, 0, grpSongs.members.length);
    intendedScore = Highscore.getModScore(editingMod, _freeplaySongs[curFreeplaySel].songName, _freeplaySongs[curFreeplaySel].difficulties[curDifficulty]);
    for (i in 0...grpSongs.members.length) {
        var item = grpSongs.members[i];
        item.targetY = i - curFreeplaySel;
        item.alpha = (item.targetY == 0) ? 1 : 0.6;
    }
    freeplayDiff(0);
}

var curDifficulty:Int = 0;
function freeplayDiff(hur:Int = 0) {
    curDifficulty = CoolUtil.wrapInt(curDifficulty + hur, 0, _freeplaySongs[curFreeplaySel].difficulties.length);

    intendedScore = Highscore.getModScore(editingMod, _freeplaySongs[curFreeplaySel].songName, _freeplaySongs[curFreeplaySel].difficulties[curDifficulty]);
		
	diffText.text = switch(_freeplaySongs[curFreeplaySel].difficulties.length) {
		case 0:
			'';
		case 1:
			_freeplaySongs[curFreeplaySel].difficulties[0].toUpperCase();
		default:
			'< ' + _freeplaySongs[curFreeplaySel].difficulties[curDifficulty].toUpperCase() + ' >';
	}
}

var lerpScore:Int = 0;
var intendedScore:Int = 0;
function freeplayEnter(song:String) {
    song = StringTools.replace(song.toLowerCase(), " ", "-");
    if (_freeplaySongs[curFreeplaySel].disabled) {
        FlxG.sound.play(existsInMods("sounds/disabledMenu.ogg", Paths.sound("disabledMenu")));
        return;
    }

    Settings.engineSettings.data.lastSelectedSong = editingMod + ":" + _freeplaySongs[curFreeplaySel].songName.toLowerCase();
    Settings.engineSettings.data.lastSelectedSongDifficulty = _freeplaySongs[curFreeplaySel].difficulties[curDifficulty];

    var code:CoolUtil.FunkinCodes;
    if ((code = CoolUtil.loadSong(editingMod, _freeplaySongs[curFreeplaySel].songName.toLowerCase(), _freeplaySongs[curFreeplaySel].difficulties[curDifficulty], _freeplaySongs[curFreeplaySel].difficulties)) == 0) {
        LoadingState.loadAndSwitchState(new PlayState());
    } else
        openSubState(new MenuMessage('Chart for ' + _freeplaySongs[curFreeplaySel].songName + " - " + _freeplaySongs[curFreeplaySel].difficulties[curDifficulty] + ' does not exist.'));
}

function selection() {
    switch(curSelectedType.toLowerCase()) {
        case "menu": menuSel();
        case "freeplay": if (grpSongs.members != null || grpSongs.members.length != 0) freeplayEnter(grpSongs.members[curFreeplaySel].text);
        case "challenge_diff": enterChallengeSong(challengeID.songID);
    }
}

var curSelectedType:String = "menu";
var updateTimeChallenges:Float = 0;
var currentColor = 0xFFFFFFFF;

var scrollY:Float = 0;
var mousePrevY:Float = 0;
function update(elapsed:Float) {
    bg.color = FlxColor.interpolate(bg.color, currentColor, elapsed*5);
    lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(0.4 * 60 * elapsed, 0, 1)));
    if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
    if (scoreText != null) scoreText.text = "PERSONAL BEST:" + lerpScore;
    if (grpSongs != null) grpSongs.forEach(function(item) {
        var scaledY = FlxMath.remapToRange(item.targetY, 0, 1, 0, 1.3);
        var h:Float = FlxG.height;
        var w:Float = FlxG.width;
        if (item.wentToTargetY) {
            item.y = FlxMath.lerp(item.y, (scaledY * 120) + (h * 0.48), 0.13 * 60 * FlxG.elapsed);
            item.x = FlxMath.lerp(item.x, (curSelectedType == "freeplay") ? (item.targetY * 20) + 90 : (0 - item.width - iconArray[item.ID].width) - 150, 0.13 * 60 * FlxG.elapsed);
        } else {
            item.x = (item.targetY * 20) + 90 - w;
            item.y = (scaledY * 120) + (h * 0.48);
            item.wentToTargetY = true;
        }
    });
    if (FlxControls.anyJustPressed([37, 65])) {
        switch(curSelectedType.toLowerCase()) {
            case "freeplay": freeplayDiff(-1);
            case "challenge_diff": challengeDiff(-1);
            case "menu":
                FlxG.sound.play(existsInMods("sounds/scrollMenu.ogg", Paths.sound("scrollMenu")));
                changeSelMenu(-1);
        }
    }
    if (FlxControls.anyJustPressed([39, 68])) {
        switch(curSelectedType.toLowerCase()) {
            case "freeplay": freeplayDiff(1);
            case "challenge_diff": challengeDiff(1);
            case "menu":
                FlxG.sound.play(existsInMods("sounds/scrollMenu.ogg", Paths.sound("scrollMenu")));
                changeSelMenu(1);
        }
    }
    if (FlxControls.anyJustPressed([38, 87])) {
        switch(curSelectedType.toLowerCase()) {
            case "freeplay": freeplaySel(-1);
            default: return;
        }
        if (curSelectedType.toLowerCase() != "") FlxG.sound.play(existsInMods("sounds/scrollMenu.ogg", Paths.sound("scrollMenu")));
    }
    if (FlxControls.anyJustPressed([40, 83])) {
        switch(curSelectedType.toLowerCase()) {
            case "freeplay": freeplaySel(1);
            default: return;
        }
        if (curSelectedType.toLowerCase() != "") FlxG.sound.play(existsInMods("sounds/scrollMenu.ogg", Paths.sound("scrollMenu")));
    }
    if (FlxControls.anyJustPressed([13])) {
        selection();
    }
    if (FlxControls.anyJustPressed([8, 27])) {
        if (curSelectedType.toLowerCase() == "") return;
        FlxTween.tween(nothingHere, {alpha: 0.0001}, 0.75, {ease: FlxEase.quadInOut});
        var time = 0;
        var goBackToMenu:Bool = true;
        completeFunc = function() {};
        switch(curSelectedType.toLowerCase()) {
            case "menu":
                FlxG.signals.postStateSwitch.removeAll();
                FlxG.signals.postUpdate.removeAll();
                LogsOverlay.hscript.variables.set("usingLJarcade", false);
                FlxG.switchState(new MainMenuState());
            case "freeplay":
                time = 0.25;
                FlxTween.tween(scoreText, {x: FlxG.width + scoreText.width + 5}, 0.75, {ease:FlxEase.quadInOut});
                FlxTween.tween(scoreBG, {x: FlxG.width + scoreText.width + 5}, 0.75, {ease:FlxEase.quadInOut});
                FlxTween.tween(diffText, {x: FlxG.width + scoreText.width + 5}, 0.75, {ease:FlxEase.quadInOut});
            case "challenges":
                canSelectChallenge = false;
                time = 1.26 + (0.5/(challengesBGstuff.length)) * 0.3;
                for (item in challengesBGstuff) {
                    FlxTween.tween(item, {y: FlxG.height + (item.height + 10)*(item.ID+1)}, 1.25, {startDelay: (0.5/(item.ID+1)) * 0.3, ease:FlxEase.backIn});
                }
            case "challenge_diff":
                goBackToMenu = false;
                curSelectedType = "challenges";
                diffStuff.forEach(function(item) {
                    item.visible = false;
                });
                canSelectChallenge = true;
            case "shop":
                currentColor = 0xFFFFFFFF;
            default:
                if (curSelectedType.toLowerCase() != "")
                trace("item isn't here yet: " + curSelectedType.toLowerCase());
        }
        if (!goBackToMenu) return;
        curSelectedType = "";
        new FlxTimer().start(time, function(tmr) {
            menuStuff.forEach(function(item) {
                var pos = new FlxPoint(0,0);
                switch(item.ID) {
                    case 0: pos.x = 225; pos.y = 100;
                    case 1: pos.x = 175; pos.y = 325;
                    case 2: pos.x = 500; pos.y = 330;
                    case 3: pos.x = 575; pos.y = 500;
                }
                item.updateHitbox();
                item.alpha = 1;
                FlxTween.tween(item, {x: pos.x, y: pos.y},
                0.75, {ease: FlxEase.circOut, onComplete: function() {
                    curSelectedType = "menu";
                    completeFunc();
                    changeSelMenu(0);
                }});
            });
        });
    }
    if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
    var lerp = FlxMath.lerp(bgScale + 0.025, bgScale, FlxEase.cubeOut(curDecBeat % 1));
    bg.scale.set(lerp,lerp);

    for (i in 0...challengeGroupArray.length) {
        var item = challengeGroupArray[i];
        var daImage = challengesBGstuff[item[0].ID];
        var clock = item[0];
        var clockText = item[1];
        var icon = item[2];
        var info = item[3];
        var playSong = item[4];
        var playIcon = item[5];
    
        icon.setPosition(daImage.x + 15, daImage.y + daImage.height/2 - icon.height/2); // icon left side
        info.setPosition(icon.x + icon.width + 5, daImage.y + daImage.height/2 - info.height/2);
    
        playSong.setPosition(daImage.x + daImage.width - playSong.width - 25, daImage.y + daImage.height/2 - playSong.height/2);
        playIcon.setPosition(playSong.x + playSong.width/2 - playIcon.width/2, playSong.y + playSong.height/2 - playIcon.height/2);
    
        clockText.setPosition(playSong.x - clockText.width, daImage.y + clockText.height);
        clock.setPosition(clockText.x - clock.width - 5, clockText.y + clockText.height/2 - clock.height/2);
    }
    updateTimeChallenges += elapsed;
    if (updateTimeChallenges > 1) {
        updateTimeChallenges = 0;
        checkTimeOnChallenges();
    }


    if (FlxG.mouse.pressed && FlxG.mouse.justMoved) {
        scrollY += -(FlxG.mouse.y - mousePrevY)*2;
    }
    mousePrevY = FlxG.mouse.y;

    if ((shopAssets != null && curSelectedType.toLowerCase() == "shop") || shopSectons != 0) {
        scrollY += FlxG.mouse.wheel * 50;
        scrollY = FlxMath.bound(scrollY, 0, (shopAssets.height - shopAssets.members[shopSectons].height));
        shopAssets.y = FlxMath.lerp(shopAssets.y, -scrollY, CoolUtil.getLerpRatio(0.25));
    }
    if (targetSprShop != null) selShopSpr.setPosition(targetSprShop.x, targetSprShop.y);
    else selShopSpr.visible = false;
}

var canSelectChallenge:Bool = false;
var challengeDiffValue:Int = 0;
var challengeID = {};
function challengeDiff(hur:Int = 0) {
    challengeDiffValue = CoolUtil.wrapInt(challengeDiffValue + hur, 0, _freeplaySongs[challengeID.songID].difficulties.length);
	diffStuff.members[2].text = switch(_freeplaySongs[challengeID.songID].difficulties.length) {
		case 0:
			'';
		case 1:
			_freeplaySongs[challengeID.songID].difficulties[0].toUpperCase();
		default:
			'< ' + _freeplaySongs[challengeID.songID].difficulties[challengeDiffValue].toUpperCase() + ' >';
	}
    diffStuff.members[2].updateHitbox();
    diffStuff.members[2].screenCenter();
    diffStuff.members[2].y = diffStuff.members[1].y + diffStuff.members[1].height/2 - diffStuff.members[2].height/2;
}
var doingChallenge:Bool = false;
function enterChallengeSong(id:Int) {
    doingChallenge = true;
    Settings.engineSettings.data.lastSelectedSong = editingMod + ":" + _freeplaySongs[id].songName.toLowerCase();
    Settings.engineSettings.data.lastSelectedSongDifficulty = _freeplaySongs[id].difficulties[challengeDiffValue];

    var code:CoolUtil.FunkinCodes;
    if ((code = CoolUtil.loadSong(editingMod, _freeplaySongs[id].songName.toLowerCase(), _freeplaySongs[id].difficulties[challengeDiffValue], _freeplaySongs[id].difficulties)) == 0) {
        LoadingState.loadAndSwitchState(new PlayState());
    } else {
        doingChallenge = false;
        openSubState(new MenuMessage('Chart for ' + _freeplaySongs[id].songName + " - " + _freeplaySongs[id].difficulties[challengeDiffValue] + ' does not exist.'));
    }
}

var timesInFuture:Array<Dynamic> = [
    60 * 1000, // 1 Minute
    60 * 60 * 1000, // 1 Hour
    60 * 60 * 24 * 1000, // 1 Day
];
var dontChangeItem:Int = -1;
var coolTime:Int = 2;
function checkTimeOnChallenges() {
    if (jsonContent == null) return;
    var getChallTime = save.data.challengesData.get(editingMod).data;
    var ugh:Int = 0;
    for (item in getChallTime) ugh++;
    var nowDate = Date.now().getTime();
    for (i in 0...ugh) {
        if (dontChangeItem == i) continue;

        var coolTime = (getChallTime[i].vars.daData.get("timeOnChallenge") != null) ? getChallTime[i].vars.daData.get("timeOnChallenge") : 2;
        var timeLeft = Math.abs( nowDate - (getChallTime[i].date + timesInFuture[coolTime] ));
        var minutesLeft = (timeLeft / (60*1000)) % 60;
        var hoursLeft = (timeLeft / ((60*60)*1000)) % 24;
        var daysLeft = (timeLeft / ((60*60*24)*1000));
        var time = '[d]d, [h]h, [m]m';
        var addTime:Bool = true;
        if (addTime) time += ", [s]s"; // togglable?

        if (Std.int(daysLeft) == 0) time = StringTools.replace(time, "[d]d, ", "");
        else time = StringTools.replace(time, "[d]", Std.string(Std.int(daysLeft)));

        if (Std.int(hoursLeft) == 0) time = StringTools.replace(time, "[h]h, ", ""); 
        else time = StringTools.replace(time, "[h]", Std.string(Std.int(hoursLeft)));
        
        if (Std.int(minutesLeft) == 0)  {
            if (!addTime) time = Std.string(Std.int(timeLeft / 1000) % 60)+"s";
            time = StringTools.replace(time, "[m]m,", "");
        }
        else time = StringTools.replace(time, "[m]", Std.string(Std.int(minutesLeft)));
        if (addTime) time = StringTools.replace(time, "[s]", Std.string(Std.int(timeLeft / 1000) % 60));
        if (Std.int(timeLeft / 1000) == 0) time = "Soon...";

        challengeGroupArray[i][1].text = time;
        var among = [];
        for (e in 0...ugh) among.push(getChallTime[e].vars.daData.get("songID"));
        if (nowDate > getChallTime[i].date + timesInFuture[coolTime]) changeData(i, among);
    }
}
/**
    [s] - Song Name
    [att] - Attribute (ex: 2x Speed)
    [tokens] - Multiplier for Tokens
**/
var containables:Array<Dynamic> = [
    "[s]",
];

var disableGloablChallenges:Bool = false;
var randomPercentDiff:Int = 50.0;

var challengesData:Map = [
    "challengesToDo" => [
        0 => ["Play [s]"],
    ],
    "songSpecificChallenges" => null,
];

function challengesEnter(type:String) {
    for (item in challengesBGstuff) {
        FlxTween.tween(item, {y: (item.height + 5)*(item.ID+1) - 75}, 1, {startDelay: (0.5*item.ID) * 0.3, ease: FlxEase.quadOut});
    }
    new FlxTimer().start(1 + (0.5*challengesBGstuff.length) * 0.3, function() {
        curSelectedType = type;
        canSelectChallenge = true;
    });
}

/**
    .length should be the number of challenge, hence challengeID ig
**/
var challengeGroupArray:Array<Dynamic> = [];
var challengesBGstuff:Array<Dynamic> = [];
var diffStuff:FlxTypedGroup;
function makeNewChallengeCards(?id:Int, ?init:Bool) {
    if (init == null) init = false;
    if (id == null) id = -1;
    var challengeCoolData = save.data.challengesData.get(editingMod).data;
    if (init) {
        for (i in 0...challengeCoolData.length) {
            var slot = new FlxUI9SliceSprite(0,0, (existsInMods("ljArcade/images/SquareShit.png", Paths.image("SquareShit"))),
            new Rectangle(0, 0, FlxG.width - 200, FlxG.height/3 - 75), [20, 20, 460, 460]);
            slot.color = 0xFF000000;
            slot.alpha = 0.5;
            slot.screenCenter();
            slot.y = FlxG.height + slot.height + 10;
            slot.ID = i;
            add(slot);
            challengesBGstuff.push(slot);
        }
    }

    if (id != -1) {
        for (item in challengeGroupArray[id]) {
            if (item == null) continue;
            item.destroy();
            item.kill();
            remove(item, true);
        }
        challengeGroupArray[id] = [];
        challengeGroupArray[id] = doChallengeSpr(id);
    } else {
        for (i in 0...challengeCoolData.length) challengeGroupArray.push(doChallengeSpr(i));
    }
    for (arry in challengeGroupArray) {
        for (item in arry) add(item);
    }

    if (init) {
        diffStuff = new FlxTypedGroup();
        add(diffStuff);
        
        var bgDarken:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        bgDarken.scrollFactor.set();
        bgDarken.screenCenter();
        bgDarken.alpha = 0.3;
        diffStuff.add(bgDarken);
        var diffBG = new FlxUI9SliceSprite(0,0, (Paths.image('SquareShit')),
        new Rectangle(0, 0, 700, 300), [20, 20, 460, 460]);
        diffBG.color = 0xFF000000;
        diffBG.alpha = 0.9;
        diffBG.screenCenter();
        diffStuff.add(diffBG);
        
        var diffText:FlxText = new FlxText(0,0, 0, "placeholder", 26);
        diffText.updateHitbox();
        diffText.screenCenter();
        diffText.y = diffBG.y + diffBG.height/2 - diffText.height/2;
        diffStuff.add(diffText);
        diffStuff.forEach(function(item) {
            item.visible = false;
        });
    }
}
function doChallengeSpr(i) {
    var modChallenges = save.data.challengesData.get(editingMod).data;
    var healthIcon = modChallenges[i].vars.daData.get('icon');
    var infoText = modChallenges[i].vars.daText;
    var songID = modChallenges[i].vars.daData.get('songID');

    var slot = challengesBGstuff[i];

    var timeClock:FlxSprite = new FlxSprite(0,0, existsInMods("ljArcade/images/clockIcon.png", Paths.image("clockIcon")));
    timeClock.setGraphicSize(25, 25);
    timeClock.updateHitbox();
    timeClock.ID = i;

    var timeLeft:FlxText = new FlxText(0,0,0, "", 12);
    timeLeft.updateHitbox();
    timeLeft.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 1.5);
    timeLeft.ID = i;

    var icon:HealthIcon = new HealthIcon(healthIcon, false, editingMod);
    icon.updateHitbox();
    icon.setPosition(slot.x + 15, slot.y + slot.height/2 - icon.height/2);
    icon.ID = i;

    playSong = new FlxUI9SliceSprite(0,0, (Paths.image('SquareShit')), new Rectangle(0, 0, 75, 75), [20, 20, 460, 460]);
    playSong.antialiasing = true;
    playSong.color = 0xFF3A7431;
    playSong.updateHitbox();
    playSong.ID = i;
    playSong.setPosition(slot.x + slot.width - playSong.width - 25, slot.y + slot.height/2 - playSong.height/2);

    var playIcon:FlxSprite = CoolUtil.createUISprite("play");
    playIcon.scale.set(2.5,2.5);
    playIcon.updateHitbox();
    playIcon.setPosition(playSong.x + playSong.width/2 - playIcon.width/2, playSong.y + playSong.height/2 - playIcon.height/2);
    playIcon.ID = i;

    var info:FlxText = new FlxText(0,0, slot.width - icon.width - playSong.width - 20, infoText, 24);
    info.setGraphicSize(slot.width - icon.width - playSong.width - 20, info.height);
    info.setPosition(icon.x + icon.width + 5, slot.y + slot.height/2 - info.height/2);
    info.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 4);
    info.ID = i;

    for (item in [playSong, playIcon]) {
        FlxMouseEventManager.add(item, function(){}, function(){
            if (!canSelectChallenge) return;
            diffStuff.forEach(function(item) {
                item.visible = true;
            });
            curSelectedType = "challenge_diff";
            canSelectChallenge = false;
            challengeID = {itemID: i, songID: songID, songSpecific: save.data.challengesData.get(editingMod).data[i].vars.daData.get("isSongSpecific"), challengeID: save.data.challengesData.get(editingMod).data[i].vars.daData.get("challengeID")};
            challengeDiff(0);
        }, function(){});
    }
    return [timeClock, timeLeft, icon, info, playSong, playIcon];
}

function changeData(id:Int, ?arry) {
    if (id == null) id = 0;
    save.data.challengesData.get(editingMod).data[id].vars = parseChallengeDataIntoArray(id, arry);
    save.data.challengesData.get(editingMod).data[id].date = Date.now().getTime();
    save.flush();
    makeNewChallengeCards(id);
}
/**
    [saveAPI]
    The Layout of `save.data.challengesData`.get(editingMod);
    {
        data: [ // challengeItemID (0, 1, 2 or smth)
            date: Date.now().getTime() // ran when mod is set to the future time
            vars: {
                daText: String,
                daData: {
                    songID: Int,
                    icon: String,
                    challengeItemID: Int, // might be deprecated soon
                    challengeID: Int,
                    hasCompletedChallenge: Bool,
                }
            }
        ],
        version: challengesVersion
    }
**/
var currentTokenVersion:String = "1.0.0";
var currentXPversion:String = "1.0.0";
function makeSaveData() {
    // save.data.challengesData = null;
    // save.data.challengesData.remove(editingMod);

    /**
        use this when re-doing UI and adding XP / Levels

        +: 50xp,
        -: 25xp,
        
        S Rank: 150xp,
        A Rank: 100xp,
        B Rank: 75xp,
        C Rank: 50xp,
        E Rank: 25xp,
        F Rank: 15xp
    **/
    var levelsUp = [
        "1" => 250,
        "2" => 250,
        "3" => 250,
        "4" => 250,
        "5" => 450,
        "6" => 450,
        "7" => 450,
        "8" => 450,
        "9" => 450,
        "10" => 1000,
        "11" => 1000,
        "12" => 1000,
        "13" => 1000,
        "14" => 1000,
        "15" => 1250,
    ];
    var cap:Int = 0;
    for (i in levelsUp.keys()) {
        cap++;
    }
    if (save.data.levelSystem == null) {
        save.data.levelSystem = {
            tokenData: {
                tokens: 0,
                version: currentTokenVersion,
            },
            xpData: {
                level: 1,
                xp: 0,
                xpToLevelUp: 250,
                capLevel: cap,
                version: currentXPversion,
                xpLevels: levelsUp,
            }
        };
        save.flush();
    }
    if (save.data.levelSystem.tokenData.version != currentTokenVersion) {
        switch(currentTokenVersion) {
            default:
                save.data.levelSystem.tokenData = {
                    tokens: 0,
                    version: currentTokenVersion,
                }
        }
        save.flush();
    }
    if (save.data.levelSystem.xpData.version != currentXPversion) {
        switch(currentXPversion) {
            default:
                save.data.levelSystem.xpData = {
                    level: 1,
                    xp: 0,
                    xpToLevelUp: 250,
                    capLevel: cap,
                    version: currentXPversion,
                    xpLevels: levelsUp,
                }
        }
        save.flush();
    }
    if (save.data.levelSystem.xpData.xp >= save.data.levelSystem.xpData.xpToLevelUp) {
        if (save.data.levelSystem.xpData.level < save.data.levelSystem.xpData.capLevel) {
            save.data.levelSystem.xpData.level++;
            save.data.levelSystem.xpData.xp -= save.data.levelSystem.xpData.xpToLevelUp;
            save.data.levelSystem.xpData.xpToLevelUp = save.data.levelSystem.xpData.xpLevels.get(save.data.levelSystem.xpData.level);
        }
    }

    if (save.data.challengesData == null
        || !save.data.challengesData.exists(editingMod)
        || save.data.challengesData.get(editingMod).version.toLowerCase() != challengesVersion.toLowerCase()) {
        var dateNow = Date.now().getTime();
        var challengeData = parseChallengeDataIntoArray();
        var arry = [];
        for (item in challengeData) if (item != null) arry.push({date: dateNow, vars: item});

        if (save.data.challengesData == null) save.data.challengesData = [editingMod => {version: challengesVersion, data: arry}];
        else save.data.challengesData.set(editingMod, {version: challengesVersion, data: arry});

        save.flush();
    }
}

function parseChallengeDataIntoArray(?id, ?skipItemsInRandom) {
    var amount = (_freeplaySongs.length > 3) ? 3 : _freeplaySongs.length;
    var songArray = doSong(amount, skipItemsInRandom);
    var dataArray = doData(songArray);
    if (id != null) return dataArray[id];
    else return dataArray;
}

function doSong(amontOfChallenges:Int, ?skipItemsRandom:Array<Int>) {
    var songNames:Array<String> = [];
    var alrPicked:Array<Int> = [];
    var songCharacters:Array<String> = [];

    var removedPickedFromRandom:Array<Int> = [];
    if (skipItemsRandom != null) removedPickedFromRandom.copy(skipItemsRandom);
    for (i in 0...amontOfChallenges) {
        var random = FlxG.random.int(0, _freeplaySongs.length-1, removedPickedFromRandom);
        removedPickedFromRandom.push(random); alrPicked.push(random);

        var freeplaySongThing = _freeplaySongs[random];
        var songName = freeplaySongThing.songName;
        if (freeplaySongThing.displayName != null) songName = freeplaySongThing.displayName;
        songNames.push(songName);
        songCharacters.push(freeplaySongThing.songCharacter);
    }
    return [songNames, songCharacters, alrPicked];
}

function doData(songArray) {
    var returnedData:Array<Dynamic> = [];
    for (i in 0...songArray[0].length) {
        var otherValues:Map = [
            "[s]" => "song"
        ];
        var text:String = "";

        var challengesToDo = challengesData.get("challengesToDo");
        var songSpecificChallenges = challengesData.get("songSpecificChallenges");

        var addSpecThing:Bool = false;

        var check:Int = 0;
        var theTimeOnChall = 2;
        var isSongSpecific = FlxG.random.bool(randomPercentDiff);
        if (!disableGloablChallenges || (disableGloablChallenges && songSpecificChallenges == null)) {
            for (i in challengesToDo.keys()) check++;
            challengeRandom = FlxG.random.int(0, check-1);
            text = challengesToDo.get(challengeRandom)[0];
            theTimeOnChall = challengesToDo.get(challengeRandom)[1];

            check = 0;
            if (songSpecificChallenges != null) {
                if (songSpecificChallenges.exists(songArray[2][i]) && isSongSpecific) {
                    addSpecThing = true;
                    for (i in songSpecificChallenges.get(songSpecificChallenges).keys()) check++;
                    challengeRandom = FlxG.random.int(0, check-1);
                    text = songSpecificChallenges.get(songArray[2][i]).get(challengeRandom)[0];
                    theTimeOnChall = songSpecificChallenges.get(songArray[2][i]).get(challengeRandom)[1];
                }
            }
        } else {
            if (songSpecificChallenges.exists(songArray[2][i])) {
                addSpecThing = true;
                for (i in songSpecificChallenges.keys()) check++;
                challengeRandom = FlxG.random.int(0, check-1);
                text = songSpecificChallenges.get(songArray[2][i]).get(challengeRandom)[0];
                theTimeOnChall = songSpecificChallenges.get(songArray[2][i]).get(challengeRandom)[1];
            } else {
                logging.LogsOverlay.error("you don't have any challenge data (somehow, what the fuck???)");
                challengeRandom = 0;
                text = "ERROR: no challenge data... wait whar";
            }
        }
        if (theTimeOnChall == null) theTimeOnChall = 2;
        otherValues.set("isSongSpecific", isSongSpecific);
        otherValues.set("timeOnChallenge", theTimeOnChall);
        otherValues.set("hasCompletedChallenge", false);
        /**
            the ID for the Challenge.
            for `songSpecificChallenges` use `[songID, challengeID]` when setting the completed items LJ...
        **/
        otherValues.set("challengeID", challengeRandom);

        /**
            The `ID` of the challenge, currently max is 3. So if you have >= 3 songs, the challenge ID can be `0, 1, 2`.
            used for the challenges BG sprites in `ModEditing.hx`.
        **/
        otherValues.set("challengeItemID", i); // might remove / Deprecate
        check = 0;
        for (item in containables) {
            if (!StringTools.contains(text, item)) {
                continue;
            }
            var replace:String = "";
            var constRandom:Int = -1;
            if (ChallengesDataScript != null) {
                var returnedCustom = ChallengesDataScript.executeFunc("setSongDataValues", [replace, constRandom,
                    item, i, songArray[0]]);
                replace = returnedCustom[0];
                constRandom = returnedCustom[1];
            } else {
                switch(item) {
                    case "[s]":
                        replace = songArray[i];
                    case "[att]":
                        var attributes = challengesData.get("attributes");
                        var length:Int = 0;
                        for (i in attributes.keys()) length++;
                        if (length <= 0) continue;
                        constRandom = FlxG.random.int(0, length-1);
                        replace = attributes.get(constRandom)[0];
                    case "[tokens]":
                        var tokenMult = challengesData.get("tokenMult");
                        var length:Int = 0;
                        for (i in tokenMult.keys()) length++;
                        if (length <= 0) continue;
                        constRandom = FlxG.random.int(0, length-1);
                        replace = tokenMult.get(constRandom)[0];
                }
            }
            /**
                This is the `ID` of the replaced item.
                ex: { attributes => [0 => ["die lol"]] } 0 would be constRandom.
                if -1, then you didn't set it, thats ok tho.
            **/
            otherValues.set(item, constRandom);
            text = StringTools.replace(text, item, replace);
        }
        otherValues.set("icon", songArray[1][i]);
        /**
            This is the `ID` of your freeplaySonglist.json.
            Since `freeplaySonglist.json`.song is an array, its based on that.
            Base game terms; 0 would be `Tutorial`, (and for `Week 7 Update`) `.length` would be `Stress`.
        **/
        otherValues.set("songID", songArray[2][i]);
        returnedData.push({daText: text, daData: otherValues});
    }
    return returnedData;
}

function existsInMods(targeted:String, default:String, ?sparrow:Bool = false) {
	if (!Assets.exists(default) && !sparrow) return trace("This default doesn't exist! : " + default);
    if (sparrow) {
        if (!Assets.exists(Paths.image(default))) return trace("This default doesn't exist!");
        else default = Paths.getSparrowAtlas(default);
    }
	targeted = Paths.getLibraryPathForce(targeted, "mods/" + editingMod);
	return (Assets.exists(targeted)) ? targeted : default;
}

/**
	basically convert the int into R G B from 0 - 1 values
	bitshift, divide by 100 and return an array

	Yce is dumb and makes Blue = Green, and Green = Blue, instead of RGB, its RBG?? sure yoshi.
	Need some help getting to the insane asylum? I can help.
**/
function colorToShaderVec(color:Int, ?rgbUh:Bool = false) {
    if (color == null) return;
	if (rgbUh == null) rgbUh = false;
	var r = (color >> 16) & 0xff;
	var g = (color >> 8) & 0xff;
	var b = (color & 0xff);
	return (rgbUh) ? {r: r, g: g, b: b, a: (color >> 24) & 0xff} : [(r)/100, (g)/100, (b)/100];
}
/*
	Hex - (FF, A1)S
	AA - Alpha Channel in Hex
	RR - Red Channel in Hex
	GG - Green Channel in Hex
	BB - Blue Channel in Hex
	0x - beginning of Hex data.
*/
/**
	@param shader The CustomShader variable
	@param colors 
	{ 
		fill: 0xAARRGGBB,
		outline: 0xAARRGGBB,
		gradientData: {
			gradient: Bool,
			coloredGradient: Bool,

			fillCap: {
				min: Float, max: Float
			},
			outlineCap: {
				misn: Float, max: Float
			},

			fillGrad: 0xAARRGGBB,
			outlineGrad: 0xAARRGGBB
		},
	}
**/
function setOmogusShador(shader:CustomShader, colors:Dynamic) {
	if (shader == null) return;

	shader.data.fillColor.value = colorToShaderVec(colors.fill);
	shader.data.outlineColor.value = colorToShaderVec(colors.outline);
	shader.data.enableGradient.value = [0, 0];
    
	
	if (colors.gradientData != null && colors.gradientData.gradient) {
		if (colors.gradientData.fillCap != null) shader.data.fillGradientCap.value = [colors.gradientData.fillCap.min, colors.gradientData.fillCap.max];
		if (colors.gradientData.outlineCap != null) shader.data.outlineGradientCap.value = [colors.gradientData.outlineCap.min, colors.gradientData.outlineCap.max];

		shader.data.enableGradient.value[0] = 1;
		if (colors.gradientData.coloredGradient) {
			shader.data.fillGradientColor.value = colorToShaderVec(colors.gradientData.fillGrad);
			shader.data.outlineGradientColor.value = colorToShaderVec(colors.gradientData.outlineGrad);
			
			shader.data.enableGradient.value[1] = 1;
		}
	}
}

var shopAssets:FlxTypedSpriteGroup;
var shopSectons:Int = -1;
var selShopSpr:FlxUI9SliceSprite;
function makeShopItems() {
    curSelectedType = "menu";
    curSel = 1;
    selection();

    shopAssets = new FlxTypedSpriteGroup();
    add(shopAssets);
    
    selShopSpr = new FlxUI9SliceSprite(0,0, Paths.image("SquareOutline"),
    new Rectangle(0, 0, 500, 500), [20, 20, 460, 460]);
    selShopSpr.alpha -= 0.2;
    selShopSpr.screenCenter();
    selShopSpr.visible = false;
    add(selShopSpr);
    
    addNewItems({type: 0, style: 1, tabName:"Test Tab"});
    addNewItems({type: 0, style: 2});
}
/**
    @param type [0, 1] 0 - Big Square | 1 - Small Square
    @param data
    {
        tab: [
            {
                tabName: String,
                items: [
                    isSparrow: Bool,
                    cost: Int
                ],
                style: Int,
            },
        ],
        script: String,
    }
**/
/*
    styles:
    0 - 1 Big, 4 Small
    1 - 3 Big
    2 - 8 Small
    3 - 2 Big, 4 Small
*/
var shopMaxY:Float = 0;
function addNewItems(data:Dynamic) {
    shopSectons++;
    var itemShop = new FlxTypedSpriteGroup();
    insert(members.indexOf(shopAssets)-1, itemShop);

    var size = {
        big: new FlxPoint(335, 550),
        small: new FlxPoint(275, 275)
    };

    var itms = [];
    switch(data.style) {
        case 0:
            for (i in 0...5) {
                var sze = (i == 0) ? new FlxPoint(450, 550) : size.small;
                var bgItem = new FlxUI9SliceSprite(0,0, Paths.image("SquareShit"),
                new Rectangle(0, 0, sze.x, sze.y), [20, 20, 460, 460]);
                switch(i) {
                    case 1: bgItem.x += itms[0].width;
                    case 2: bgItem.x += itms[0].width*2 - 175;
                    case 3:
                        bgItem.x += itms[0].width;
                        bgItem.y += bgItem.height;
                    case 4:
                        bgItem.x += itms[0].width*2 - 175;
                        bgItem.y += bgItem.height;
                }
                bgItem.x += 60;
                bgItem.alpha = 0.4;
                bgItem.color = 0xFF000000;
                itms.push(bgItem);
            }
        case 1:
            for (i in 0...3) {
                var bgItem = new FlxUI9SliceSprite(0,0, Paths.image("SquareShit"),
                new Rectangle(0, 0, size.big.x, size.big.y), [20, 20, 460, 460]);
                bgItem.x = bgItem.width*i;
                bgItem.alpha = 0.4;
                bgItem.color = 0xFF000000;
                bgItem.x += 60;
                itms.push(bgItem);
            }
        case 2:
            for (i in 0...6) {
                var sze = size.small;
                var bgItem = new FlxUI9SliceSprite(0,0, Paths.image("SquareShit"),
                new Rectangle(0, 0, sze.x, sze.y), [20, 20, 460, 460]);
                bgItem.x = bgItem.width*(i % 3);
                if (i > 2) bgItem.y += bgItem.height;
                bgItem.alpha = 0.4;
                bgItem.color = 0xFF000000;
                bgItem.x += 60;
                itms.push(bgItem);
            }
    }
    for (item in itms) {
        itemShop.add(item);
        FlxMouseEventManager.add(item, function(){}, function(){
            trace("CLICKED");
        }, function(){
            selShopItem(item);
        }, function() {
            targetSprShop = null;
        }, true, true, false);
        
        var sellable = new FlxSprite();
        sellable.frames = Paths.getSparrowAtlas("shop/placeHolder");
        sellable.animation.addByPrefix("idle", "funnyThing instance 1", 12, true);
        sellable.animation.play("idle");
        var maxSize = 300;
        sellable.setGraphicSize(item.frameWidth - 50, (item.frameHeight > maxSize) ? maxSize : item.frameHeight);
        sellable.scale.set(Math.min(sellable.scale.x, sellable.scale.y), Math.min(sellable.scale.x, sellable.scale.y)); // Thanks math :dies of horrable math death:
        sellable.setPosition(item.x + item.width/2 - sellable.width/2, item.y + item.height/2 - sellable.height/2);
        itemShop.add(sellable);

        var token = new FlxSprite(0,0, Paths.image("ljtoken"));
        token.setGraphicSize(50, 50);
        token.scale.set(Math.min(token.scale.x, token.scale.y), Math.min(token.scale.x, token.scale.y)); // Thanks math :dies of horrable math death:
        token.updateHitbox();
        token.setPosition(item.x + item.width - token.width - 5, item.y + item.height- token.height - 5);
        itemShop.add(token);

        var cost = new FlxText(0, 0, 0, "100", 20);
        cost.font = Paths.font("Funkin - No Outline.ttf");
        cost.updateHitbox();
        cost.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2);
        cost.setPosition(token.x - cost.width - 5, token.y + token.height/2 - cost.height/2);
        itemShop.add(cost);
    }
    
    if (data.tabName == null || Std.string(data.tabName) == "") data.tabName = "Unammed Tab";
	var tab = new FlxText(0, 0, 0, Std.string(data.tabName), Math.min(48, (FlxG.width - 5) / (1 * Std.string(data.tabName).length)));
	tab.font = Paths.font("Funkin - No Outline.ttf");
	tab.scrollFactor.set();
	tab.updateHitbox();
    tab.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2);
    tab.setPosition(tab.x + 70, -tab.height);
    itemShop.add(tab);
    
    itemShop.screenCenter();
    itemShop.x += 75;
    itemShop.y += 70;

    shopAssets.add(itemShop);
    itemShop.y += (shopAssets.members[shopSectons].height + 50)*shopSectons;
}

var targetSprShop = null;
function selShopItem(item) {
    selShopSpr.visible = true;
    selShopSpr.resize(item.frameWidth, item.frameHeight);
    selShopSpr.setPosition(item.x, item.y);
    targetSprShop = item;
}

function doShop() {
    curSelectedType = "shop";
    currentColor = 0xFF22BE0D;
}