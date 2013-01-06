Rift HUD Experience, Currency and Achievement Counter
==========

Window to display the current amounts of all currencies and experience in Rift.
Shows changes to currency and experience since last counter reset. Progress in
achievements are displayed at the bottom of the counter window.

Installation
==========

First locate Rift's addon directory:
-----

1. From rift activate the main menu by pressing the 'esc' key.
2. Click on the `Addons` button.
3. Click on the `Open Addons Directory` button.

Second clone the repo:
-----

- Open the command prompt and navigate to the addons directory.
  - `git clone git://github.com/delphian/rift-hud-counter.git`
  - `cd AOMCounter`
  - `git submodule init`
  - `git submodule update`

Third enable the addon:
-----

Now restart Rift, refresh the addons and enable the HUD Counter.
__You may need to restart Rift one more time__.

Usage
=====

- Start the counter: `/aom init`
- Reset the counters: `/aom reset`
- Show the counter `/aom show`

Errors
=====

Please report all errors, installation problems, or suggestions to
https://github.com/delphian/rift-hud-counter/issues/new

Rift Lua API Documentation
=====
- http://forums.riftgame.com/rift-general-discussions/addon-api-development/
- http://pastebin.com/Ra9pix1k
- http://www.seebs.net/rift/live/index.html
- http://wiki.riftui.com/Main_Page
