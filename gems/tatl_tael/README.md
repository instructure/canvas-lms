# TatlTael

TatlTael provides linting on the commit as a whole.

## Usage

```
require "tatl_tael"

linter = TatlTael::Linter.new(git_dir: git_dir)

linter.ensure_specs do
  puts "this will be printed if there are ruby additions or modifications,"\
       " but no spec additions or modifications."
end
```


