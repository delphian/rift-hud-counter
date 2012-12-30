AOMCounter
==========

Small window that displays the current amounts of all currencies and experience in Rift.

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

Extract the first file into the addon directory. Create a subdirectory inside
AOMCounter named AOMRift and extract the second file into the AOMRift directory.

Enable the addon:
-----

Now restart Rift, refresh the addons and enable the AOMCounter. You may need to restart
Rift one more time.

Usage
=====

Start the addon

    /aom init

Reset the counters:

    /aom reset