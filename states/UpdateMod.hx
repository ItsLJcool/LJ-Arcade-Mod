//a
import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import flixel.ui.FlxBarFillDirection;

import openfl.events.IOErrorEvent;
import openfl.events.ErrorEvent;

import openfl.events.Event;
import openfl.events.ProgressEvent;

import openfl.net.URLLoader;
import openfl.net.URLStream;
import openfl.net.URLRequest;

import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

import MenuMessage;
import CoolUtil;
import flixel.group.FlxTypedGroup;
import flixel.group.FlxTypedSpriteGroup;
import openfl.utils.ByteArrayData;
import sys.io.Process;
import openfl.system.System;

var url:String = "";
var tag:String = "";
/**
    BitmapData.loadFromFile("https://raw.githubusercontent.com/ThatOneIdiotXav/thing/master/cne/imgs/suffering.png")
        .onComplete(function(bitmap:BitmapData) {
        var f:FlxSprite = new FlxSprite().loadGraphic(bitmap);
        f.screenCenter();
        f.setGraphicSize(FlxG.width, FlxG.height);
        f.alpha = .1;
        add(f);
    });
**/

var downloadExtenstion:String = "";
function new(_url:String) {
    if (!Assets.exists(Paths.txt("version"))) {
        openSubState(new MenuMessage(
            "Mod Doesn't contain a `version.txt` in `data/`. If your a developer, please add it.", [
            {
                label: "Play Mod Without Updating",
                callback: function() {
                    FlxG.switchState(new MainMenuState());
                }
            }
        ]));
    }
    var version = Assets.getText(Paths.txt("version")).split("\n");
    downloadExtenstion = version[1];
    url = _url + StringTools.trim(version[0]) + "/" + StringTools.trim(version[1]);
}

var w = 775;
var h = 550;
var downloadedFiles:Int = 0;
var bg:FlxTypedSpriteGroup = new FlxTypedSpriteGroup();
function create() {
    FlxG.autoPause = false;

    var loadingThingy = new FlxSprite(0, 0, Paths.image("loading/bg", "preload"));
    loadingThingy.setGraphicSize(FlxG.width, FlxG.height);
    loadingThingy.screenCenter();
    add(loadingThingy);
    for(x in 0...Math.ceil(FlxG.width / w)+1) {
        for(y in 0...(Math.ceil(FlxG.height / h)+1)) {
            // bg pattern
            var pattern = new FlxSprite(x * w, y * h, Paths.image("loading/bgpattern", "preload"));
            pattern.antialiasing = true;
            bg.add(pattern);
        }
    }
    add(bg);

    bf = new FlxSprite(337.60, 27.30).loadGraphic(Paths.image("loading/bf", "preload"));
    bf.antialiasing = true;
    bf.screenCenter(FlxAxes.X);
    add(bf);

    var loading = new FlxSprite().loadGraphic(Paths.image("loading/updating"));
    loading.scale.set(0.85, 0.85);
    loading.updateHitbox();
    loading.y = FlxG.height - (loading.height * 1.15);
    loading.screenCenter(FlxAxes.X);
    loading.antialiasing = true;
    add(loading);
    
    downloadBar = new FlxBar(0, 0, FlxBarFillDirection.LEFT_TO_RIGHT, Std.int(FlxG.width * 0.75), 30);
    downloadBar.createGradientBar([0x88222222], [0xFF7163F1, 0xFFD15CF8], 1, 90, true, 0xFF000000);
    downloadBar.screenCenter(FlxAxes.X);
    downloadBar.y = FlxG.height - 45;
    downloadBar.scrollFactor.set(0, 0);
	downloadBar.setRange(0, 100);
    add(downloadBar);
    
    percentLabel = new FlxText(downloadBar.x, downloadBar.y + (downloadBar.height / 2), downloadBar.width, "0%");
    percentLabel.setFormat(Paths.font("vcr.ttf"), 22, 0xFFFFFFFF, "center", "outline", 0xFF000000);
    percentLabel.y -= percentLabel.height / 2;
    add(percentLabel);
    
    currentFileLabel = new FlxText(0, downloadBar.y - 10, FlxG.width, "");
    currentFileLabel.setFormat(Paths.font("vcr.ttf"), 22, 0xFFFFFFFF, "center", "outline", 0xFF000000);
    currentFileLabel.y -= percentLabel.height * 2;
    add(currentFileLabel);
    loadYCEmod();
}
function colorToShaderVec(color:Int, ?rgbUh:Bool = false) {
    if (color == null) return;
	if (rgbUh == null) rgbUh = false;
	var r = (color >> 16) & 0xff;
	var g = (color >> 8) & 0xff;
	var b = (color & 0xff);
	return (rgbUh) ? {r: r, g: g, b: b, a: (color >> 24) & 0xff} : [(r)/100, (g)/100, (b)/100];
}

var fileList:Array<String> = ["shut up"];
var downloadedFiles:Int = 0;
var percentLabel:FlxText;
var currentFileLabel:FlxText;
var totalFiles:Int = 1;
var daValue;
function loadYCEmod() {
    var downloadStream = new URLLoader();
    downloadStream.dataFormat = 0;
    
    var request = new URLRequest(StringTools.replace(url, " ", "%20"));
    currentFileLabel.text = 'Downloading File: '+downloadExtenstion;
    
    downloadStream.addEventListener("ioError", function(e) {
        if (StringTools.contains(e.text, "404")) {
            
            trace('404 Error');
        } else {
            openSubState(new MenuMessage('Failed to download the .ycemod. Make sure you have a working internet connection, and try again.\n\nError ID: '+ e.errorID +'\n'+ e.text, [
                {
                    label: "Play Mod Without Updating",
                    callback: function() {
                        FlxG.switchState(new MainMenuState());
                    }
                }
            ]));
        }
    });
    downloadStream.addEventListener("complete", function(e) {
        trace("Complete");
        FileSystem.createDirectory('./_cache/');
        var fileOutput:FileOutput = File.write('./_cache/'+downloadExtenstion, true);

        var data = new ByteArrayData();
        downloadStream.data.readBytes(data, 0, downloadStream.data.length - downloadStream.data.position);
        fileOutput.writeBytes(data, 0, data.length);
        fileOutput.flush();

        fileOutput.close();
		downloadedFiles++;

        new FlxTimer().start(0.5, function() {
            new Process('start /B _cache/'+ downloadExtenstion, null);
            System.exit(0);
        });
    });
    downloadStream.addEventListener("progress", function(e) {
        var ll = CoolUtil.getSizeLabel(Std.int((e.bytesLoaded - oldBytesLoaded) / (t - oldTime)));

        daValue = Math.floor(((downloadedFiles / totalFiles) + (e.bytesLoaded / e.bytesTotal / totalFiles)) * 100);
        percentLabel.text = [for(i in 0...ll.length) " "].join("") +'     '+ daValue+'% ('+ll+'/s)';
        
        oldTime = t;
        oldBytesLoaded = e.bytesLoaded;
    });

    downloadStream.load(request);
}
var t:Float = 0;
var oldTime:Float = 0;
var oldBytesLoaded:Float = 0;

function update(elapsed) {
    t += elapsed; // for speed calculations

    downloadBar.value = daValue;

    bg.x = -(w * t / 4) % w;
    bg.y = -(h * t / 4) % h;

    bf.angle = Math.sin(t / 10) * 10;
}