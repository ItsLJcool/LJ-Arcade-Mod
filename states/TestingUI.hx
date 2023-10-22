//a
import openfl.filters.ShaderFilter;
import CustomShader;
import flixel.math.FlxRect;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.util.FlxGradient;
import ColoredNoteShader;

var bgSpr:FlxSprite;
function create() {
	omogu = new CustomShader(Paths.shader("amongSus", mod));
	setOmogusShador(omogu, {
		fill: 0xFF000000,
		outline: 0xFF0DE40D,
		gradientData: {
			gradient: true,
			coloredGradient: false,

			fillCap: {min: -0.25, max: 1.5},
			outlineCap: {min: -0.25, max: 1.5},

			fillGrad: 0xFF000000,
			outlineGrad: 0xFF000000
		}
	});

	bgSpr = new FlxSprite(0,0, Paths.image('ratingState/RatingScreen'));
	bgSpr.setGraphicSize(FlxG.width, FlxG.height);
	bgSpr.screenCenter();
	var uh = colorToShaderVec(0xFFFF0000, true);
	bgSpr.shader = new ColoredNoteShader(uh.r, uh.g, uh.b, false);
	add(bgSpr);

	var gradient = FlxGradient.createGradientFlxSprite(bgSpr.width/1.5, bgSpr.height, [0x00000000, 0x90000000], 1, 0, true);
	gradient.setPosition(bgSpr.x + bgSpr.width/1.5 - gradient.width/2, bgSpr.y + bgSpr.height/2 - gradient.height/2);
	add(gradient);

    var spr = new FlxUI9SliceSprite(0,0, Paths.image('ratingState/RatingsThing Test'), new Rectangle(0, 0, 600, 60), [3, 3, 153, 58]);
    spr.updateHitbox();
    spr.screenCenter();
    spr.antialiasing = true;
    add(spr);
    spr.shader = omogu;
}

function update(elapsed:Float) {
    if (FlxG.keys.justPressed.L) FlxG.switchState(new MainMenuState());
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
	/* 
		0xAARRGGBB
		we could just return 0xFF (int) but that means we will always return 1, so lets just
		get the alpha from the color, (i think) i need to mult the RGB by alpha
	*/
	var a = (color >> 24) & 0xff;

	var r = (color >> 16) & 0xff;
	var g = (color >> 8) & 0xff;
	var b = (color & 0xff);
	return (rgbUh) ? {r: r, g: g, b: b, a: a} : [(r)/100, (g)/100, (b)/100];
}

function colorHue(color:Int) {
	var colored = colorToShaderVec(color, true);
	var hueRad = Math.atan2(Math.sqrt(3) * (colored.g - colored.b), 2 * colored.r - colored.g - colored.b);
	var hue:Float = 0;
	if (hueRad != 0) hue = 180 / Math.PI * hueRad;
	return hue < 0 ? hue + 360 : hue;
}

/*
	Hex - (FF, A1)
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