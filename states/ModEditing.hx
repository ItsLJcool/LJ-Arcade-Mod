// a
import MainMenuState;
import sys.FileSystem;
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

// use CoolUtil.getMostPresentColor(icon.pixels); for new UI
var challengesVersion:String = "2.1.0";

function new(modYay:String, ?_modChallengeJust:Dyanimc) {
    if (_modChallengeJust != null) modChallengeJust = _modChallengeJust;

	if (modYay != null) editingMod = modYay;
    
	var p = Paths.json('freeplaySonglist', 'mods/'+modYay);
	if (Assets.exists(p)) {
        jsonContent = Json.parse(Assets.getText(p));
		if (jsonContent.songs != null)
			for (song in jsonContent.songs) freeplaySongs.push(SongMetadata.fromFreeplaySong(song, modYay));
	}
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

var menuItemsType = {
	menus: [{
			name: "freeplay",
			sprite: "FNF_main_menu_assets",
		}, {
			name: "mods",
			sprite: "FNF_main_menu_assets",
		}, {
			name: "options",
			sprite: "FNF_main_menu_assets",
		}, {
			name: "medals",
			sprite: "FNF_main_menu_assets",
		},
	]
}

var bg:FlxSprite;
var bgScale:Float = 1;

var ljTokenImage:FlxSprite;
var tokenText:FlxText;
var tokenBG:FlxUI9SliceSprite;
var bgRect:FlxRect;

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

	if (FlxG.sound.music == null || !FlxG.sound.music.playing)
        FlxG.sound.playMusic(existsInMods("music/freakyMenu.ogg", Paths.music("freakyMenu")));

	bg = new FlxSprite(0, 0, existsInMods("images/menuDesat.png", Paths.image("menuDesat")));
	bg.setGraphicSize(FlxG.width, FlxG.height);
    bgScale = bg.scale.x;
	bg.screenCenter();
    bg.alpha -= 0.15;
	add(bg);
    
	tokenData = new FlxTypedGroup();
	add(tokenData);

    ljTokenImage = new FlxSprite(0,0, Paths.image("ljtoken"));
    ljTokenImage.setGraphicSize(100, 100);
    ljTokenImage.scale.set(Math.min(ljTokenImage.scale.x, ljTokenImage.scale.y), Math.min(ljTokenImage.scale.x, ljTokenImage.scale.y)); // Thanks math :dies of horrable math death:
    ljTokenImage.setPosition(FlxG.width - ljTokenImage.width + 15, FlxG.height - ljTokenImage.height + 15);
    ljTokenImage.antialiasing = !EngineSettings.antialiasing;
    // ljTokenImage.alpha = 0.5;

    tokenText = new FlxText(0,0,0, "placeholder", 20);
    tokenText.alignment = "right";
    tokenText.text = "LJ Tokens: " + save.data.ljTokens;
    tokenText.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2);
    tokenText.setPosition(ljTokenImage.x - tokenText.width + 20, ljTokenImage.y + ljTokenImage.height/2 - tokenText.height/2);
    tokenText.alpha = 0.0001;

    tokenBG = new FlxUI9SliceSprite(0,0, (Paths.image('SquareShit')),
    new Rectangle(0, 0, tokenText.width + ljTokenImage.width/2 + 20, ljTokenImage.height/2 - 5), [20, 20, 460, 460]);
    tokenBG.color = 0xFF000000;
    tokenBG.setPosition(tokenText.x + tokenText.width + ljTokenImage.width/2 - ljTokenImage.width/5, ljTokenImage.y + ljTokenImage.height/2 - tokenBG.height/2);
    tokenBG.alpha = 0.4;
    add(tokenBG);
    add(tokenText);
    add(ljTokenImage);
	bgRect = new FlxRect(0, 0, 0, tokenBG.frameHeight);
    tokenBG.clipRect = bgRect;

    var time:Float = 0.25;
    var ease:FlxEase = FlxEase.quadInOut;
    FlxMouseEventManager.add(ljTokenImage, function(){}, function(){}, function(){
        for (item in ljTokenTweens) if (item != null) item.cancel();
        ljTokenTweens[0] = FlxTween.tween(bgRect, {width: tokenBG.frameWidth}, time, {ease: ease, onUpdate: function() {
            tokenBG.clipRect = bgRect;
        }});
        ljTokenTweens[1] = FlxTween.tween(tokenBG, {x: tokenText.x + tokenText.width/2 - tokenBG.width/2}, time, {ease: ease});
        ljTokenTweens[2] = FlxTween.tween(tokenText, {alpha: 1}, time, {startDelay: time, ease: ease});
    }, function(){
        for (item in ljTokenTweens) if (item != null) item.cancel();
        ljTokenTweens[0] = FlxTween.tween(bgRect, {width: 0}, time, {startDelay: time, ease: ease, onUpdate: function() {
            tokenBG.clipRect = bgRect;
        }});
        ljTokenTweens[1] = FlxTween.tween(tokenBG, {x: tokenText.x + tokenText.width + ljTokenImage.width/2 - ljTokenImage.width/5}, time, {startDelay: time, ease: ease});
        ljTokenTweens[2] = FlxTween.tween(tokenText, {alpha: 0.0001}, time, {ease: ease});
    });

	menuStuff = new FlxTypedGroup();
	add(menuStuff);

    if (menuItemsType.menus[0].name == "freeplay" && jsonContent == null) menuItemsType.menus.remove(menuItemsType.menus[0]);
    if (menuItemsType.menus[2].name == "medals" && jsonContent == null) menuItemsType.menus.remove(menuItemsType.menus[2]);

	for (i in 0...menuItemsType.menus.length) {
        var item = menuItemsType.menus[i];
		var spr:FlxSprite = new FlxSprite();
		spr.frames = existsInMods(item.sprite + ".png", item.sprite, true);
        spr.scale.set(0.65, 0.65);
        spr.updateHitbox();
        spr.animation.addByPrefix("normal", item.name + " basic", 24, true);
        spr.animation.addByPrefix("selected", item.name + " white", 24, true);
        spr.animation.play("normal", true);
        spr.ID = i;
        spr.x += 50;
        spr.y = (FlxG.height / menuItemsType.menus.length * i) + (FlxG.height / (menuItemsType.menus.length * 2)) - 50;
		menuStuff.add(spr);
	}
    changeSelMenu(0);
    if (jsonContent != null) {
        makeFreeplayData();
        makeSaveData();
        makeNewChallengeCards(-1, true);
    }

    if (modChallengeJust.hasCompleted) {
        if (save.data.challengesData.get(editingMod).data[modChallengeJust.dataID.itemID].vars.daData.get("hasCompletedChallenge"))
            hasCompletedChallenge();
    }
    Conductor.changeBPM(configMod.intro.bpm); // L Config File
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
            curSelectedType = "medals";
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
    curSel = CoolUtil.wrapInt(curSel + hur, 0, menuStuff.length);
    menuStuff.forEach(function(item) {
        item.animation.play(((item.ID == curSel) ? "selected" : "normal"), true);
    });
}
function menuSel() {
    curSelectedType = "";
    FlxG.sound.play(existsInMods("sounds/confirmMenu.ogg", Paths.sound("confirmMenu")));

    menuStuff.forEach(function(item) {
        FlxTween.tween(item, {x: 0 - item.width - 90}, 0.5, {startDelay: 0.75, ease: FlxEase.quadIn, onComplete: function() {
            if (item.ID != curSel) return;
            switch(menuItemsType.menus[item.ID].name.toLowerCase()) {
                case "freeplay": freeplayInit(menuItemsType.menus[item.ID].name.toLowerCase());
                case "medals": challengesEnter(menuItemsType.menus[item.ID].name.toLowerCase());
                default: curSelectedType = menuItemsType.menus[item.ID].name.toLowerCase();
            }
        }});
        if (item.ID == curSel) {
            FlxTween.tween(item, {y: (FlxG.height / 2) - item.height / 2}, 0.5, {ease: FlxEase.quadInOut});
            return;
        }
        FlxTween.tween(item, {alpha: 0.0001, x: -(FlxG.height / 2)}, 0.5, {ease: FlxEase.quadOut});
    });
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

var curSelectedType:String = "menu";
var updateTimeChallenges:Float = 0;
function update(elapsed:Float) {
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
        }
    }
    if (FlxControls.anyJustPressed([39, 68])) {
        switch(curSelectedType.toLowerCase()) {
            case "freeplay": freeplayDiff(1);
            case "challenge_diff": challengeDiff(1);
        }
    }
    
    if (FlxControls.anyJustPressed([38, 87])) {
        switch(curSelectedType.toLowerCase()) {
            case "menu": changeSelMenu(-1);
            case "freeplay": freeplaySel(-1);
            default: return;
        }
        if (curSelectedType.toLowerCase() != "") FlxG.sound.play(existsInMods("sounds/scrollMenu.ogg", Paths.sound("scrollMenu")));
    }
    if (FlxControls.anyJustPressed([40, 83])) {
        switch(curSelectedType.toLowerCase()) {
            case "menu": changeSelMenu(1);
            case "freeplay": freeplaySel(1);
            default: return;
        }
        if (curSelectedType.toLowerCase() != "") FlxG.sound.play(existsInMods("sounds/scrollMenu.ogg", Paths.sound("scrollMenu")));
    }
    if (FlxControls.anyJustPressed([13])) {
        switch(curSelectedType.toLowerCase()) {
            case "menu": menuSel();
            case "freeplay": if (grpSongs.members != null || grpSongs.members.length != 0) freeplayEnter(grpSongs.members[curFreeplaySel].text);
            case "challenge_diff": enterChallengeSong(challengeID.songID);
        }
    }
    if (FlxControls.anyJustPressed([8, 27])) {
        if (curSelectedType.toLowerCase() == "") return;
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
            case "medals":
                canSelectChallenge = false;
                time = 1.26 + (0.5/(challengesBGstuff.length)) * 0.3;
                for (item in challengesBGstuff) {
                    FlxTween.tween(item, {y: FlxG.height + (item.height + 10)*(item.ID+1)}, 1.25, {startDelay: (0.5/(item.ID+1)) * 0.3, ease:FlxEase.backIn});
                }
            case "challenge_diff":
                goBackToMenu = false;
                curSelectedType = "medals";
                diffStuff.forEach(function(item) {
                    item.visible = false;
                });
                canSelectChallenge = true;
            default:
                if (curSelectedType.toLowerCase() != "")
                trace("item isn't here yet: " + curSelectedType.toLowerCase());
        }
        if (!goBackToMenu) return;
        curSelectedType = "";
        new FlxTimer().start(time, function(tmr) {
            menuStuff.forEach(function(item) {
                item.y = (FlxG.height / menuItemsType.menus.length * item.ID) + (FlxG.height / (menuItemsType.menus.length * 2)) - 50;
                item.animation.play("normal", true);
                item.alpha = 1;
                FlxTween.tween(item, {x: 50},
                0.75, {ease: FlxEase.circOut, onComplete: function() {
                    if (item.ID == curSel) item.animation.play("selected", true);
                    curSelectedType = "menu";
                    completeFunc();
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
function makeSaveData() {
    // save.data.challengesData = null;
    // save.data.challengesData.remove(editingMod);

    /**
        use this when re-doing UI and adding XP / Levels
    **/
    if (save.data.xpData == null) {
        save.data.xpData = {
            level: 0,
            xp: 0,
            capLevel: 50,
            xpToLevelUp: 500,
        };
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