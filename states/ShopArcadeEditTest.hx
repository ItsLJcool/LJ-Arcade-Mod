//a

import Conductor;
import CoolUtil;
import sys.FileSystem;
import haxe.Json;
import sys.io.File;
import haxe.io.Path;
import lime.ui.FileDialogType;
import lime.ui.FileDialog;
import flixel.addons.text.FlxTypeText;
import flixel.addons.ui.FlxInputText;
import Script;
import ScriptPack; // you fucking cant just do 'Script.ScriptPack' you gotta import them one by on
import flixel.text.FlxTextBorderStyle;

import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIDropDownHeader;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import dev_toolbox.file_explorer.FileExplorer;
import dev_toolbox.file_explorer.FileExplorerType;
import flixel.addons.ui.StrNameLabel;
import flixel.FlxBasic;
import flixel.FlxCamera;
import dev_toolbox.ColorPicker;
import StringTools;

var bg:FlxSprite;
var bgScale:Float = 1;
function create() {
    bg = new FlxSprite(0,0, Paths.image("menuDesat"));
    bg.setGraphicSize(FlxG.width, FlxG.height);
    bg.screenCenter();
    bgScale = bg.scale.x;
    bg.antialiasing = true;
    add(bg);


}

function update(elapsed) {
    if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
    var lerp = FlxMath.lerp(bgScale + 0.005, bgScale, FlxEase.cubeOut(curDecBeat % 1));
    bg.scale.set(lerp,lerp);
}

var tabsData = [
    5, 3, 6, 5,
];
var customShop = null;
function setTabSet(type) {
    var itemShop = new FlxTypedSpriteGroup();
    insert(members.indexOf(shopAssets)-1, itemShop);

    var size = {
        big: new FlxPoint(335, 550),
        small: new FlxPoint(275, 275)
    };

    var itms = [];
    var makeSprites = function(idx, ?func) {
        if (customShop.items[idx] == null || customShop.items[idx].bg == null) {
            var spr = new FlxUI9SliceSprite(0,0, Paths.image("SquareShit"),
            new Rectangle(0, 0, size.small.x, size.small.y), [20, 20, 460, 460]);
            spr.alpha = 0.4;
            spr.color = 0xFF000000;
            itms.push(spr);
            spr.x = 0; spr.y = 0;
            if (func != null) func(spr);
        } else {
            var bgYes = Std.string(customShop.items[idx].bg); // replace with `existsInMods` later
            if (defaultTypes.exists(bgYes.toLowerCase())) {
                bgYes = bgYes.toLowerCase();
                var bgType = "normal";
                bgYes = StringTools.replace(defaultTypes.get(bgYes), "[type]", bgType);
            }
            // trace(Paths.image(bgYes));
            var test = new FlxSprite();
            test.ID = idx;
            var endTest = FlxSpriteUtil.alphaMask(test, Paths.image(bgYes), Paths.image("SquareShit"));
            var nineSpliceTest = new FlxUI9SliceSprite(0,0, endTest.graphic,
            new Rectangle(0, 0, size.small.x, size.small.y), [20, 20, 460, 460]);
            itms.push(nineSpliceTest);
            nineSpliceTest.x = 0; nineSpliceTest.y = 0;
            if (func != null) func(nineSpliceTest);
        }
    };
    var amt:Int = customShop.items.length;
    if (customShop.items.length > tabsData[type]) amt = tabsData[type];
    for (i in 0...amt) {
        var func = null;
        switch(type) {
            case 0:
                func = function(bgItem) {
                    var sze = (i == 0) ? new FlxPoint(450, 550) : size.small;
                    bgItem.resize(sze.x, sze.y);
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
                };
            case 1:
                func = function(bgItem) {
                    bgItem.resize(size.big.x, size.big.y);
                    bgItem.x = bgItem.width*i;
                };
            case 2: func = function(bgItem) {
                bgItem.resize(size.small.x, size.small.y);
                bgItem.x = bgItem.width*(i % 3);
                if (i > 2) bgItem.y += bgItem.height;
                // so it can go up, down, up, down, etc...
            }
            case 3: func = function(bgItem) {
                var big = new FlxPoint(400, 600);
                var sze = (i < 2) ? big : new FlxPoint(200, 200);
                bgItem.resize(sze.x, sze.y);
                
                bgItem.y = 0;
                if (i > 1) {
                    bgItem.x = big.x*2;
                    bgItem.y = bgItem.height*(i-2);
                } else {
                    bgItem.x = bgItem.width*(i);
                }
            }
        }
        makeSprites(i, func);
    }
}

function openDialoguePaths(type:String = 'open') {
    switch(type.toLowerCase()) {
        case "open":
            CoolUtil.openDialogue(FileDialogType.OPEN, "Open Your Dialogue.json", function(t) {
                if (Path.extension(t).toLowerCase() != "json") {
                    trace("You Need To Grab A json File");
                    return;
                }
                var FUCK = t;
                addNewWindow("test", "Unfinished work", 200, "Nah Im Good, DO NOT SAVE", function() {
                    //a
                });
                killMePlease = new FlxText(0,50,newWindow.width,"Before you open this Dialogue, would you like to save your current one or discard it?", 25);
                killMePlease.alignment = "center";
                uhTab.add(killMePlease);
                killMePlease.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 1.5);
            });
        case "save":
            CoolUtil.openDialogue(FileDialogType.OPEN, "Save Your Dialogue.json", function(t) {
                if (Path.extension(t).toLowerCase() != "json") {
                    trace("You Need To Grab A json File");
                    return;
                }
                // File.saveContent(t, Json.stringify(dialogue, null, "\t"));
            });
    }
}
var uhTab:FlxUI;
function addNewWindow(name:String, title:String, height:Int, enterText:String, ?callback:Void->Void) {
    windowBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0x88000000);
    add(windowBG);
    newWindow = new FlxUITabMenu(null, null, [
        {
            name: name,
            label: title,
        }
    ], null, true);
    uhTab = new FlxUI(null, newWindow);
    uhTab.name = name;

    var bottomButton = new FlxUIButton(250, height, enterText, function() {
        removeWindow();
        if (callback != null) callback();
    });
    bottomButton.x -= bottomButton.width / 2;

    newWindow.resize(500, bottomButton.y + bottomButton.height + 25);
    newWindow.screenCenter();
    newWindow.addGroup(uhTab);
    if (enterText != null) uhTab.add(bottomButton);
    add(newWindow);
    
    var closeButton = new FlxUIButton(newWindow.width - 24, -15, "X", function() {
        removeWindow();
    });
    closeButton.color = 0xFFFF4444;
    closeButton.label.color = 0xFFFFFFFF;
    closeButton.resize(20, 20);
    
    uhTab.add(closeButton);
}
function removeWindow() {
    newWindow.destroy();
    windowBG.destroy();
    uhTab.destroy();
}

/*
    Ideas:
    Basically your mod can have its own Item Shop that can sell items you can use in your mod.
    I will probably make a feature to allow all mods to make items usable in other mods
    but it will be complicated.

    You will be able to edit a specific tabSet (and make a custom one in the future) where you can edit
    specific sections of your "Tab" and add images (animated or not) and set the BG of the shop too.
    
    There are default types that you can use if you don't have a shop bg, and different styles

    Right now, the BG has to be 500x500 (because im a dummie) but you don't need to make it rounded,
    it will automatically round the edges.

    The editor is just easier to make, so I can edit the itemShop stuff whenever very easally.

    I want to make a server that holds specific data that you can upload your itemStuff to the servers
    and it will be accessable to everyone at the same time, instead of it being random for everyone.
*/
