# MTInfusion

Uses a list of targest to track and handout PIs. The color of the target's background indicates if target is out of range (orange), on CD (red), off CD and not requested (yellow) or off CD and requested (green). Also has an "LOS" button to whisper the target that you cant cast PI at the moment 

When you click on a target, auto casts PI and whispers the target to let them know

Also:
1. Makes an alert noise when someone whispers you the word "PI" (and adds them to a list of targets if not present).
2. If PI is not yet up, whispers back what the cooldown is
3. Everytime PI comes off CD, whispers the last person who asked for PI to let them know (OR whispers your prio target if set)
4. allows you to manually add/remove/prio slash commands to manually add/remove players (or your target) to the list and to prio a certain player (so that you always whisper them rather than your last target)

Note that due to blizzard anti-botting contraints, adding and removing targets will only be performed once you exit combat.


# Commands
 <code>/mtpi - show commands</code>
 
 
 
 <code>/mtpi add Village - adds the player "Village" to the list of players </code>
 
 <code>/mtpi add target - adds your current target to the list of players </code>



 <code>/mtpi prio Village - sets the player "Village" as your priority target (will whisper them when PI is up rather than the last person to ask)</code>



 <code>/mtpi remove Village - removes the player "Village" from the list of players (and their priority) </code>
 
 <code>/mtpi remove target - removes your current target from the list of players (and their priority) </code>



