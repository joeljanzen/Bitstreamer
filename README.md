# Bitstreamer

A rhythm game where you, the central processor, receive streams of bits to run programs. Make too many errors and you will crash the program, so be careful! The user is depending on you.

# Credits

Created by Joel Janzen with Godot Engine

Music composed by Joel Janzen

CRT Shader by Flowerwall: https://github.com/Art-Michel/Flowerwall-CRT-shader-for-Godot

Special thanks to osu!

# Dev Notes

## Accuracy Calculation

Important calculations such as accuracy use the physics process which runs at a constant, fast rate, unlike the normal process.

Physics process is set to 240 fps which can measure differences as small as 4.16 milliseconds. This should be running at this rate regardless of the FPS chosen by the player, so that accuracy calculations and song timing events are always as accurate as possible.

## Level Parameters

Self-explanatory parameters are not listed here. See their minimal explanations in the code documentation.

### Version

Used to distinguish levels that use the same song. For the most part, the version of a level should generally be described in terms of its overall difficulty (there is no value associated with a level for overall difficulty yet, as there are too many factors going into a level's difficulty at the moment and no formula has yet been devised to compile those factors into a single value).

The standard version names are as follows, in order of overall difficulty:
- Easy
- Normal
- Hard
- Insane
- Expert
- Extreme
- Unreal

Despite that, a level's version can be called anything at all (there are no actual restrictions). Not all versions of a level may be of a different overall difficulty; they may be different in other aspects, such as their speed, required accuracy (difficulty, not to be confused with *overall* difficulty), damage dealt, and most importantly the bit patterns that make up the level.

#### Standard Level Parameters by Version
Though there are no strict restrictions on the parameters a particular standard version should have, some basic guidelines may be useful:

- Easy: 0-3 difficulty, 1-5 speed
- Normal: 4-5 difficulty, 5-6 speed
- Hard: 6 difficulty, 7 speed
- Insane: 7-8 difficulty, 8-9 speed
- Expert: 9-10 difficulty and speed
- Extreme: 11 difficulty, 10-11 speed
- Unreal: 12 difficulty, 11-12 speed

Damage is not standardized as it depends heavily on a level's mapping. Generally, it will be low (1-5 damage) for easy to normal levels, increase for hard to insane levels (6-10 damage), and remain similar or even decrease for levels of higher difficulty, to compensate for more frequently spawning bits. As a general rule, damage should never exceed 20 unless affected by mods.

### BPM

The beats per minute of the song. Can be a fractional value, if for some reason that is needed. Right now, BPM must be constant throughout the entire song.

### Speed

Determines how quickly the bits move across the screen towards the cursor. The minimum speed is 1 and the maximum speed is 12. 

The speed value is converted into an approach time, i.e. the time it takes a bit to reach the cursor after being sent (in seconds). A higher speed value equates to a shorter approach time. 
The approach time goes from 3 seconds at speed 1 to 0.5 seconds at speed 12.

### Difficulty

Determines the accuracy (i.e. the hit windows) required to get a perfect, good, okay score, or miss a bit. The minimum difficulty is 0 and the maximum difficulty is 12. 

The perfect click range goes from 80ms at difficulty 0 to 8ms at difficulty 12.
The good click range goes from 140ms at difficulty 0 to 44ms at difficulty 12.
The okay click range goes from 200ms at difficulty 0 to 80ms at difficulty 12.

This difficulty system is inspired by what osu! uses. 

### Damage

The amount of damage missing or incorrectly clicking a bit does (must be an integer). The player has 100 health to start.

Damage can be set to zero to make failing impossible, but it cannot be negative. Setting damage to anything above 100 will be no different than it being at 100, as the player will fail immediately after a miss or error-click either way.

### Length

The length of the level in seconds. The file stores up to 3 decimal places of precision. 

Automatically calculated if it's not already in the level file.

### Bit Count

The total number of bits to be sent to the player in the level (all bit types are included, not just 0s and 1s).

Automatically calculated if it's not already in the level file.

## Level Files

### Level Data

The first line contains comma-separated tokens such as "bpm=100" that hold data about the level. Unrecognized tokens will throw an error, but the loading process will continue anyway as long as the needed tokens are found. These are "song", "song_filename", "bpm", "speed", "diff", "dmg"

The needed tokens can be in any order in the first line, as long as they are all properly separated by a comma and their value is proper for its descriptor (bpm must be a number, version must be a string, etc.). See more info about these in [[#Level Parameters]].

### Bits and Delays

Each line in the file after the first contains 2 values separated by a comma. The first is a delay, and the second is the bit to play after that delay.

You can safely put empty lines anywhere you wish to improve readability. They will be ignored.

Add headers for song sections (comments) starting with a single hashtag. Always put headers entirely on their own line (no in-line comments).

#### Delays

The delay can be denoted in the file as a raw float delay (in seconds) by preceding the value with "f". To cause a delay of 1.5 seconds, the delay should appear in the file as "f1.5"

The delay can more conveniently be denoted as a number of beats, a beat being calculated based on the level's BPM parameter.

You can give just a floating point value, which is the number of beats to delay. However, fractional beats of delay should be instead be indicated as a fraction of integers, such as "1/3" to indicate a third of a beat delay. This is easier to understand and more precise than giving the floating point value (typing 0.333333 is only so accurate, and looks nasty).

##### First Delay

The first delay after the song starts has to be at least as long as it takes for a bit to reach the cursor. This is so that the bit can be sent in time to reach the cursor when it is supposed to.

If you run into this problem, but really want to send a bit at the time you gave, you either have to increase the bit speed, so it can make it to the cursor by the delay you've indicated, or you must place some silence at the start of the audio file that will provide the sufficient time for the first bit to reach the cursor.

#### Bits

A simple legend denotes the values associated with each bit type:
- "0" indicates a zero bit
- "1" indicates a one bit
- "enter" indicates an enter bit
- "back" indicates a back bit

This value follows the delay that will proceed its sending to the screen.
