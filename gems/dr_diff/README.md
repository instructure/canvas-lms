# Dr Diff

Dr Diff is a linter's best friend forever.

Say you want to add rubocop or eslint to your project, but you'd have to fix
a million linter errors throughout your monolithic app for the linter to pass
your commit. Don't worry, Dr Diff is here! He can make your linter run only
on the diff of your commit! That is, only on the files/lines your commit
changed. Huzzah! Now you can polish your app one small piece at a time, saving
your QA friends from:

```
add rubocop, fixes CNVS-1234

test plan:
* regression test the entire app
```

## Usage

```
require "dr_diff"

# Create a manager.
# -- (optional) git_dir (uses cwd by default)
# -- (optional) sha (runs on outstanding changes by default)
dr_diff = DrDiff::Manager.new(git_dir: git_dir, sha: env_sha)

# Collect the files for this change.
# -- (optional) regex to filter results
ruby_files = dr_diff.files(/\.rb$/)

# Collect relevant linter comments.
# -- (required) format
# -- (required) command
# Under the hood, Dr Diff uses Gergich (github.com/instructure/gergich)
# to collect linter comments.
# See github.com/instructure/gergich#gergich-capture-format-command
# for details on format and command parameters.
comments = dr_diff.comments(format: "rubocop",
                            command: "rubocop #{ruby_files.join(' ')}")

# These comments will be objects of the form:
# {
#   path: "/path/to/file.rb",
#   message: "[rubocop] Avoid using sleep.\n\n       sleep 1\n       ^^^^^^^\n",
#   position: 5, # line number
#   severity: "error" # one of %w(error warn info)
# }

# If you are using gergich, you may want him to post these comments via:
if comments.length > 0
  require 'shellwords'
  `gergich comment #{Shellwords.escape(comments.to_json)}`
end

# Take a peek at /script/rlint to see how Canvas uses Dr Diff.
```
