//a
import StringTools;
import Conductor;
import PauseSubState;
// import PlayState;
/**
    [s] - Song Name
    [att] - Attribute (ex: 2x Speed)
    [tokens] - Multiplier for Tokens

    You can add custom containables, add functionality in `setSongDataValues` function
**/
var containables:Array<Dynamic> = [
    "[s]", "[att]", "[tokens]", "[miss]", "[dead]"
];

/** 
    Disables `challengesToDo` and only accepts `songSpecificChallenges` compared to both being enabled.
    if enabled but it doesn't contain items it will disable.
**/
var disableGloablChallenges:Bool = false;
var randomPercentDiff:Float = 50.0; // higher = more chance for Specific | Lower = more Global

/**
    Challenges that every song can complete. If you want a specific song to have a challenge, use `songSpecificChallenges`
    `[Challenge Text, time]` - `time`; refrence `timesInFuture` in ModEditing, 0 - 1m; 1 - 1 hour;  2 - 1 day (default)
**/
var challengesData:Map = [
    "challengesToDo" => [
        0 => ["Beat [s]"],
        1 => ["FC [s] for [tokens]"],
        2 => ["Reach the half way point in [s]"],
        3 => ["Beat [s] with [att]"],
        4 => ["Beat [s] in less than [miss]"],
        5 => ["Beat [s] within [dead]"],
        6 => ["Beat [s] without Missing and Dying once", 0], // hard challenge to do lol
        7 => ["Beat [s] without Missing and Dying once, and [att]", 1],
        8 => ["Beat [s] with notes fading INTO judgement line"],
        9 => ["Beat [s] with notes fading OUT OF judgement line"],
        10 => ["Beat [s] with Mines in your way"],
    ],
    // make this into a map to enable it automatically, if null, then doesn't check
    // use songID, so from 0 to (freeplaySonglist.json.length-1). ex: { "bopbebo", "fresh" } (songs), this would be 0 to (2)-1.
    "songSpecificChallenges" => null

    // the challengesToDo and songSpecificChallenges are needed to exist for this to work, since they
    // need at least either a null or a Map to function.
    // Technically you don't need anything else, but it gives it more variety to add more things to do.
    
    // idk why i need [], might remove them unless i find a good use for an array here
    "attributes" => [
        0 => ["1.25x Speed"],
        1 => ["1.5x Speed"],
        2 => ["1.75x Speed"],
    ],
    "tokenMult" => [
        0 => ["1.25x Token Multiplier"],
        1 => ["1.5x Token Multiplier"],
    ],
    "misses" => [
        0 => ["5 Misses"],
        1 => ["10 Misses"],
        2 => ["15 Misses"],
        3 => ["20 Misses"],
    ],
    "death" => [
        0 => ["1 death"],
        1 => ["2 deaths"],
        2 => ["3 deaths"],
        3 => ["4 deaths"],
        4 => ["5 deaths"],
        5 => ["10 deaths"],
    ]
];
function modEditingCreate() { }

function musicstart() {
    trace(saveChallengesData.data[challengeID.itemID].vars.daData);
    if (saveChallengesData.data[challengeID.itemID].vars.daData.exists("[att]")) {
        onResyncVocalsPost();
        for (item in [PlayState.playerStrums.members, PlayState.cpuStrums.members]) {
            for (strum in item) {
                strum.scrollSpeed = strum.getScrollSpeed();
                strum.scrollSpeed /= PlayState.inst.pitch;
            }
        }
    }
}

var mineNoteType:Int = -1;
var isPixelNote:Bool = false;
function createPost() {
    if (PlayState.noteScripts[0].metadata.noteType.split(":")[1] != null)
        isPixelNote = (PlayState.noteScripts[0].metadata.noteType.split(":")[1].toLowerCase() == "pixel note");
    if (challengeID.challengeID == 10) {
        var invalid = [];
        for (note in PlayState.unspawnNotes) {
            if (!note.mustPress || note.isSustainNote) continue;
            invalid.push(note);
        }
        for (i in 0...invalid.length) {
            if (FlxG.random.bool(FlxG.random.int(20, 70))) continue;

            var time = FlxG.random.int(invalid[i].strumTime - 200, invalid[i].strumTime + 200, [invalid[i].strumTime]);
            var randomKey = FlxG.random.int(0, PlayState.SONG.keyNumber-1);
            var doCont = false;
            for (note in invalid) {
                if ((note.strumTime > time - 100 && note.strumTime < time + 100) && note.noteData == randomKey) {
                    doCont = true;
                    break;
                }
            }
            if (doCont) continue;

            var mineNote = PlayState.addNoteType(loadedMod + ":mineNote");
            var newNote = new Note(time, randomKey + (PlayState.SONG.keyNumber * 2) * mineNote,
            null, false, true);
            mineNoteType = newNote.noteType;
            newNote.script.setVariable("onMiss", function(mineNoteType) {
                return false;
            });
            PlayState.unspawnNotes.push(newNote);
        }
        PlayState.unspawnNotes.sort(PlayState.sortByShit);
    }
}

var halfWay:Bool = false;
function update(elapsed:Float) {
    if (Math.ffloor(PlayState.songPercentPos >= 0.5) && !halfWay) {
        halfWay = true;
        challengeComplete({challengeID: 2});
    }
}

function onNoteUpdatePost(note) {
    var alphaSus = (note.isSustainNote) ? 0.6 : 1;
    if (challengeID.challengeID == 8) {
        if ((note.strumTime - 200) - Conductor.songPosition <= 200) {
            note.__renderAlpha = (1 - ((note.strumTime - 200) - Conductor.songPosition) / 200) * alphaSus;
        }
        else note.__renderAlpha = 0;
    } else if (challengeID.challengeID == 9) {
        if ((note.strumTime - 150) - Conductor.songPosition <= 200)
            note.__renderAlpha = (((note.strumTime - 150) - Conductor.songPosition) / 200) * alphaSus;
    }
    if (challengeID.challengeID == 10) {
        if (note.noteType == mineNoteType) note.__noteScale = (!isPixelNote) ? 0.8 : 6;
    }
}

function onResyncVocalsPost() {
    if (saveChallengesData.data[challengeID.itemID].vars.daData.exists("[att]")) {
        var saveDaData = saveChallengesData.data[challengeID.itemID].vars.daData;
        var speedTimes = Std.parseFloat(challengesData.get("attributes")[saveDaData.get("[att]")][0].toLowerCase().split("x")[0]);
        if (PlayState.inst != null && PlayState.inst._channel != null)
            if (speedTimes != PlayState.inst._channel.pitch) PlayState.inst.pitch = speedTimes;
        if (PlayState.vocals != null && PlayState.vocals._channel != null)
            if (speedTimes != PlayState.vocals._channel.pitch) PlayState.vocals.pitch = speedTimes;
    }
}
var focusingIn:Bool = false;
function preUpdate(elapsed:Float) {
    if (focusingIn) {
        focusingIn = false;
        if (saveChallengesData.data[challengeID.itemID].vars.daData.exists("[att]") && Conductor.songPosition >= 0) onResyncVocalsPost();
    }
}
function onFocus() {
    focusingIn = true;
}

function onPreEndSong() {
    var saveDaData = saveChallengesData.data[challengeID.itemID].vars.daData;
    focusingIn = true;
    /**
        Good pratice to make sure if it even exists before trying to grab the data.
        It could cause errors or even crashes if your not carefull.
    **/
    if (saveDaData.exists("[tokens]")) {
        if (PlayState.misses == 0) {
            tokenMultiplier = switch(saveDaData.get("[tokens]")) {
                case 0: 1.25;
                case 1: 1.5;
                default: 1;
            }
            challengeComplete({challengeID: 1});
        }
    }
    if (saveDaData.exists("[miss]")) {
        if (PlayState.misses <= Std.int(challengesData.get("misses")[saveDaData.get("[miss]")][0].toLowerCase().split(" ")[0]))
            challengeComplete({challengeID: 4});
    }
    if (saveDaData.exists("[dead]")) {
        if (PlayState.blueballAmount < Std.int(challengesData.get("death")[saveChallengesData.data[challengeID.itemID].vars.daData.get("[dead]")][0].toLowerCase().split(" ")[0]))
            challengeComplete({challengeID: 5});
    }
    // the hard challenge lol
    if (PlayState.misses == 0 && PlayState.blueballAmount == 0) {
        challengeComplete({challengeID: 6});
        // attribute is handled differently so I don't need to even code an if statement here. I love coding
        challengeComplete({challengeID: 7});
    }
    challengeComplete({challengeID: 0});
    challengeComplete({challengeID: 3});
    challengeComplete({challengeID: 8});
    challengeComplete({challengeID: 9});
    challengeComplete({challengeID: 10});
}


// This is for the ModEditing.hx State :)
function setSongDataValues(replace, constRandom,
    item, i, songArray) {
    var length:Int = 0;
    switch(item) {
        case "[s]":
            replace = songArray[i];
        case "[att]":
            var localData = challengesData.get("attributes");
            for (i in localData.keys()) length++;
            if (length <= 0) continue;
            constRandom = FlxG.random.int(0, length-1);
            replace = localData.get(constRandom)[0];
        case "[tokens]":
            var localData = challengesData.get("tokenMult");
            for (i in localData.keys()) length++;
            if (length <= 0) continue;
            constRandom = FlxG.random.int(0, length-1);
            replace = localData.get(constRandom)[0];
        case "[miss]":
            var localData = challengesData.get("misses");
            for (i in localData.keys()) length++;
            if (length <= 0) continue;
            constRandom = FlxG.random.int(0, length-1);
            replace = localData.get(constRandom)[0];
        case "[dead]":
            var localData = challengesData.get("death");
            for (i in localData.keys()) length++;
            if (length <= 0) continue;
            constRandom = FlxG.random.int(0, length-1);
            replace = localData.get(constRandom)[0];
        default:
            trace("Item isn't added in the switch case.");
            replace = "[error, item not set]";
            constRandom = 0;
    }
    /**
        Return only the `replace, constRandom`.
        `replace` - the Text that gets replaced from the `item`.
        ex: "Play [s]". I want to replace [s] with 'sus', so (if item == [s]) replace = 'sus'; .

        `constRandom` is the attribute of the item from `challengesData`, you want to get a random item from `attributes`?
        set constRandom to a item in `attributes` and it will set it in the saveData. Used to properly get the attribute type.
    **/
    return [replace, constRandom];
}