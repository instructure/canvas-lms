Canvas LMS
======

Canvas is a modern, open-source [LMS](https://en.wikipedia.org/wiki/Learning_management_system)
developed and maintained by [Instructure Inc.](https://www.instructure.com/) It is released under the
AGPLv3 license for use by anyone interested in learning more about or using
learning management systems.

[Please see our main wiki page for more information](http://github.com/instructure/canvas-lms/wiki)

Installation
=======

Detailed instructions for installation and configuration of Canvas are provided
on our wiki.

 * [Quick Start](http://github.com/instructure/canvas-lms/wiki/Quick-Start)
 * [Production Start](http://github.com/instructure/canvas-lms/wiki/Production-Start)

### Notes for Arm Mac

#### The following are dependencies that can be installed via homebrew:
* Ruby Dependencies: `brew install gmp libyaml`
* Canvas specific dependencies: `brew install getsentry/tools/sentry-cli libidn libxmlsec1`
* Needed for running tests: `brew --cask chromedriver`

* canvas has `idn-ruby` as a dependency which requires libidn, which you can get
  via homebrew, but bundler does not know how to find it. This can be fixed by
  running: `bundle config set --global build.idn-ruby --with-idn-dir=$(brew --prefix libidn)`

#### If you use Postgres.app (`brew install postgres-unofficial`)
Postgres.app makes running and managing postgres servers locally, easy
.
* Make sure that you put `/Applications/Postgres.app/Contents/Versions/latest/bin` in your `$PATH`

* For setting up the database, create a Postgres-14 server in the app, it will create a  data directory in `~/Library/Application\ Support/Postgres/var-14/` with a few databases. Go into `template1` and use `\list` to ensure the character encodings are correct, the Canvas instructions set encoding to `utf8`. The encoding should match that and collation as well as ctype are at `en_US.UTF-8`. When copying `config/database.yml`, if you remove the username and password from `development` and `test`. `rails db:create` should just create them with your local user as the owner, without needing to alter DB permissions.

#### If you use ASDF
ASDF is a multi-language version manager similar to rbenv, it modifies the shell by swapping links in the `$ASDF_DIR/shims` directory, which if its in your `$PATH` ensures you are using the current language versions and tools.

* You will need the nodejs and ruby asdf plugins.
* ASDF depends on `brew install coreutils curl`
* I installed via asdf's shell script, not homebrew as I found it has less issues.
* The `.tool-versions` file should have the correct pinned versions. Running `asdf install` should grab both.

#### If Ruby LSP fails to load ()

If you get this error:
```
bundler-multilock`, due to Bundler::Plugin::MalformattedPlugin (plugins.rb
was not found in the plugin.)
```

Its because the gem is referenced in `vendor`, however `ruby-lsp` makes its own
`Gemfile` in `.ruby-lsp/`, hence run `cd .ruby-lsp; ln -s ../vendor vendor` to copy the vendored
plugin to solve this issue.
