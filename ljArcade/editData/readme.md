# Custom Challenges ( THIS GUIDE IS FOR KNOWLAGABLE CODERS!! )
How to add custom challenges:
Make a new File called `ChallengesData.hx` ***I Highly Recommend Checking Out [`ljArcade/editData/ChallengesData.hx`](https://github.com/ItsLJcool/LJ-s-Arcade-Mod/blob/staging/ljArcade/editData/ChallengesData.hx) for reference***

## Global Challenges
This applies to any song, meaning any song can get the attributes you add to it.

In `challengesData` variable, there will be something like `challengesToDo" => [`, thats the Global Random Challenges, since its a map, the index of your challenge must be a number (from 0 to whatever), and it will pick a random text from that.

### Why is `0 =>` an array?
Because it goes `[ ChallengeText, limeLimit ]`, ex: if its just `["Bob"]`, then the challenge will reset in 24 hours, if its `["Bob", 1]`, it will reset in 1 hour. `["Bob", 0]` will be 1 minute :trollface:

### Song Specific Challenges
These songs are only specific to a song, meaning only that song may be given the attribute.

Before I explain more, this uses your `freeplaySonglist.json` in your `data` folder. That `Json` uses an array index to showcase the songs in your `FreeplayState`.

Here is an exaplpe of the layout
`freeplaySonglist.json`:
```json
{
    "songs": [
        {
			"displayName": "Test",
			"difficulties": [
				"Hard"
			],
			"char": "bf",
			"color": "#FFFFFF",
			"name": "test"
		}, {
			"displayName": "Song 2",
			"difficulties": [
				"Hard"
			],
			"char": "bf",
			"color": "#FFFFFF",
			"name": "song2"
		},
    ]
}
```
This song's `.length` property would be `2`
```txt
"songSpecificChallenges" => [
    0 => [
        0 => ["Song 1 | Challenge 1"],
        1 => ["Song 1 | Challenge 2"],
    ],
    1 => [
        0 => ["Song 2 | Challenge 1"],
        1 => ["Song 2 | Challenge 2"],
    ],
],
```
basically
```txt
"songSpecificChallenges" => [
    songIndex:Int => [
        challengeID:Int => [challengeData]
    ]
]
```
### Coding The Challenges
You do the coding of the challenges inside `ChallengesData.hx` as well

To complete a challenge, do
```hx
challengeComplete({challengeID: *THEID* });
```
if its a songSpecific Challenge, do
```hx
challengeComplete({challengeID: 1, songSpecific: true, songID: songIndex});
```
## YOU DO NOT HAVE TO CHECK IF THE CHALLENGE IS TRUELY THE CHALLENGE ID!!!
You can just execute the function if the challengeID meets your code requirements
**EX:**
```hx
// The challenge is: Do not die more than 5 times
function onPreEndSong() {
    if (PlayState.blueballAmount <= 5) {
         challengeComplete({challengeID: 0});
    }
}

```
Even if the current challenge isn't `0`, the code automatically handles it for you. Less work for you to do.

## What is `"attributes"` in the `challengesData` variable?
Good question, you can add random attributes into your text when displaying your challenge.

You can get the attribute type and code based on what random was selected.

### What is the `setSongDataValues` function?
It is basically the replacement function of your attributed value.

You set variables `replace` and `constRandom` dependent on the Map Data in `challengesData`.

Its a bit weird to explain but look in your LJ Arcade Mod Example to see how I did my global challenges.

### Any more info?
1. `containables` variable is refrencing the `challengesData` data within it, for your attributes repalcement.
2. `disableGloablChallenges` variable changes weather if you want your mod to have global challenges enabled. If false `challengesToDo` will not be referenced. only `songSpecificChallenges`
3. `randomPercentDiff` variable changes the amount difference in giving the player either a Global Challenge, or a Song Specific challenge.
- The higher the number is to `100`, more chance for Specific Songs.
- The lower the number is to `0`, more chance for Global Songs.
