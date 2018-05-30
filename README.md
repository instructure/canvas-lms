Beyond Z Canvas LMS
======

How to install:
-----

Follow the instructions from the [Canvas wiki](https://github.com/instructure/canvas-lms/wiki/Quick-Start)

You may also want to set up a virtual machine with Ubuntu dedicated to Canvas, as it requires some specific versions and a separate VM just makes it easier to manage without conflicts with other stuff installed on your computer. This is suggested in the Canvas wiki under the prerequisities section too and I suggest it too.

When creating the VM, make sure you give it at least 1 GB of RAM or Ubuntu will likely fail to install. The hard drive can be as little as 20 GB. Do a default installation of Ubuntu, then install gcc with `apt-get install gcc` and then follow the quick start guide. The automated script will get most the way.

### Extra Installation Notes: 
* On my box i had to run the i18n thing as  root individually but it should work automatically on other boxes

* I was able to skip a few steps because the ruby for the main platform worked here. If you already have the BZ code running, you should also have ruby and might be able to take a shortcut too.

* If you get:
        
        NameError: method `respond_to_missing?' not defined in ActiveRecord::NamedScope::Scope

  Find: `canvas-lms/config/initializers/rails2.rb:127` and comment that line, uncomment the method below to create the db

* You may need to change config/domain.yml

### Starting the server:
1. Make sure you’re on version 1.9.3 of Ruby.

        $ ruby –v
          ruby 1.9.3p484 (2013-11-22 revision 43786) [x86_64-darwin13.0.2]

2. If not, just run (assuming you have rvm setup):

        $ rvm use 1.9.3

3. Run the following (a different port is used so it won't conflict with the main application):

        bundle exec script/server -p 3001 

If you see:

    script/rails:6:in `require': cannot load such file -- rails/commands (LoadError)

Run:

    bundle show rails

Then change the line of the error (script/rails:6) to:

    require 'PATH_TO_RAILS/lib/commands' 

where `PATH_TO_RAILS` is found in the bundle show command.

BZ Git branch layout
========

    instructure/stable - the cloud version of Canvas that you can signup/pay for at http://www.canvaslms.com/
        \
     beyond-z/stable - beyondz's forked copy
          \
       beyond-z/bz-master - the production branch hosted at https://portal.bebraven.org
            \
         beyond-z/bz-staging - the staging branch hosted at https://stagingportal.bebraven.org
     
## Development Process

*These steps assume that your development environment is setup and working.*

### Get the source code
1. On github, fork this repository to your personal github account, such as: `https://github.com/<yourGithubHandle>/canvas-lms`
2. On your local development environment, clone your forked repository

        $ mkdir <yourSrcDir>; cd <yourSrcDir>
        $ git clone https://github.com/<yourGithubHandle>/canvas-lms.git canvas-lms

### Make a change
1. Create a feature branch from `bz-staging`

        $ git checkout bz-staging
        $ git checkout -b <yourBranch>

2. Make your code changes, test them locally, and commit them to `<yourBranch>`.

### Deploy changes to staging
1. Push your commits to github

        $ git push origin <yourBranch>

2. Open a pull request against `bz-staging`

3. Have your pull request reviewed, merged, and pushed to the [staging](https://stagingportal.bebraven.org) server.
   1. Command to deploy to staging if you have privileges

          `bundle exec cap staging deploy`

4. Have the changes tested on staging

### Deploy changes to production

1. When a set of changes on staging is ready for a production release, merge the `bz-staging` branch into `bz-master`
   * E.g. assuming that you're running the merge from a clone of the `https://github.com/beyond-z/canvas-lms` repository and *not* your forked repository

            $ git checkout bz-staging 
            $ git pull origin bz-staging
            $ git checkout bz-master
            $ git merge --no-ff bz-staging
              [Commit the merge]
            $ git push origin bz-master
         
2. Deploy to production
   * Command to deploy to production if you have privileges
   
            $ bundle exec cap production deploy --trace &> prod_deploy_<insertDate>.log

## Update BZ Canvas code
These instructions are for pulling changes from Instructure's cloud hosted version of Canvas into the Beyond Z version of Canvas hosted at (https://portal.bebraven.org)

1. Pull changes from `instructure/stable` into `beyond-z/stable`

   * Assuming that you're on a clone of (https://github.com/beyond-z/canvas-lms) and *not* your personal github

            $ git remote add upstream https://github.com/instructure/canvas-lms.git
            $ git checkout stable
            $ git pull origin stable
            $ git pull upstream stable
            $ git tag -a bz-release/<insertDate> -m "Update our fork with Canvas upstream changes"
            $ git push origin stable

2. Merge changes from `stable` into `bz-staging` (same assumption as step 1 about which repo)

        $ git checkout bz-staging
        $ git merge --no-ff stable
        $ git push origin bz-staging
        
3. Do a staging deploy and test everything on the staging server!!
4. Do a normal production release to merge the stable, tested changes back into `bz-master` (from whence it came)

## Submit Pull Request to Instructure
1. Make our change in `bz-staging`, push to `bz-master` as usual.
2. Pull upstream `instructure/master` into `beyond-z/master` so they are in sync.
   * Instructure requires you to submit PRs against master, not stable
3. Merge the change that we want from `beyond-z/bz-master` to `beyond-z/master`.  
4. Submit the pull request from `beyond-z/master` to `instructure/master`.

Notes / Tips / Tricks
=========

* Plugin folders:

        canvas-lms/app/views/plugins
        canvas-lms/lib/canvas/plugins/

* Testing is done in the `/spec` directory.

* `node.js` is apparently used to compile assets

* The basic setup is
	users have accounts in the system
	there's courses in the system
	user accounts are tied to courses via roles which grant them access to various parts

	external service login works by getting info from the other service then doing a
	lookup and create a local account as needed to match it and log them in.

	My strategy is to make BZ an OAuth provider and make Canvas understand it, similarly
	to a FB login. It won't be accepted upstream since BZ isn't big like Facebook but the
	way the existing code works is a series of if/else service!

	git should be able to keep our branch straight though.

	Then, hopefully, we can make it automatically and always use this instead of the built in
	login except for admin stuff, but I haven't gotten to that yet...

	The advantage of this oauth sso is we can then do cross-domain communication with an authenticated
	user - if we do have to iframe the resume app, for instance, we'll know which user is logged in
	without needing them to do a separate manual step.

* npm package installation errors

Occasionally an npm package gets a new version which has a dependency on another npm package that no longer supports our version of npm / node. This will show up in a staging deploy. You'll see an error like
    npm verb stack Error: No compatible version found: someNpmPackage@'>=2.1.1 <3.0.0'
    npm verb stack Valid install targets:
    npm verb stack ["1.0.0","1.0.1","1.1.0","1.1.2","1.1.3","2.0.0","2.0.2","2.0.3","2.1.0"]
To resolve this, you need to track down the npm package with a new version and a breaking dependency. The easiest way to do this is login to production where the last successful npminstall ran and navigate to the app root. Then run ```npm ls --json```. Copy and paste that into a text editor and search for the failing package name. In this case, ```someNpmPackage```. Open up the npm-shrinkwrap.json file and lock the dependencies down to the production versions by copy / pasting the tree starting at the failing package and working up to its root.
	
# The rest is just the original Canvas README contents:

Canvas LMS
======

Canvas is a new, open-source LMS by Instructure Inc. It is released under the
AGPLv3 license for use by anyone interested in learning more about or using
learning management systems.

[Please see our main wiki page for more information](http://github.com/instructure/canvas-lms/wiki)

Installation
=======

Detailed instructions for installation and configuration of Canvas are provided
on our wiki.

 * [Quick Start](http://github.com/instructure/canvas-lms/wiki/Quick-Start)
 * [Production Start](http://github.com/instructure/canvas-lms/wiki/Production-Start)
