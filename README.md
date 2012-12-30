AOMCounter
==========

Small window that displays the current amounts of all currencies and experience in Rift. 
Any achievements you progress in while playing will be posted in the console chat.


Installation
==========

First locate Rift's addon directory:
-----

1. From rift activate the main menu by pressing the 'esc' key.
2. Click on the "Addons" button.
3. Click on the "Open Addons Directory" button.

If you use git (the good way):
-----

Issue following commands in Rift's addon directory:

    git clone
    cd AOMCounter git://github.com/delphian/AOMCounter.git
    git submodule init
    git submodule update

Or, download the zip files and extract (the bad way):
-----

Two zip files must be downloaded:
- https://github.com/delphian/AOMCounter/archive/master.zip
- https://github.com/delphian/AOMRift/archive/master.zip

Extract the files:
- Extract the first file into the addon directory. 
- Rename the created folder to AOMCounter
- Enter the AOMCounter folder.
- Delete the AOMRift subfolder.
- Extract the second file into the AOMCounter folder.
- Rename the created subfolder to AOMRift

Enable the addon:
-----

Now restart Rift, refresh the addons and enable the AOMCounter. __You may need to restart
Rift one more time__.

Usage
=====

Start the addon:

    /aom init

Reset the counters:

    /aom reset

Errors
=====

Please report all errors or installation problems to
https://github.com/delphian/AOMCounter/issues/new
