# Gravity Ace

I'm making a game called Gravity Ace (https://gravityace.com)

This is the Twitch overlay I use when I stream

It depends on https://github.com/MennoMax/gift this addon (MIT) by MennoMax

Have fun, please don't send me pull requests or bug reports but take this and go in peace, traveller.

Thanks!


# Config files

user://commands.json

```json
[
    {
        "command": "battle",
        "help": "Start the battle!",
        "action": "battle",
        "streamer": true
    },
    {
        "command": "reload_commands",
        "help": "Reload commands",
        "action": "reload_commands",
        "streamer": true
    },
    {
        "command": "credit",
        "aliases": ["addtocredits"],
        "help": "Add yourself to the Gravity Ace credits!",
        "action": "addtocredits"
    },
    {
        "command": "discord",
        "help": "Get a discord invite",
        "action": "chat",
        "text": "Here's your Discord invite: ..."
    },
    {
        "command": "commands",
        "help": "You're looking at it",
        "aliases": ["help"],
        "action": "commands"
    },
    {
        "command": "info",
        "help": "About Gravity Ace",
        "action": "chat",
        "text": "Hi, I'm working on Gravity Ace! It's a Godot Engine game and you can find out more at https://gravityace.com"
    }
]
```


user://discord.ini

Your Discord channel webhook goes here

```
[discord]

announce_webhook="https://discord.com/api/webhooks/..."
```

user://twitch.ini

```
[twitch]

token="Your Twitch token here"
channel="jotson"
```