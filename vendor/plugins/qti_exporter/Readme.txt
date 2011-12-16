The QTI converter won't work unless you have the Python QTI 1.2 to QTI 2.1 converter installed

The plugin will first check to see if the python app is in
"RAILS_ROOT/vendor/QTIMigrationTool"
We generally have the QTIMigrationTool checked out somewhere on the system and symlink
that to the expected directory

If the QTIMigrationTool isn't in that location the plugin will just try to run the
executable and see if it works. So if you have the QTIMigrationTool in your system
path it will work as well.
