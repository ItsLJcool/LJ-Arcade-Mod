# How to use LJ Arcade Images
You need to replace the specific file location name, if user is using skins your overrides may not be affected

## What can I edit within my mod?
It depends, but as of (Version: 2.1.0) you can edit a bit.
### Rating UI
`ljArcade/images/ratingsState/` - You can't customize color yet but you can edit the image `ratingInfo.png`, but it doesn't work really good right now. As it uses `FlxUI9SliceSprite`, meaning you need a 4 index array with `[X, Y, Width, Height]` and there is no way to edit that within your mod, **YET.**

You can edit the sprites for `F, E, D, C, B, A, S, +, -` within your mod, look in `images/ratingsState/` in your LJ Arcade mod for 2 examples of how you can do your ratings:
1. XML - `ratingsSheet.png / ratingsSheet.xml`
2. Individual PNG's - `ratings/`

### SFX( `sounds/` )
If you edit the sound files normally (ex: `freakyMenu`) then it will be applied in the mod automatically.

### MenuDesat (`images/menuDesat`)
Editing that image will apply that background in `ModEditing.hx`, and (soon) will be able to edit the color.