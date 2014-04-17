# ChemLook

ChemLook is a Quick Look plugin that renders chemistry files using [Open Babel](http://openbabel.org) and [ChemDoodle Web Components](http://web.chemdoodle.com).

## Installation

To install the plugin, just drag ChemLook.qlgenerator to `/Library/QuickLook` or `~/Library/QuickLook`. You may need to create that folder if it doesn't already exist.

The Library in your home folder is now hidden by default. To go there, press <kbd title="Command">Command</kbd>-<kbd title="Shift">Shift</kbd>-<kbd title="G">G</kbd> or choose "Go to Folder" from the Go menu, and enter `~/Library`.

The plugin is also installed by default with the related ChemSpotlight plugin, which indexes chemistry files using Open Babel and adds chemical metadata (molecular mass, formula, etc.) to the Finder.

## Dependencies

ChemLook requires Open Babel 2.3+ to be installed. Instructions are available in the [Open Babel documentation](http://openbabel.org/docs/current/Installation/install.html).

## Troubleshooting

It sometimes take Quick Look a while to recognise the new plugin. Try logging out and in again, or alternatively type `qlmanage -r` into the Terminal and press Return.

Quick Look plugins have an order of precedence based on their location. Those in `/Library/QuickLook` will be overridden by those in `~/Library/QuickLook`, which will be overridden by those embedded within specific apps. The ChemDoodle app contains an embedded Quick Look plugin which will override ChemLook for some file formats. If you prefer ChemLook, right-click on the ChemDoodle app, choose "Show Package Contents" and delete "ChemDoodle_QLPlugin.qlgenerator".

## Credits

Thanks [to Nate Gray](http://n8gray.org) for his [QLColorCode](http://code.google.com/p/qlcolorcode) plugin for colorizing source code. I used this as a model for communicating with WebKit and command line programs.

Thanks also to iChemLabs for their excellent JavaScript [ChemDoodle Web Components](http://web.chemdoodle.com). These are used to generate the interactive Quick Look HTML views.
