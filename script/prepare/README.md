# prepare

There are numerous tasks to execute after checking out a Canvas patchset...
compile assets, migrate database changes, update plugins, etc. Forgetting to do
any one of these may bork your testing, possibly even produce false positives!

Sometimes all you need is the latest master branch of canvas-lms, but you can't
quite recall all the database migration and asset compilation tasks.

`prepare` takes care of all that for you.

## What does it do exactly?

`prepare` will:

1. Make sure you're in a canvas root directory
2. Pull the code changes (either from master or from the patchset you've specified)
3. Update Canvas plugins
4. Check if your Canvas gem dependencies need updating
    * If they do, it will install them for you
5. Migrate any database changes to your development db
6. Migrate any database changes to your test db
7. Install Canvas javascript dependencies if they aren't already installed
8. Compile CSS and Javascript
9. Make you happy :smiley:

It can also nuke your Javascript dependencies, force re-install them, and more.
See the full feature list below.

## What does it NOT do?

We assume the following:

  - you've already installed Postgres (postgresapp.com is an excellent option
    for Mac users)
  - postgres is running
  - you've already installed Node.js
  - you've already installed Yarn

## Setup

Add a symlink to `prepare` in your /usr/local/bin/ directory, like so:

```bash
$ cd canvas-lms/script/prepare/
$ ln -s $(pwd)/prepare /usr/local/bin/prepare
```

You're all set!

## How do I use it?

This works just like Portals. To checkout a specific patchset, copy its unique
ID from gerrit. Then execute:

```bash
$ prepare <commit_id>
```

For example:
```bash
$ prepare 89/12345/67
```

Or, if you just want to checkout master, do this:
```bash
$ git checkout master
$ prepare
```

You might encounter problems with some Ruby dependencies. The ["Dependency
Installation" section](https://github.com/instructure/canvas-lms/wiki/Quick-Start#dependency-installation)
in the public Canvas LMS Github wiki has some useful tips.

## What else can it do for me?

Let's say you've branched off master and committed code changes. Now you want to
test your changes against the latest Canvas code base on master before you push
your code for review.

You can easily `git pull --rebase` (provided you've already done
`git branch --set-upstream-to=origin/master`), but what if there have been
database, gem, or css changes since you branched?

You can update all those manually. Or you can let `prepare` do it for you.

Simply:
```bash
$ prepare
```

It will `git pull --rebase`, then update your database, compile css, etc.
(Again, see the "What does it do exactly?" section above for details.)

NOTE: `prepare` won't execute `git branch --set-upstream-to=origin/master` for
you. It assumes you've already set your branch's upstream to the desired remote
branch.

## Features

Current and planned:

- [x] Keeps a log of processes and any errors
- [x] Updates your Canvas codebase, including plugins, gems, and node packages
- [x] Performs database migrations on both development and test databases
- [x] Compiles assets (css and javascript)
- [x] Starts or restarts `powder` if you have it installed and linked to Canvas
- [x] Supports `git checkout`
- [x] Supports updating your current branch off master
- [x] Supports nuking your Canvas node_modules, i.e. `rm -rf node_modules && npm install`
- [x] Supports a fresh installation of Javascript dependencies (useful for new Canvas setups)
- [ ] Supports `git cherry-pick`
- [ ] Supports a "quick" option, i.e. skipping asset compilation entirely
- [ ] Run delayed jobs in the background

## Code Credit

Much of this code is borrowed from [one of Canvas' update scripts](https://github.com/instructure/canvas-lms/blob/stable/script/canvas_update).
I simply added a couple features and repurposed it for Canvas QA folks who are
likely accustomed to the Portals checkout flow.
