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
import CustomShader;
import mod_support_stuff.ContextMenu;

import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxRect;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.group.FlxTypedSpriteGroup;
import flixel.util.FlxSpriteUtil;
import flixel.ui.FlxButton;

import Type;
import StringTools;
import flixel.addons.display.FlxGridOverlay;

var bg:FlxSprite;
var bgScale:Float = 1;

var maxItemShopSize:FlxUI9SliceSprite;
var shopAssets:FlxTypedSpriteGroup;

var camUI:FlxCamera;

var shopTabData = {
    sections: [{
        bgData: [
            {
                position: new FlxPoint(0,0),
                size: new FlxPoint(150, 150),
                bgType: "normal",
                rarity: "common",
                flipX: false,
                flipY: false
            }
        ]
    }]
};

var illegalShop:Bool = false;
var editingMod = "Friday Night Funkin'";
function new(_editMod) {
    editingMod = _editMod;
}

var addNewObj:FlxButton;
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
    new Rectangle(0, 0, 1000, 600), [20, 20, 460, 460]);
    maxItemShopSize.screenCenter();
    // maxItemShopSize.visible = false;
    add(maxItemShopSize);
    var minus:Int = 22;
    bgMax = new FlxSprite().makeGraphic(maxItemShopSize.frameWidth-minus, maxItemShopSize.frameHeight-minus, 0xFF000000);
    bgMax.alpha -= 0.4;
    bgMax.setPosition(maxItemShopSize.x + maxItemShopSize.width/2 - bgMax.width/2, maxItemShopSize.y + maxItemShopSize.height/2 - bgMax.height/2);
    insert(members.indexOf(maxItemShopSize)-1, bgMax);
    generateGrid();

    addNewObj = new FlxButton(bgMax.x + bgMax.width, bgMax.y + bgMax.height + 15, "Add New Item", addNewItem);
    addNewObj.x -= addNewObj.width - 5;
    add(addNewObj);
    
    var loadTab = new FlxButton(addNewObj.x, addNewObj.y, "Load Shop Tab", function() {
        openDialoguePaths("open", "Save Your Tab Set in your YCE Mod!", null, function(data) {
            loadNewShopTab(data);
        });
    });
    loadTab.x -= loadTab.width + 15;
    add(loadTab);

    var saveTab = new FlxButton(loadTab.x, loadTab.y, "Save Shop Tab", function() {
        if (illegalShop) return;
        getProperData();
        openDialoguePaths("save", "Save Your Tab Set in your YCE Mod!", shopTabData);
    });
    saveTab.x -= saveTab.width + 15;
    add(saveTab);

    //errors check
    // overlapSprite = new FlxSprite().makeGraphic(200, 200, 0xFFFF0000);
    // overlapSprite.visible = false;
    // add(overlapSprite);
}

function loadNewShopTab(data) {
    shopTabData = data;
    /**
        var widthHeight = new FlxPoint(spr.width, spr.height);

        var mask = FlxSpriteUtil.alphaMask(new FlxSprite(),
        Paths.image("shop/bg/"+folder+"/"+item), Paths.image("SquareShit"));
        var newSpr = new FlxUI9SliceSprite(0,0, mask.graphic,
            new Rectangle(0, 0, widthHeight.x, widthHeight.y), [20, 20, 480, 480]);
        newSpr.ID = spr.ID;
        newSpr.setPosition(spr.x, spr.y);
        shopAssets.replace(spr, newSpr);
        spr.kill();
        spr.destroy();
        shopAssets.remove(spr);
    **/
    shopAssets.forEach(function(spr) {
        spr.kill();
        spr.destroy();
    });
    shopAssets.clear();

    for (section in data.sections) {
        for (idx in 0...section.bgData.length) {
            var stuff = section.bgData[idx];
            var mask = FlxSpriteUtil.alphaMask(new FlxSprite(),
            Paths.image("shop/bg/"+stuff.bgType+"/"+stuff.rarity), Paths.image("SquareShit"));
            var newSpr = new FlxUI9SliceSprite(0,0, mask.graphic,
                new Rectangle(0, 0, stuff.size.x, stuff.size.y), [20, 20, 480, 480]);
            newSpr.ID = idx;
            newSpr.setPosition(stuff.position.x,stuff.position.y);
            shopAssets.add(newSpr);
            newSpr.flipX = stuff.flipX;
            newSpr.flipY = stuff.flipY;
        }
    }
}

function getProperData() {
    for (spr in shopAssets.members) {
        shopTabData.sections[section].bgData[spr.ID].position = new FlxPoint(spr.x, spr.y);
        shopTabData.sections[section].bgData[spr.ID].size = new FlxPoint(spr.width, spr.height);
        shopTabData.sections[section].bgData[spr.ID].flipX = spr.flipX;
        shopTabData.sections[section].bgData[spr.ID].flipY = spr.flipY;
    }
}

var isSelecingObj:Bool = false;
var selectedObj:Dynamic;
var addativeSpr:FlxSprite;
function snapSpriteToGrid(sprite:FlxSprite, mouseX:Int, mouseY:Int) {
    var xOffset:Int = -10;
    var yOffset:Int = 0;
    // Calculate snapped position for the sprite
    var snappedX:Int = (Math.round(mouseX / cellSize) * cellSize);
    var snappedY:Int = (Math.round(mouseY / cellSize) * cellSize);
    
    // Calculate bounds for the sprite
    var minX:Int = bgMax.x;
    var minY:Int = bgMax.y;
    var maxX:Int = (bgMax.x + bgMax.width) - sprite.width; // Adjusted for the sprite's width
    var maxY:Int = (bgMax.y + bgMax.height + cellSize) - sprite.height; // Adjusted for the sprite's height

    // Clamp sprite position within bounds
    sprite.x = Math.max(minX, Math.min(maxX, snappedX - 0.5));
    sprite.y = Math.max(minY, Math.min(maxY, snappedY - 6));
}

var removingData:Array = [null, null];
function update(elapsed) {
    if (FlxG.keys.justPressed.P) FlxG.switchState(new MainMenuState());
    if (FlxG.keys.justPressed.O) FlxG.switchState(new ModState("ShopArcadeEditTest", mod, [editingMod]));
    
    if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
    var lerp = FlxMath.lerp(bgScale + 0.005, bgScale, FlxEase.cubeOut(curDecBeat % 1));
    bg.scale.set(lerp,lerp);
    shador.data.iMouse.value = [FlxG.mouse.x - 150, FlxG.mouse.y - 50, FlxG.mouse.width, FlxG.mouse.height];

    if (FlxG.mouse.justPressed) {
        isSelecingObj = !isSelecingObj;
        shopAssets.forEach(function(item) {
            if (!FlxG.mouse.overlaps(item)) return;
            selectedObj = (isSelecingObj) ? item : null;
        });
    }
    if (selectedObj != null) {
        snapSpriteToGrid(selectedObj, FlxG.mouse.screenX - selectedObj.width/2, FlxG.mouse.screenY - selectedObj.frameHeight/2);
    }

    if (adjustingSize) {
        if (functionAdjust != null) functionAdjust();
    }

    if (FlxG.mouse.justPressedRight && !isSelecingObj) {
        editObj();
    }
    if (isSelecingObj) {
        if (FlxG.keys.justPressed.S) adjustSize(selectedObj, new FlxPoint(bgMax.x + bgMax.width + 15, bgMax.y));
        if (FlxG.keys.justPressed.X) {
            removingData[0] = FlxTween.tween(selectedObj, {angle: -15}, 1.45, {ease: FlxEase.quadIn});
            removingData[3] = new FlxPoint(selectedObj.scale.x, selectedObj.scale.y);
            removingData[1] = FlxTween.tween(selectedObj.scale, {x: (selectedObj.scale.x - 0.15), y: (selectedObj.scale.y - 0.15)}, 1.45, {ease: FlxEase.quadIn});
            var tempObj = selectedObj;
            removingData[2] = new FlxTimer().start(1.5, function(tmr) {
                if (FlxG.keys.pressed.X && removingData[2] != null) {
                    removeItem(tempObj);
                } else {
                    removingData[0] = FlxTween.tween(tempObj, {angle: 0}, 0.15, {ease: FlxEase.quadInOut});
                    removingData[1] = FlxTween.tween(tempObj.scale, {x: (removingData[3].x), y: (removingData[3].y)}, 0.15, {ease: FlxEase.quadInOut});
                    return;
                }
            });
        }
        if (FlxG.keys.justReleased.X && removingData[2] != null) {
            removingData[2].cancel();
            if (removingData[0] != null) removingData[0].cancel();
            if (removingData[1] != null) removingData[1].cancel();
            removingData[0] = FlxTween.tween(selectedObj, {angle: 0}, 0.15, {ease: FlxEase.quadInOut});
            removingData[1] = FlxTween.tween(selectedObj.scale, {x: (removingData[3].x), y: (removingData[3].y)}, 0.15, {ease: FlxEase.quadInOut});
        }

        if (FlxG.keys.justPressed.R) {
            flipRotation(selectedObj);
        }
    }
    if (!illegalShop) {
        bg.color = FlxColor.interpolate(bg.color, 0xFFFFFFFF, elapsed*10);
        checkSpriteOverlap();
    } else {
        bg.color = FlxColor.interpolate(bg.color, 0xFFFF9696, elapsed);
        spriteOverlaps();
    }
}

function flipRotation(spr) {
    if (!spr.flipX && !spr.flipY) spr.flipX = true;
    else if (spr.flipX && !spr.flipY) spr.flipY = true;
    else if (spr.flipX && spr.flipY) spr.flipX = false;
    else if (!spr.flipX && spr.flipY) spr.flipY = false;
}

function checkSpriteOverlap() {
    for (i in 0...shopAssets.members.length) {
    var spriteA = shopAssets.members[i];
    if (spriteA != selectedObj) spriteA.alpha = FlxMath.lerp(spriteA.alpha, 0.5, FlxG.elapsed);
    else spriteA.alpha = FlxMath.lerp(spriteA.alpha, 1, FlxG.elapsed*5);
    
    if ((spriteA.x + spriteA.width) > (bgMax.x + bgMax.width + 20) || (spriteA.y + spriteA.height) > (bgMax.y + bgMax.height + 20)) {
        illegalShop = true;
        return;
    }
    for (j in (i + 1)...shopAssets.members.length) {
        var spriteB = shopAssets.members[j];
        if (checkOverlap(spriteA, spriteB, 0,0)) {
            illegalShop = true;
            return [spriteA, spriteB];
        }
    }
    }
    illegalShop = false;
}
function checkOverlap(sprite1:FlxSprite, sprite2:FlxSprite, xOffset:Int = 0, yOffset:Int = 0) {
    // Adjust sprite positions with offsets
    var x1:Int = sprite1.x + xOffset;
    var y1:Int = sprite1.y + yOffset;
    var x2:Int = sprite2.x;
    var y2:Int = sprite2.y;

    // Check for overlap
    return (x1 < x2 + (sprite2.width - 12) &&
            x1 + (sprite1.width - 12) > x2 &&
            y1 < y2 + (sprite2.height - 12) &&
            y1 + (sprite1.height - 12) > y2);
}
var overlapSprite:FlxSprite;
function spriteOverlaps() {
    var sprites = checkSpriteOverlap();
    if (sprites == null) {
        // overlapSprite.visible = false;
        return;
    };
    var sprite1 = sprites[0];
    var sprite2 = sprites[1];
    // // Calculate overlapping area
    // var overlapWidth:Float = Math.min(sprite1.x + sprite1.width, sprite2.x + sprite2.width) - Math.max(sprite1.x, sprite2.x);
    // var overlapHeight:Float = Math.min(sprite1.y + sprite1.height, sprite2.y + sprite2.height) - Math.max(sprite1.y, sprite2.y);
    
    // // Calculate the position of the overlapSprite
    // overlapSprite.x = Math.min(sprite1.x, sprite2.x) + (Math.abs(sprite1.x - sprite2.x) / 2);
    // overlapSprite.y = Math.min(sprite1.y, sprite2.y) + (Math.abs(sprite1.y - sprite2.y) / 2);
    // var size = 15;
    // overlapSprite.setGraphicSize(overlapWidth - size, overlapHeight - size);
    // if ((overlapWidth - size) < 0 || (overlapHeight - size) < 0) {
    //     overlapSprite.visible = false;
    //     illegalShop = false;
    // }
    // else overlapSprite.visible = true;
}
function editObj() {
    for (item in shopAssets.members) {
        if (FlxG.mouse.overlaps(item)) {
            var xy = new FlxPoint(bgMax.x + bgMax.width + 15, bgMax.y);
            var avaliableStyles = [];
            for (itms in defaultTypes) {
                avaliableStyles.push({
                    label: itms,
                    callback: function() {
                        var items = getRarities(itms);
                        var newItems = [];
                        for (thing in items) {
                            newItems.push({
                                label: thing,
                                callback: function() {
                                    setSprToShopBG(itms, thing, item);
                                },
                                enabled: true
                            });
                        }
                        openSubState(new ContextMenu(xy.x, xy.y, newItems));
                        FlxG.state.persistentUpdate = true;
                        // Substate fix
                        new FlxTimer().start(0.0001, function() { FlxG.state.subState.curSelected = 0; });
                    },
                    enabled: true
                });
            }
            avaliableStyles.push({
                label: "Adding Custom BG Soon",
                enabled: false
            });
            var more = [
                {
                    label: "Adjust Size (Keybind: S)",
                    callback: function() {
                        adjustSize(item, xy);
                    },
                    enabled: true
                }, {
                    label: "Rotate 90° CC (Keybind: R)",
                    callback: function() {
                        flipRotation(item);
                    },
                    enabled: true
                }, {
                    label: "Remove Item (Keybind: X)",
                    callback: function() {
                        removeItem(item);
                    },
                    enabled: true
                },
            ];
            for (die in more) avaliableStyles.push(die);
            openSubState(new ContextMenu(xy.x, xy.y, avaliableStyles));
            FlxG.state.persistentUpdate = true;
            // Substate fix
            new FlxTimer().start(0.0001, function() { FlxG.state.subState.curSelected = 0; });
            break;
        }
    }
}

function removeItem(spr) {
    isSelecingObj = false;
    FlxTween.tween(spr.scale, {x:0, y:0}, 0.3, {ease: FlxEase.quadOut, onComplete: function() {
        var theThing = shopAssets.remove(spr, true);
        theThing.kill();
        theThing.destroy();
    }});
    FlxTween.tween(spr, {alpha: 0, angle: -90}, 0.25, {ease: FlxEase.quadOut});
}

var adjustingSize:Bool = false;
var functionAdjust:Dynamic;

var minimumScale:Int = 150;
function adjustSize(spr, subStatePos) {
    adjustingSize = true;
    var scaleOutline = new FlxSprite().makeGraphic(spr.width - 10, spr.height - 10, 0x80000000);
    insert(members.indexOf(shopAssets)+1, scaleOutline);
    scaleOutline.screenCenter();
    var addative = new FlxPoint(0,0);
    var getSize = function(?size:Bool = true) {
        if (size == null) size = true;
        if (size) return new FlxPoint((scaleOutline.x + ((spr.width) + addative.x/2)), (scaleOutline.y + ((spr.height) + addative.y/2)));
        else return new FlxPoint(scaleOutline.width * scaleOutline.scale.x, scaleOutline.height * scaleOutline.scale.y);
    };
    addativeSpr = scaleOutline;
    var onNoMore = function() {
        adjustingSize = false;
        functionAdjust = null;
        addativeSpr = null;
        spr.resize(scaleOutline.width * scaleOutline.scale.x + 10, scaleOutline.height * scaleOutline.scale.y + 10);
        snapSpriteToGrid(spr, spr.x, spr.y);
        scaleOutline.kill();
        scaleOutline.destroy();
        remove(scaleOutline);
        if (FlxG.state.subState != null) FlxG.state.subState.close();
    };
    functionAdjust = function() {
        var add = (FlxG.keys.pressed.SHIFT) ? cellSize * 5 : cellSize;
        if (FlxG.keys.justPressed.L) {
            addative.x += add;
            if (getSize().x > (bgMax.x + bgMax.width)) addative.x -= add;
            else scaleOutline.setGraphicSize((spr.width - 10) + addative.x, (spr.height - 10) + addative.y);
        }
        if (FlxG.keys.justPressed.J) {
            addative.x -= add;
            scaleOutline.setGraphicSize((spr.width - 10) + addative.x, (spr.height - 10) + addative.y);
            if (getSize(false).x < (minimumScale - 10)) {
                addative.x += add;
                scaleOutline.setGraphicSize((spr.width - 10) + addative.x, (spr.height - 10) + addative.y);
            }
        }
        if (FlxG.keys.justPressed.I) {
            addative.y -= add;
            scaleOutline.setGraphicSize((spr.width - 10) + addative.x, (spr.height - 10) + addative.y);
            if (getSize(false).y < (minimumScale - 10)) {
                addative.y += add;
                scaleOutline.setGraphicSize((spr.width - 10) + addative.x, (spr.height - 10) + addative.y);
            }
        }
        if (FlxG.keys.justPressed.K) {
            addative.y += add;
            scaleOutline.setGraphicSize((spr.width - 10) + addative.x, (spr.height - 10) + addative.y);
            if (getSize().y > (bgMax.y + bgMax.height)) {
                addative.y -= add;
                scaleOutline.setGraphicSize((spr.width - 10) + addative.x, (spr.height - 10) + addative.y);
            }
        }
        var pos = new FlxPoint((spr.x + 5) + (addative.x/2), (spr.y + 5) + (addative.y/2));
        scaleOutline.setPosition(pos.x, pos.y);
        if (FlxG.state.subState == null || FlxG.keys.justPressed.ENTER) onNoMore();
    };
    var arry = [{
        label: "Click / Enter To Accept",
        enabled: false
    },{
        label: "J -> Left",
        enabled: false
    },{
        label: "K -> Down",
        enabled: false
    },{
        label: "I -> Up",
        enabled: false
    },{
        label: "L -> Right",
        enabled: false
    },{
        label: "Shift -> Times 5 ( * 5 )",
        enabled: false
    },
    ];
    openSubState(new ContextMenu(subStatePos.x, subStatePos.y, arry));
    FlxG.state.persistentUpdate = true;
    // Substate fix
    new FlxTimer().start(0.0001, function() { FlxG.state.subState.curSelected = 0; });
}

function getRarities(folder:String) {
    if (!FileSystem.exists(Paths.get_modsPath()+"/"+mod+"/images/shop/bg/"+folder)) return;
    var defaultTypes = [for (itm in FileSystem.readDirectory(Paths.get_modsPath()+"/"+mod+"/images/shop/bg/"+folder)) {
        if (Path.extension(itm) == "png") StringTools.replace(itm, ".png", "");
    }];
    return defaultTypes;
}

function setSprToShopBG(folder:String, item:String, spr:FlxUI9SliceSprite) {
    
    var widthHeight = new FlxPoint(spr.width, spr.height);

    var mask = FlxSpriteUtil.alphaMask(new FlxSprite(),
    Paths.image("shop/bg/"+folder+"/"+item), Paths.image("SquareShit"));
    var newSpr = new FlxUI9SliceSprite(0,0, mask.graphic,
        new Rectangle(0, 0, widthHeight.x, widthHeight.y), [20, 20, 480, 480]);
    newSpr.ID = spr.ID;
    newSpr.setPosition(spr.x, spr.y);
    shopAssets.replace(spr, newSpr);
    spr.kill();
    spr.destroy();
    shopAssets.remove(spr);
    
    shopTabData.sections[section].bgData[spr.ID].position = new FlxPoint(newSpr.x, newSpr.y);
    shopTabData.sections[section].bgData[spr.ID].size = new FlxPoint(newSpr.width, newSpr.height);
    shopTabData.sections[section].bgData[spr.ID].bgType = folder;
    shopTabData.sections[section].bgData[spr.ID].rarity = item;
    shopTabData.sections[section].bgData[spr.ID].flipX = spr.flipX;
    shopTabData.sections[section].bgData[spr.ID].flipY = spr.flipY;
}

var grid:FlxSprite;
var cellSize:Int = 15;
function generateGrid() {
    shador = new CustomShader(Paths.shader("fadeAroundMouse", mod));
    shador.data.iMouse.value = [FlxG.mouse.x - 150, FlxG.mouse.y - 50, FlxG.mouse.width, FlxG.mouse.height];
    shador.data.radiusCircle.value = [250, 250];
    shador.data.radius.value = [1];
    shador.data.smoothRadius.value = [1];
    
    var subtract = 20;
    grid = FlxGridOverlay.create(cellSize,cellSize, (1000)-subtract, (600)-subtract, true);
    grid.setPosition(maxItemShopSize.x+(subtract/2)+2, maxItemShopSize.y+(subtract/2)+2);
    grid.shader = shador;
    insert(members.indexOf(maxItemShopSize)-1, grid);
}

var sample:FlxUI9SliceSprite;
var sizes = [
    new FlxPoint(300, 580),
];

var defaultTypes = [for (itm in FileSystem.readDirectory(Paths.get_modsPath()+"/"+mod+"/images/shop/bg")) { if (Path.extension(itm) == "") itm; }];

var section = 0;
function addNewItem() {
    var type = defaultTypes[FlxG.random.int(0, defaultTypes.length-1)];
    var mask = FlxSpriteUtil.alphaMask(new FlxSprite(),
    Paths.image("shop/bg/"+type+"/common"), Paths.image("SquareShit"));
    sample = new FlxUI9SliceSprite(0,0, mask.graphic,
        new Rectangle(0, 0, 200, 200), [20, 20, 480, 480]);
    sample.ID = shopAssets.members.length;
    sample.alpha = 0.0001;
    FlxTween.tween(sample, {alpha: 1}, 0.75, {ease: FlxEase.expoOut});
    shopAssets.add(sample);
    snapSpriteToGrid(sample, sample.x, sample.y);

    shopTabData.sections[section].bgData[sample.ID] = {
        position: new FlxPoint(sample.x, sample.y),
        size: new FlxPoint(sample.width, sample.height),
        bgType: type,
        rarity: "common",
        flipX: false,
        flipY: false,
    }
}















function openDialoguePaths(type:String = 'open', ?openText:String, ?fileToSave:Dynamic, ?onWindowClose:Dynamic) {
    if (illegalShop) return;
    if (openText == null) openText = "";
    switch(type.toLowerCase()) {
        case "open":
            CoolUtil.openDialogue(FileDialogType.OPEN, openText, function(t) {
                if (Path.extension(t).toLowerCase() != "json") {
                    trace("You Need To Grab A json File");
                    return;
                }
                var FUCK = t;
                addNewWindow("test", "Unfinished work", 200, "Nah Im Good, DO NOT SAVE", "Oh thanks! Cancel", function() {
                    var data = Json.parse(File.getContent(FUCK));
                    if (onWindowClose != null) onWindowClose(data);
                });
                killMePlease = new FlxText(0,50,newWindow.width,"Before you open this Shop Tab, would you like to save your current one or discard it?", 25);
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
                if (fileToSave == null) {
                    trace("Error! You need to provide a json in the Argument!!");
                    return;
                }
                File.saveContent(t, Json.stringify(fileToSave, null, "\t"));
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
