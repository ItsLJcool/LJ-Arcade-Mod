//a
import discord_rpc.DiscordRpc;
import DiscordClient;
import ModSupport;
import logging.LogsOverlay;
import StringTools;
import Script;

var crafterEngineLogo:FlxSprite = null;
var gfDancing:FlxSprite = null;
function create() {
    DiscordClient.initialize();
	gfDancing = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
	gfDancing.frames = Paths.getSparrowAtlas('titlescreen/gfDanceTitle');
	gfDancing.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
	gfDancing.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
	gfDancing.animation.play('danceLeft', true);
	gfDancing.antialiasing = true;
	add(gfDancing);

	crafterEngineLogo = new FlxSprite(-50, -35);
	crafterEngineLogo.frames = Paths.getSparrowAtlas('titlescreen/logoBumpin');
	crafterEngineLogo.antialiasing = true;
	crafterEngineLogo.animation.addByPrefix('bump', 'logo bumpin', 24);
	crafterEngineLogo.animation.play('bump');
	crafterEngineLogo.updateHitbox();
	crafterEngineLogo.scale.x = crafterEngineLogo.scale.y = 0.95;
	add(crafterEngineLogo);
    
    RPCScript = Script.create(Paths.modsPath + "/" + mod + "/RPC.hx");
    ModSupport.setScriptDefaultVars(RPCScript, mod, {});
    if (RPCScript == null) RPCScript = new DummyScript();

    RPCScript.setVariable("create", function() {});
    RPCScript.setVariable("mod", mod);
    RPCScript.loadFile();
    RPCScript.executeFunc("create");
}

function onUpdateCheck() {
    if (LogsOverlay.hscript.variables.get("isMostUpToDateArcade") != true 
        && !LogsOverlay.hscript.variables.exists("skippedUpdate")) {
        FlxG.switchState(new ModState("OutdatedLJArcade", mod, []));
    }
}

function beatHit() {
	if (gfDancing != null)
		gfDancing.animation.play((gfDancing.animation.curAnim.name == "danceLeft") ? "danceRight" : "danceLeft");
}
var updateDiscordRPC:Float = 2;
function update(elapsed:Float) {
    updateDiscordRPC += elapsed;
    if (updateDiscordRPC >= 2) {
        updateDiscordRPC = 0;
        ModSupport.refreshDiscordRpc();
    }
}