//a
enableRating = false;

function create() {
    var isPixelNote = false;
    if (PlayState.noteScripts[0].metadata.noteType.split(":")[1] != null && FlxG.state.noteScripts[0].metadata.noteType.split(":")[0].toLowerCase() != null) isPixelNote = (PlayState.noteScripts[0].metadata.noteType.split(":")[0].toLowerCase() == "pixel note" || PlayState.noteScripts[0].metadata.noteType.split(":")[1].toLowerCase() == "pixel note");
    if (PlayState.noteScripts[0].metadata.noteType.toLowerCase() == "pixel note") isPixelNote = true;
    var thing = (isPixelNote) ? [17, 17] : [133, 128];
    note.loadGraphic((isPixelNote) ? Paths.image("notes/mines/pixel/mines") : Paths.image("notes/mines/base/mines"), true, thing[0], thing[1]);
    note.colored = false;
    note.splashColor = 0xffFF0000;
    // note.animation.add("idle", [0], 12, false);
    note.animation.add("scroll", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 12, true);
    note.animation.play("scroll", true);
    note.antialiasing = !isPixelNote;
    note.hitOnBotplay = false;
    note.cpuIgnore = true;
    note.updateHitbox();
    note.noteOffset.x -= (isPixelNote) ? -45 : 10;
}

function onPlayerHit(note) {
    PlayState.misses++;
    if (!EngineSettings.botplay) {
        PlayState.health -= 0.125 * 2.5;
    }
}

function onMiss() {
    return false;
}

function onDadHit(shrex:Int) { // still don't know what shrex variable is
    super.onDadHit(shrex);
}