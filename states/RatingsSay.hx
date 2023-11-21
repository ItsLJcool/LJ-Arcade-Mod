//a
import Settings;
import flixel.math.FlxMath;
import openfl.filters.ShaderFilter;
import CustomShader;
import flixel.math.FlxRect;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.util.FlxGradient;
import ColoredNoteShader;
import AlphabetOptimized;
import ModSupport;
import flixel.group.FlxTypedGroup;
import flixel.math.FlxPoint;
import ModSupport;
import Script;
import DummyScript;
import StringTools;
import ScoreText;

var ljTokenImage:FlxSprite;
var editingMod:String;
var playState:Dynamic;

var cheated:Bool = false;

var cardData:Dynamic;
var properRating = "F";
function create(ps:Dynamic) {
	trace(ps.tokenMult);
    if (ps.tokenMult == null) ps.tokenMult = 1;
	if (ps.tokenMult > 2.5) ps.tokenMult = 2.5;
	playState = ps;
	editingMod = playState.mod;
	if (FlxG.sound.music != null) FlxG.sound.music.stop();
	var thing = (StringTools.contains(playState.acc[1], ":")) ? playState.acc[1].split(":")[1].split("%")[0] : playState.acc[1].split("%")[0];
	properRating = getScoreReal(thing);
	cheated = (properRating == "-" || playState.rating[0].toLowerCase() == "botplay" || playState.rating[0].toLowerCase() == 'n/a' || !playState.canDie || !playState.validScore || playState.rating[1] == "-");
    var theMod = editingMod;
    if (!Assets.exists(Paths.getLibraryPathForce("ljArcade/editData/RatingsDisplay.hx", "mods/" + theMod))) theMod = mod;

    RatingsScript = Script.create(Paths.modsPath + "/" + mod + "/ljArcade/editData/RatingsDisplay.hx");
    ModSupport.setScriptDefaultVars(RatingsScript, mod, {});
    if (RatingsScript == null) RatingsScript = new DummyScript();

    RatingsScript.setVariable("create", function() {});
    RatingsScript.setVariable("loadingMod", mod);
    RatingsScript.setVariable("mod", editingMod);
    RatingsScript.setVariable("PlayState", playState);
    RatingsScript.setVariable("playState", playState);
    RatingsScript.setVariable("cardData", [{
		title: "Song Score",
		stuff: function (grp:FlxTypedGroup, index) {
				grp.members[0].text = playState.songScore;
				return [new FlxPoint(25, -5)];
			},
		}, {
		title: "Accuracy",
		stuff: function (grp:FlxTypedGroup, index) {
				var text = playState.acc[1].split(":")[1];
				if (text == null) text = playState.acc[1];
				grp.members[0].text = text;
				return [new FlxPoint(25, -5)];
			},
		}, {
			title: "Misses",
			stuff: function (grp:FlxTypedGroup, index) {
				var text = playState.misses[1].split(":")[1];
				if (text == null) text = playState.misses[1];
				grp.members[0].text = text;
				return [new FlxPoint(25, -5)];
			},
		}
	]);
    RatingsScript.loadFile();
	RatingsScript.executeFunc("create", function(){});
	cardData = RatingsScript.getVariable("cardData");

	makeUI();
}

function getScoreReal(acc) {
	acc = Std.parseFloat(acc) / 100;
	var rating = "huh";
	if (acc == 1) rating = "S";
	else if (acc >= 0.9) rating = "S";
	else if (acc >= 0.8) rating = "A";
	else if (acc >= 0.7) rating = "B";
	else if (acc >= 0.6) rating = "C";
	else if (acc >= 0.5) rating = "D";
	else if (acc >= 0.4) rating = "E";
	else if (acc == 0) rating = "-";
	else rating = "F";

	return rating;
}

// ModSupport.modSaves[loadedMod].data.challengesData.get(editingMod).data[challengeID].vars.daData.set("hasCompletedChallenge", true);

var bgSpr:FlxSprite;
var topSpr:FlxSprite;
var barsThing:Array<Dynamic> = [];

var ratingSpr:FlxSprite;
var ratingAdd:FlxSprite;
var ratingAtlas:Bool = true;

var ratingColors:Dynamic = [
	"F" => 0xFFFF0000,
	"E" => 0xFFFF6600, // might be unused
	"D" => 0xFFD0FF00,
	"C" => 0xFF00FFFF,
	"B" => 0xFF0080FF,
	"A" => 0xFF00FF00,
	"S" => 0xFFFF0062
];
var ratingScale:Float = 0.75;
var ratingAddScale:Float = 0.5;
var ratingOrder:Array<String> = ["F", "E", "D", "C", "B", "A", "S"];

var ratingInfo:Array<Dynamic> = [];

var challengeText = "";
function makeUI() {
	if (playState.theChallengeWasCompleted.hasCompleted || !playState.doingChallenge) {
	challengeText = (playState.doingChallenge) ?
	ModSupport.modSaves[mod].data.challengesData.get(editingMod).data[playState.theChallengeWasCompleted.dataID.itemID].vars.daText :
	"( Freeplay ) | Completed " + StringTools.replace(playState.song, "-", " ");
	} else {
		challengeText = "Failed Challenge | Song: " + StringTools.replace(playState.song, "-", " ");
	}
	omogu = new CustomShader(Paths.shader("amongSus", mod));
	setOmogusShador(omogu, {
		fill: 0xFF000000,
		outline: 0xFF0DE40D,
		gradientData: {
			gradient: true,
			coloredGradient: false,

			fillCap: {min: -1, max: 3},
			outlineCap: {min: -1, max: 3},

			fillGrad: 0xFF000000,
			outlineGrad: 0xFF000000
		}
	});

	bgSpr = new FlxSprite(0,0, existsInMods("ljArcade/images/ratingState/RatingScreen.png", Paths.image("ratingState/RatingScreen")));
	bgSpr.setGraphicSize(FlxG.width, FlxG.height);
	bgSpr.screenCenter();
	var uh = colorToShaderVec(0xFFFF0000, true);
	bgSpr.shader = new ColoredNoteShader(uh.r, uh.g, uh.b, false);
	add(bgSpr);

	var gradient = FlxGradient.createGradientFlxSprite(bgSpr.width/1.5, bgSpr.height, [0x00000000, 0x90000000], 15, 0, true);
	gradient.setPosition(bgSpr.x + bgSpr.width/1.5 - gradient.width/2, bgSpr.y + bgSpr.height/2 - gradient.height/2);
	add(gradient);

	var topSpr = new FlxUI9SliceSprite(0,0, existsInMods("ljArcade/images/ratingState/ratingInfo.png", Paths.image("ratingState/ratingInfo")),
	new Rectangle(0, 0, 750, 60), [3, 3, 153, 58]);
	topSpr.updateHitbox();
	topSpr.setPosition(0, 0 + topSpr.height/2);
	topSpr.antialiasing = true;
	topSpr.shader = omogu;
	add(topSpr);

	var topChallenge:AlphabetOptimized = new AlphabetOptimized(topSpr.x + 15, topSpr.y, challengeText, false, Math.min(0.6, (topSpr.width - 75) / (35 * challengeText.length)));
	topChallenge.setPosition(topSpr.x + 15, topSpr.y + topSpr.height/2 - topChallenge.height/2 - 7);
	add(topChallenge);

	var item:Int = 3;
	var tempY:Array<Dynamic> = [15, -125, -275];
	var xThing:Array<Dynamic> = [450, 375, 325];
	for (i in 0...item) {
		var spr = new FlxUI9SliceSprite(0,0, existsInMods("ljArcade/images/ratingState/ratingInfo.png", Paths.image("ratingState/ratingInfo")),
		new Rectangle(0, 0, xThing[i], 60), [3, 3, 153, 58]);
		var middle = FlxG.height/2 - spr.height/2;
		spr.updateHitbox();
		spr.setPosition(-spr.width - 10, middle - tempY[i]);
		spr.antialiasing = true;
		spr.shader = omogu;
		spr.ID = i;
		add(spr);
		barsThing.push(spr);
	}

	ratingSpr = new FlxSprite();
	ratingAdd = new FlxSprite();
	if (ratingAtlas) {
		ratingSpr.frames = existsInMods("ljArcade/images/ratingState/ratingsSheet.png", "ratingState/ratingsSheet", true);
		ratingAdd.frames = existsInMods("ljArcade/images/ratingState/ratingsSheet.png", "ratingState/ratingsSheet", true);
		for (i in 0...ratingOrder.length) ratingSpr.animation.addByPrefix(ratingOrder[i], ratingOrder[i], false, 24);
		ratingSpr.animation.play(ratingOrder[0], true);
		for (item in ratingSpr.frames.frames) {
			switch(item.name.split("0")[0].toLowerCase()) {
				case "plus", "minus":
					ratingAdd.animation.addByPrefix(item.name.toLowerCase().split("0")[0], item.name.toLowerCase(), false, 24);
					ratingAdd.animation.play(item.name.toLowerCase().split("0")[0], true);
			}
		}
	} else {
		ratingSpr.loadGraphic(existsInMods("ljArcade/images/ratingState/ratings/" + ratingOrder[0]+".png", Paths.image("ratingState/ratings/" + ratingOrder[0])));
		for (item in ["plus", "minus"]) {
			ratingAdd.loadGraphic(existsInMods("ljArcade/images/ratingState/ratings/"+item+".png", Paths.image("ratingState/ratings/"+item)));
		}
	}

	ratingSpr.scale.set(0.75, 0.75);
	ratingSpr.updateHitbox();
	ratingSpr.screenCenter();
	ratingSpr.x = FlxG.width/1.5;
	ratingSpr.y += 50;
	var uh = colorToShaderVec(ratingColors.get(ratingOrder[0]), true);
	ratingSpr.shader = new ColoredNoteShader(uh.r, uh.g, uh.b, false);
	ratingSpr.alpha = 0.0001;
	add(ratingSpr);
	
	ratingAdd.scale.set(0.5, 0.5);
	ratingAdd.updateHitbox();
	ratingAdd.setPosition(ratingSpr.x + ratingSpr.width/2 + ratingAdd.width/2, ratingSpr.y - ratingAdd.height/2);
	var uh = colorToShaderVec(ratingColors.get(ratingOrder[0]), true);
	ratingAdd.shader = new ColoredNoteShader(uh.r, uh.g, uh.b, false);
	add(ratingAdd);
	ratingAdd.alpha = 0.0001;

	for (i in 0...item) {
		if (cardData[i] == null || cardData[i] == []) continue;
		var titleCard:AlphabetOptimized = new AlphabetOptimized(barsThing[i].x, barsThing[i].y, cardData[i].title, false, 0.5);
		titleCard.ID = i;
		add(titleCard);

        var descGroup = new FlxTypedGroup();
		add(descGroup);
		var text:AlphabetOptimized = new AlphabetOptimized(barsThing[i].x, barsThing[i].y, "Placeholder", true, 0.5);
		text.ID = i;
		descGroup.add(text);
		positioning = cardData[i].stuff(descGroup, i);
		if (positioning == null) positioning = [new FlxPoint(25, 0)];
		if (cheated) {
			descGroup.members[0].text = "CHEATER!!";
			positioning = [new FlxPoint(25, 0)];
		}
		descGroup.members[0].textSize = Math.min(0.5, (barsThing[i].width - 75) / (45 * descGroup.members[0].text.length));
		
		ratingInfo.push([[descGroup, positioning], titleCard]);
	}
    ding = new FlxSound().loadEmbedded(Paths.sound('confirmMenu'));
	ding.startSound(0);
    ding.stop();
    ding.volume = 0.8;
	ding.pitch = 0.85 - 0.025;

	ljTokensAdd();

	// startRating(1);
}

/**
	XP System goes here as well

	Showcase the XP first going up and if leveled up then give 'em the milestone thing
	for now probably just be more Tokens, `10 + ( 10 * Math.floor(level * 0.20) )`
	basically every 5 levels gives you 10 more tokens? idk i suck at math
**/

var ljTokenTween:FlxTween;
var ljTokensText:AlphabetOptimized;

var lerpToken:Bool = false;
function ljTokensAdd() {
	ljTokenTween = FlxTween.tween(this, {}, 0);
	
	var textInt = Std.parseInt(save.data.levelSystem.tokenData.tokens);
	ljTokensText = new AlphabetOptimized(0, 0, textInt, true, 0.5);
	ljTokensText.screenCenter();
	add(ljTokensText);

    ljTokenImage = new FlxSprite(0,0, Paths.image("ljtoken"));
    ljTokenImage.setGraphicSize(100, 100);
    ljTokenImage.scale.set(Math.min(ljTokenImage.scale.x, ljTokenImage.scale.y), Math.min(ljTokenImage.scale.x, ljTokenImage.scale.y));
	ljTokenImage.updateHitbox();
	ljTokenImage.setPosition(ljTokensText.x - ljTokenImage.width - 15, ljTokensText.y + ljTokensText.height/2 - ljTokenImage.height/2);
    ljTokenImage.antialiasing = true;
    add(ljTokenImage);

	var math = (playState.theChallengeWasCompleted.hasCompleted) ? 20 : 0;
    math *= playState.tokenMult; math = Math.floor(math);

    // me when i accidentally divide by 0 and get -2,147,483,648 tokens so i add this here
    if (math > 0 && !cheated) {
        save.data.levelSystem.tokenData.tokens += math;
        save.flush();
    }
    ljTokenTween = FlxTween.num(textInt, textInt + math, 1, {startDelay: 1, ease: FlxEase.cubeInOut}, function(v:Float) {
        ljTokensText.text = Math.ffloor(v);
    });

	FlxTween.tween(ljTokenImage, {x: FlxG.width - ljTokenImage.width - 5, y: 5}, 1, {startDelay: 3, ease: FlxEase.sineInOut, onStart: function() {
		lerpToken = true;
		startRating(1);
	}});
}

function startRating(time:Float) {
	if (ratingInt >= ratingOrder.length-1 || stopRating) return;
	var die = time;
	new FlxTimer().start(time, function() {
		updateRating();
		die -= 0.12;
		if (die <= 0) die = 0.25;
		if (StringTools.contains(properRating, ratingOrder[ratingInt])
			|| (cheated && ratingInt >= ratingOrder.length-1)
			|| (playState.rating[1].toLowerCase() ==  "perfect" && ratingInt >= ratingOrder.length-1)) {
			if (cheated) die = 1;
			new FlxTimer().start(die, function () {
				if (cheated) {
					ratingInt = 0;
					(ratingAtlas) ? ratingSpr.animation.play(ratingOrder[0], true) : ratingSpr.loadGraphic(Paths.image("ratingState/ratings/" + ratingOrder[0]));
					var uh = colorToShaderVec(ratingColors.get(ratingOrder[0]), true);
					ratingSpr.shader.setColors(uh.r, uh.g, uh.b);
					bgSpr.shader.setColors(uh.r, uh.g, uh.b);
					ratingAdd.animation.play("minus", true);
					ratingAdd.alpha = 1;
					ratingAdd.shader.setColors(uh.r, uh.g, uh.b);
					ratingsEnd(true);
					return;
				}
				var theAcc = FlxMath.roundDecimal((playState.acc[0] / playState.numberOfNotes) * 100, 2);
				if ((Math.fround(theAcc) % 10) == 5) {
					new FlxTimer().start(1, ratingsEnd);
					return;
				}
				updateRating(true, ( ((Math.fround(theAcc) % 10) > 5) || playState.rating[1].toLowerCase() ==  "perfect"));
			});
			return;
		}
		startRating(die);
	});
} 

var endingRating:Bool = false;
var stopRating:Bool = false;
var addedExtra = {type: -1};
function updateRating(?addExtra:Bool = false, ?type:Int) {
	ratingSpr.alpha = 1;
	if (addExtra == null) addExtra = false;
	if (addExtra) {
		var uh = colorToShaderVec(ratingColors.get(ratingOrder[ratingInt]), true);
		(ratingAtlas) ? ratingAdd.animation.play((type == 0) ? "minus" : "plus", true) : ratingAdd.loadGraphic(Paths.image("ratingState/ratings/" + ((type == 0) ? "minus" : "plus")));
		addedExtra.type = type;
		ratingAdd.alpha = 1;
		ratingAdd.shader.setColors(uh.r, uh.g, uh.b);
		new FlxTimer().start(1, ratingsEnd);
		ratingAdd.scale.set(ratingAddScale+0.075, ratingAddScale+0.075);
		return;
	}
	ratingInt++;
	if (ratingInt > ratingOrder.length-1) ratingInt = ratingOrder.length-1;
	(ratingAtlas) ? ratingSpr.animation.play(ratingOrder[ratingInt], true) : ratingSpr.loadGraphic(Paths.image("ratingState/ratings/" + ratingOrder[ratingInt]));
	var uh = colorToShaderVec(ratingColors.get(ratingOrder[ratingInt]), true);
	ratingSpr.shader.setColors(uh.r, uh.g, uh.b);
	bgSpr.shader.setColors(uh.r, uh.g, uh.b);
	ratingSpr.scale.set(ratingScale+0.075, ratingScale+0.075);
	FlxTween.tween(ding, {pitch: ding.pitch + 0.025}, 0.001);
	ding.play(true);
}

function ratingsEnd(?loser:Bool) {
	stopRating = true;
	if (loser == null) loser = false;
	if (!loser) {
    	FlxG.sound.play(existsInMods("sounds/confirmMenu.ogg", Paths.sound("confirmMenu")));
		ratingSpr.scale.set(ratingScale+0.1, ratingScale+0.1);
		ratingAdd.scale.set(ratingAddScale+0.1, ratingAddScale+0.1);
	} else {
    	FlxG.sound.play(Paths.sound("blud"), 1);
	}
	for (item in barsThing) {
		FlxTween.tween(item, {x: 0}, 1, {startDelay: 1 + (0.5*item.ID) * 0.25, ease: FlxEase.sineOut});
	}
	new FlxTimer().start(1 + (0.5*barsThing.length) * 0.25, function() {
		endingRating = true;
	});
	if (!cheated) {
		var addTo:Int = 0;
		switch(ratingInt) {
			case 6: addTo = 150;
			case 5: addTo = 125;
			case 4: addTo = 100;
			case 3: addTo = 75;
			case 2: addTo = 50;
			case 1: addTo = 25;
			case 0: addTo = 15;
		}
		switch(addedExtra.type) {
			case 1: addTo += 50;
			case 0: addTo += 25;
			default: addTo += 0;
		}
		save.data.levelSystem.xpData.xp += addTo;
		save.flush();
	}
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
}

var ratingInt:Int = -1;
function update(elasped:Float) {
	ratingSpr.scale.set( FlxMath.lerp(ratingSpr.scale.x, ratingScale, elasped*10), FlxMath.lerp(ratingSpr.scale.x, ratingScale, elasped*10) );
	ratingAdd.scale.set( FlxMath.lerp(ratingAdd.scale.x, ratingAddScale, elasped*10), FlxMath.lerp(ratingAdd.scale.x, ratingAddScale, elasped*10) );

	if (lerpToken) {
		ljTokensText.x = FlxMath.lerp(ljTokensText.x, ljTokenImage.x - ljTokensText.width - 15, elasped*3);
		ljTokensText.y = FlxMath.lerp(ljTokensText.y, ljTokenImage.y + ljTokenImage.height/2 - ljTokensText.height/2, elasped*3);
	}

	for (i in 0...barsThing.length) {
		var followed = barsThing[i];
		for (j in 0...ratingInfo[i].length) {
			var item = ratingInfo[i][j];
			switch(j) {
				case 0:
					for (k in 0...item[0].members.length) {
						var thing = item[0].members[k];
						thing.x = followed.x + item[1][k].x;
						thing.y = followed.y + followed.height/2 - thing.height/2 + item[1][k].y;
					}
				case 1:
					item.x = followed.x + 25;
					item.y = followed.y - item.height - 20;
			}
		}
	}
	if (endingRating && FlxControls.anyJustPressed([13, 32, 27])) {
		FlxG.switchState(new ModState("ModEditing", Settings.engineSettings.data.selectedMod, [editingMod, (cheated) ? { hasCompleted: false } : playState.theChallengeWasCompleted]));
	}
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

function colorHue(color:Int) {
	var colored = colorToShaderVec(color, true);
	var hueRad = Math.atan2(Math.sqrt(3) * (colored.g - colored.b), 2 * colored.r - colored.g - colored.b);
	var hue:Float = 0;
	if (hueRad != 0) hue = 180 / Math.PI * hueRad;
	return hue < 0 ? hue + 360 : hue;
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
		shader.data.fillGradientCap.value = [colors.gradientData.fillCap.min, colors.gradientData.fillCap.max];
		shader.data.outlineGradientCap.value = [colors.gradientData.outlineCap.min, colors.gradientData.outlineCap.max];

		shader.data.enableGradient.value[0] = 1;
		if (colors.gradientData.coloredGradient) {
			shader.data.fillGradientColor.value = colorToShaderVec(colors.gradientData.fillGrad);
			shader.data.outlineGradientColor.value = colorToShaderVec(colors.gradientData.outlineGrad);
			
			shader.data.enableGradient.value[1] = 1;
		}
	}
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