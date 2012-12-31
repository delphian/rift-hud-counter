AOMCounter
==========

Small window that displays the current amounts of all currencies and experience in Rift. 
Any achievements you progress in while playing will be posted in the console chat.


Installation
==========

First locate Rift's addon directory:
-----

1. From rift activate the main menu by pressing the 'esc' key.
2. Click on the `Addons` button.
3. Click on the `Open Addons Directory` button.

If you use git (the good way):
-----

- Open the command prompt.
  - Click on the windows start button.
  - Select `run` and type `command` then hit enter. _OR_ type `command` in the search box and select `command prompt` when displayed.
- Navigate to the Rift addon directory. The `delphian` in the following command must
  replaced with your username on the computer. You can find what this path should really
  look like by examining the path in the folder that was opened when you clicked on the
  `Open Addons Directory` while in Rift.

    cd C:\Users\delphian\Documents\RIFT\Interface\Addons

- Once in the Rift addons directory issue following commands:

    git clone git://github.com/delphian/AOMCounter.git
    cd AOMCounter
    git submodule init
    git submodule update

Or, download the zip files and extract (the bad way):
-----

__Step 1:__
- Download https://github.com/delphian/AOMCounter/archive/master.zip 
- Extract the first zip file into the addon folder, this will create a `AOMCounter-master` folder.
  - From your browser show the `AOMCounter-master.zip` file, select `show in folder`.
  - Drag and drop the `AOMCounter-master.zip` file into the Rift addon folder.
  - Right click on the `AOMCounter-master.zip` file and select `extract here`. 
- Rename the newly created `AOMCounter-master` to `AOMCounter`.
  - Right click on the `AOMCounter-master` folder and select `rename`.
  - Type in `AOMCounter` and hit enter.
- Enter the `AOMCounter` folder. Double click on the folder to do this. 
- Delete the `AOMRift` folder that resides in `AOMCounter`.
  - Right click on the `AOMRift` folder and select `delete`.

__Step 2:__
- Download https://github.com/delphian/AOMRift/archive/master.zip
- Extract the second zip file into the `AOMCounter` folder, this will create a `AOMRift-master` folder.
  - From your browser show the `AOMRift-master.zip` file, select `show in folder`.
  - Drag and drop the `AOMRift-master.zip` file into the `AOMCounter` folder.
  - Right click on the `AOMRift-master.zip` file and select `Extract here`.
- Rename the newly created `AOMRift-master` folder to `AOMRift`
  - Right click on the `AOMRift-master` folder and select `rename`.
  - Type in `AOMRift` and hit enter.

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

Please report all errors, installation problems, or suggestions to
https://github.com/delphian/AOMCounter/issues/new
