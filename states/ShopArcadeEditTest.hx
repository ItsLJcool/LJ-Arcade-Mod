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

import StringTools;

var bg:FlxSprite;
var bgScale:Float = 1;

var maxItemShopSize:FlxUI9SliceSprite;
function create() {
    bg = new FlxSprite(0,0, Paths.image("menuDesat"));
    bg.setGraphicSize(FlxG.width, FlxG.height);
    bg.screenCenter();
    bgScale = bg.scale.x;
    bg.antialiasing = true;
    add(bg);

    shopAssets = new FlxTypedSpriteGroup();
    add(shopAssets);

    maxItemShopSize = new FlxUI9SliceSprite(0,0, Paths.image("SquareOutline"),
    new Rectangle(0, 0, 1000, 600), [20, 20, 460, 460]);
    maxItemShopSize.screenCenter();
    // maxItemShopSize.visible = false;
    add(maxItemShopSize);
    var minus:Int = 22;
    var bgMax = new FlxSprite().makeGraphic(maxItemShopSize.frameWidth-minus, maxItemShopSize.frameHeight-minus, 0xFF000000);
    bgMax.setPosition(maxItemShopSize.x + maxItemShopSize.width/2 - bgMax.width/2, maxItemShopSize.y + maxItemShopSize.height/2 - bgMax.height/2);
    insert(members.indexOf(maxItemShopSize)-1, bgMax);


    for (item in customShop.tabs) {
        setTabSet(item);
    }

}

function update(elapsed) {
    if (FlxG.keys.justPressed.P) {
        FlxG.switchState(new MainMenuState());
    }
    if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
    var lerp = FlxMath.lerp(bgScale + 0.005, bgScale, FlxEase.cubeOut(curDecBeat % 1));
    bg.scale.set(lerp,lerp);
}

var tabsData = [
    5, 3, 6, 5,
];
// use StringTools.relpace() for this
var defaultTypes:Map = [
    "uncommon" => "shop/bg/[type]/uncommon",
    "common" => "shop/bg/[type]/common",
    "rare" => "shop/bg/[type]/rare",
    "epic" => "shop/bg/[type]/epic",
    "legendary" => "shop/bg/[type]/legendary",
];
var customShop = {
    tabs: [
        {
            tabName: "Your Item Shop Tab Name",
            items: [
                {
                    item: "test",
                    cost: 0,
                    bgData: {
                        bg: "uncommon",
                        type: "square",
                        flipX: false,
                        flipY: false,
                    },

                    // sparrow: null
                },
                {
                    item: "test",
                    cost: 0,
                    bgData: {
                        bg: "common",
                        type: "normal",
                        flipX: true,
                        flipY: true,
                    },
                    // sparrow: null
                },
                {
                    item: "test",
                    cost: 0,
                    bgData: {
                        bg: "rare",
                        type: "normal",
                        flipX: false,
                        flipY: true,
                    },
                    // sparrow: null
                },
                {
                    item: "test",
                    cost: 0,
                    bgData: {
                        bg: "epic",
                        type: "normal",
                        flipX: true,
                        flipY: false,
                    },
                    // sparrow: null
                },
                {
                    item: "test",
                    cost: 0,
                    bgData: {
                        bg: "legendary",
                        type: "normal",
                        flipX: false,
                        flipY: false,
                    },
                    // sparrow: null
                }
            ],
            tabSet: 0,
            modShopScript: null,
        },
    ],
    /*
        Might be able to make multiple itemShop tabs, for now just 1
    */
};
var shopSectons:Int = -1;
function setTabSet(data) {
    shopSectons++;
    var itemShop = new FlxTypedSpriteGroup();
    insert(members.indexOf(shopAssets)-1, itemShop);

    var size = {
        big: new FlxPoint(330, 550),
        small: new FlxPoint(275, 275)
    };

    var itms = [];
    var makeSprites = function(idx, ?func) {
        if (data.items[idx] == null || data.items[idx].bgData == null || data.items[idx].bgData.bg == null) {
            var spr = new FlxUI9SliceSprite(0,0, Paths.image("SquareShit"),
            new Rectangle(0, 0, size.small.x, size.small.y), [20, 20, 460, 460]);
            spr.alpha = 0.4;
            spr.color = 0xFF000000;
            itms.push(spr);
            spr.x = 0; spr.y = 0;
            if (func != null) func(spr);
        } else {
            var bgYes = Std.string(data.items[idx].bgData.bg); // replace with `existsInMods` later
            var flipX = false;
            var flipY = false;
            if (defaultTypes.exists(bgYes.toLowerCase())) {
                bgYes = bgYes.toLowerCase();
                var bgType = (data.items[idx].bgData.type == null) ? "normal" : data.items[idx].bgData.type;
                bgYes = StringTools.replace(defaultTypes.get(bgYes), "[type]", bgType);

                flipX = (data.items[idx].bgData.flipX == null) ? false : data.items[idx].bgData.flipX;
                flipY = (data.items[idx].bgData.flipY == null) ? false : data.items[idx].bgData.flipY;
            }
            var test = new FlxSprite();
            test.ID = idx;
            var endTest = FlxSpriteUtil.alphaMask(test, Paths.image(bgYes), Paths.image("SquareShit"));
            var nineSpliceTest = new FlxUI9SliceSprite(0,0, endTest.graphic,
            new Rectangle(0, 0, size.small.x, size.small.y), [20, 20, 460, 460]);
            itms.push(nineSpliceTest);
            nineSpliceTest.x = 0; nineSpliceTest.y = 0;
            nineSpliceTest.flipX = flipX; nineSpliceTest.flipY = flipY;
            if (func != null) func(nineSpliceTest);
        }
    };

    var amt:Int = data.items.length;
    if (data.items.length > tabsData[data.tabSet]) amt = tabsData[data.tabSet];
    for (i in 0...amt) {
        var func = null;
        switch(data.tabSet) {
            case 0:
                func = function(bgItem) {
                    var sze = (i == 0) ? new FlxPoint(450, 600) : new FlxPoint(275, 300);
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
    for (i in 0...itms.length) {
        var item = itms[i];
        itemShop.add(item);
        FlxMouseEventManager.add(item, function(){}, function(){
            trace("CLICKED");
            // Add a substate that opens more details about the Item
        }, function(){
            // selShopItem(item);
        }, function() {
            // targetSprShop = null;
        }, true, true, false);

        var sellable = new FlxSprite();
        sellable.frames = Paths.getSparrowAtlas("shop/placeHolder");
        sellable.animation.addByPrefix("idle", "funnyThing instance 1", 12, true);
        sellable.animation.play("idle");
        sellable.antialiasing = true;
        var maxSize = 300;
        sellable.setGraphicSize(item.frameWidth - 50, (item.frameHeight > maxSize) ? maxSize : item.frameHeight);
        sellable.scale.set(Math.min(sellable.scale.x, sellable.scale.y), Math.min(sellable.scale.x, sellable.scale.y)); // Thanks math :dies of horrable math death:
        sellable.updateHitbox();
        sellable.setPosition(item.x + item.width/2 - sellable.width/2, item.y + item.height/2 - sellable.height/2);
        itemShop.add(sellable);

        var token = new FlxSprite(0,0, Paths.image("ljtoken"));
        token.setGraphicSize(50, 50);
        token.scale.set(Math.min(token.scale.x, token.scale.y), Math.min(token.scale.x, token.scale.y)); // Thanks math :dies of horrable math death:
        token.updateHitbox();
        token.setPosition(item.x + item.width - token.width - 5, item.y + item.height- token.height - 5);
        itemShop.add(token);

        data.items[i].cost = Std.parseInt(data.items[i].cost);
        // no more cost than 1 million !! (might change it later)
        if (data.items[i].cost > 1000000) data.items[i].cost = 1000000;
        var bruh = (data.items[i].cost == null || data.items[i].cost < 0) ? "Free" : condenseInt(data.items[i].cost);
        var cost = new FlxText(0, 0, 0, bruh, 20);
        cost.font = Paths.font("Funkin - No Outline.ttf");
        cost.updateHitbox();
        cost.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2);
        cost.setPosition(token.x - cost.width - 5, token.y + token.height/2 - cost.height/2);
        itemShop.add(cost);
    }
    
    if (data.tabName != null) {
        var tab = new FlxText(0, 0, 0, Std.string(data.tabName), Math.min(48, (FlxG.width - 5) / (1 * Std.string(data.tabName).length)));
        tab.font = Paths.font("Funkin - No Outline.ttf");
        tab.scrollFactor.set();
        tab.updateHitbox();
        tab.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2);
        tab.setPosition(tab.x + 20, -tab.height);
        itemShop.add(tab);
    }
    
    itemShop.screenCenter();
    itemShop.x = maxItemShopSize.x; itemShop.y = maxItemShopSize.y;

    shopAssets.add(itemShop);
    itemShop.y += (shopAssets.members[shopSectons].height + 50)*shopSectons;
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
