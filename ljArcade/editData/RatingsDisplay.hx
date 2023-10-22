//a
import AlphabetOptimized;
import flixel.group.FlxTypedGroup;
import flixel.math.FlxPoint;

// This is where you can edit the display of what shows in the ratings (Max 3 for now)
/**
    @param title The Text the title of the card will be
    @param stuff the function that returns and sets values
**/
/**
	[group] - The FlxTypedGroup of the card (not including the card sprite as of right now)
	You can add and remove objects within it, allows you to add whatever you want to the card, even sprites!
	make sure you do `group.add()` instead of `add()`

	[index] - the # (Number) of the card, since right now the max cards is 3, it can be `0, 1, 2`

	How to offset your sprites (in the group)? By returning an FlxPoint

	ex: `return [new FlxPoint(50, -50)];`, this will offset group.members[0] on the X and Y. its like doing `spr.x + number`
	you could also do `return [{x: 50, y: 50}];` I guess.

	Returning null or not returning at all will set it do a default offset.

	function yourCustomCard(group:FlxTypedGroup, index:Int) {
		group.members[0].text = "AMONG US";
		
		var whiteBox = new FlxSprite().makeGraphic(150, 150, 0xFFFFFFFF);
		whiteBox.updateHitbox();
		group.add(whiteBox);
		
		return [new FlxPoint(25, -5)];
	}
**/

function create() {
	// you can change cardData here to customize it even more!
}

function songScoreText(grp:FlxTypedGroup, index) {
	grp.members[0].text = playState.songScore;
	return [new FlxPoint(25, -5)];
}

function accuracyText(grp:FlxTypedGroup, index) {
	var text:String = playState.acc[1].split(":")[1];
	if (text == null) text = playState.acc[1];
	grp.members[0].text = text;
	return [new FlxPoint(25, -5)];
}

function missesText(grp:FlxTypedGroup, index) {
	var text:String = playState.misses[1].split(":")[1];
	if (text == null) text = playState.misses[1];
	grp.members[0].text = text;
	return [new FlxPoint(25, -5)];
}
/**
	MAKE SURE THIS IS AT THE END OF THE FILE IF YOUR NOT EDITING IT INSIDE A FUNCTION, its just how code works ig
**/
cardData = [
	{
		title: "Song Score",
		stuff: songScoreText
	},
	{
		title: "Accuracy",
		stuff: accuracyText
	},
	{
		title: "Misses",
		stuff: missesText
	}
];