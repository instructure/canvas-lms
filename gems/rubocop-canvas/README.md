# Rubocop::Canvas

This is an extension of the RuboCop gem that provides some extra linters
("cops") that might be handy, and that provides a neat way to do
inline commenting in gerrit as a result of linted source

## Usage

### At Instructure
You don't really have to do anything if you're at Instructure!
The linter runs automatically on the CI server, using the diff-tree from the
HEAD commit to decide what files to look at.  Then it takes the linted warnings,
compares them to the lines you changed
(based on chunk headers in "git show"), and posts them as inline gerrit
comments via gergich.

### No CI Server?
No problem, you can still benefit from rubocop-canvas.  In the
"script" directory of canvas-lms, there's a little glue code called
"rlint", just an executable that does some git-fu to get the right
files, and then will print out linting information for your most
recent change right to your console.   Fix and repeat. :)

## Modifying Rubocop::Canvas
You may have several ideas of things you want to do:

#### Turn off a linter for a given directory
It doesn't make sense to lint database migrations as aggressively
as the rest of the source code, for example, so with the config file
in "db/migrate/.rubocop.yml" we turn off several linters that we might still
want elsewhere

#### Turn off a given cop everywhere
Are you sure you aren't just frustrated at how much messy code you've written?
;)  Ok, ok, you can screw with the config file in the root directory of
canvas-lms (".rubocop.yml") there are already examples in there of linters
that have been disabled because they're just too much noise.

#### Add my own cop!
Have you discovered some new thing that we should try to detect automatically
from now on?  Have a look at "freeze_constants.rb" in this project, you could
build something similar for whatever it is you need.  Checkout
all the callbacks that are available for Cops at https://github.com/bbatsov/rubocop,
don't forget to write specs!

Also, don't forget to enable your new cop by default in "config/default.yml"
