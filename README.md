# Tales of Popolon Extended (MSX) by Santiago Ontañón Villar

This project is just a playground for experimenting with extensions to my original Tales of Popolon game. You can find the original game here: https://github.com/santiontanon/talesofpopolon

List of improvements:
- Faster raycasting engine with many optimizations (some of them contributed by msx.org's forum user NYYRIKKI; his changes are credited in the code with his name). It is about 39% faster than the original.
- Better use of MSX turbo R. The rendering code is decompressed to RAM, since when running code from RAM, the turbo R is much faster.
- Slightly improved renderer if an MSX2 or higher VDP is detected, to avoid color flickering
- Game speed is now properly controlled and it runs at the same speed regardless of the MSX clock speed (turbo or not, etc.)
- Higher resolution textures (32x16), and they can now have arbitrary colors in each pixel, so, I've redrawn a few (not fully exploiting this at the moment though)
- The game size as been reduced, and at this point, even with the higher rez textures, etc. there is more than 2.5KB of free space in the 32KB cartridge. So, I have a list of improvements/additions that I couldn't include in the original and that I will be adding bit by bit (e.g., key redefinition, a couple of items that I had to get rid of, an extra map, etc.)

*Note*: The current version is not very stable, and it contains several known bugs. So, if the game hangs, or weird things happen (e.g., I know some doors do not remain open after changing maps), it's ok. I'm still working on it, and I have a list of known bugs, which I'll be working through...

You can download the latest builds from the releases tab, here: https://github.com/santiontanon/talesofpopolon-ext/releases

