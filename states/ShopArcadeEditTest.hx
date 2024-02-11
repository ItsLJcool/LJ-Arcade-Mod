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

import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxRect;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.group.FlxTypedSpriteGroup;
import flixel.util.FlxSpriteUtil;

import Type;
import StringTools;

var bg:FlxSprite;
var bgScale:Float = 1;

var maxItemShopSize:FlxUI9SliceSprite;
var shopAssets:FlxTypedSpriteGroup;

var camUI:FlxCamera;

var customShop = {
    tabs: [
        {
            tabName: "Your Item Shop Tab Name",
            items: [
            {
                itemName: "Your Item",
                spritesData: [
                    {
                        position: {
                            x: 0, y: 0
                        },
                        center: true,
                        antialiasing: true,
                        path: null,
                        sparrow: {
                            animated: true,
                            idle: ["funnyThing instance 1", 12],
                            selected: ["funnyThing instance 1", 24],
                            otherAnims: [
                                "null" => "null"
                            ],
                        },
                        alpha: 1,
                    },
                ],
                cost: 0,
                bgData: {
                    bg: "legendary",
                    type: "radial",
                    flipX: false,
                    flipY: false,
                },
            }
            ],
            tabSet: 0,
            modShopScript: null,
        },
    ],
};

var editingMod = "Friday Night Funkin'";
function new(_editMod) {
    editingMod = _editMod;
}
function create() {
	camUI = new FlxCamera();
	camUI.bgColor = 0;
	FlxG.cameras.add(camUI, false);

    bg = new FlxSprite(0,0, Paths.image("menuDesat"));
    bg.setGraphicSize(FlxG.width, FlxG.height);
    bg.screenCenter();
    bgScale = bg.scale.x;
    bg.antialiasing = true;
    add(bg);

    shopAssets = new FlxTypedSpriteGroup();
    add(shopAssets);

    maxItemShopSize = new FlxUI9SliceSprite(0,0, Paths.image("SquareOutline"),
    new Rectangle(0, 0, 1005, 605), [20, 20, 460, 460]);
    maxItemShopSize.screenCenter();
    // maxItemShopSize.visible = false;
    add(maxItemShopSize);
    var minus:Int = 22;
    bgMax = new FlxSprite().makeGraphic(maxItemShopSize.frameWidth-minus, maxItemShopSize.frameHeight-minus, 0xFF000000);
    bgMax.alpha -= 0.4;
    bgMax.setPosition(maxItemShopSize.x + maxItemShopSize.width/2 - bgMax.width/2, maxItemShopSize.y + maxItemShopSize.height/2 - bgMax.height/2);
    insert(members.indexOf(maxItemShopSize)-1, bgMax);
}
function update(elapsed) {
    if (FlxG.keys.justPressed.P) FlxG.switchState(new MainMenuState());
    if (FlxG.keys.justPressed.O) FlxG.switchState(new ModState("ShopEditorOther", mod, [editingMod]));

    if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
    var lerp = FlxMath.lerp(bgScale + 0.005, bgScale, FlxEase.cubeOut(curDecBeat % 1));
    bg.scale.set(lerp,lerp);
}

















function openDialoguePaths(type:String = 'open', ?openText:String) {
    if (openText == null) openText = "";
    switch(type.toLowerCase()) {
        case "open":
            CoolUtil.openDialogue(FileDialogType.OPEN, openText, function(t) {
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
            CoolUtil.openDialogue(FileDialogType.OPEN, openText, function(t) {
                if (Path.extension(t).toLowerCase() != "json") {
                    trace("You Need To Grab A json File");
                    return;
                }
                // File.saveContent(t, Json.stringify(dialogue, null, "\t"));
            });
    }
}
var uhTab:FlxUI;
var windowBG:FlxSprite;
var inWindow:Bool = false;
function addNewWindow(name:String, title:String, height:Int, enterText:String, ?exitText:String, ?callback:Void->Void, ?cancelCallback:Void->Void) {
    inWindow = true;
    windowBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0x88000000);
    windowBG.alpha = 0.0001;
    add(windowBG);
    newWindow = new FlxUITabMenu(null, null, [
        {
            name: name,
            label: title,
        }
    ], null, true);
    uhTab = new FlxUI(null, newWindow);
    newWindow.alpha = 0.0001;
    uhTab.name = name;

    var buttons = [];
    var bottomButton = new FlxUIButton(250, height, enterText, function() {
        if (newWindow.alpha < 0.75 || !newWindow.visible) return;
        removeWindow();
        if (callback != null) callback();
    });
    var exitButton = new FlxUIButton(250, height, exitText, function() {
        if (newWindow.alpha < 0.75 || !newWindow.visible) return;
        removeWindow();
        if (cancelCallback != null) cancelCallback();
    });
    buttons.push(bottomButton); buttons.push(exitButton);
    FlxSpriteUtil.space(buttons, 175, height, 100, 0);

    newWindow.resize(500, bottomButton.y + bottomButton.height + 25);
    newWindow.screenCenter();
    newWindow.addGroup(uhTab);
    if (enterText != null) uhTab.add(bottomButton);
    if (exitText != null) uhTab.add(exitButton);
    add(newWindow);
    
    var closeButton = new FlxUIButton(newWindow.width - 24, -15, "X", function() {
        removeWindow();
        if (cancelCallback != null) cancelCallback();
    });
    closeButton.color = 0xFFFF4444;
    closeButton.label.color = 0xFFFFFFFF;
    closeButton.resize(20, 20);
    
    uhTab.add(closeButton);
    FlxSpriteUtil.fadeIn(windowBG, 0.15, true, function() {
        FlxSpriteUtil.fadeIn(newWindow, 0.25, true);
    });
}
function removeWindow() {
    FlxSpriteUtil.fadeOut(newWindow, 0.15, function() {
        FlxSpriteUtil.fadeOut(windowBG, 0.15, function() {
            newWindow.destroy();
            windowBG.destroy();
            uhTab.destroy();
            new FlxTimer().start(0.15, function() {inWindow = false;});
        });
    });
}

function condenseInt(inted:Int) {
    inted = Std.parseInt(inted);
    if (inted < 999) return Std.string(inted);
    else {
        if (Math.floor(roundToDecimals(inted/1000000000, 2)) >= 1)
            return roundToDecimals(inted/1000000000, 2) + "B"; // how?

        if (Math.floor(roundToDecimals(inted/1000000, 2)) >= 1)
            return roundToDecimals(inted/1000000, 2) + "M";

        return roundToDecimals(inted/1000, 2) + "K";
    }
    return "a number, sorry lol";
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
