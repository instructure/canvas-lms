# Gems

This folder is a place to extract modular functionality from
canvas.  Canvas's Gemfile arrangement is enabled to read gems
from this path locally without installing from a remote source. This is valuable for a few reasons:
  - it prevents circular dependencies (bundler won't allow it)
  - modularized code cannot bind to specific domain concepts on canvas models
  - gems can have their specs run independently, without needing to load all
     of canvas, saving iteration time
  - it allows for eventual build optimization via only running specs for the
    transitive closure of parents depending on a gem where a change is.

There are some tradeoffs:
  - spreads canvas over more subdirectories, giving some mental overhad to traversing
     the entire codebase.
  - modular tests necessarily don't test integration with canvas concepts, so solid        integration tests in the app are still a requirement.
  - total SERIALIZED build time goes up because each gem loads it's specs in a new process rather than all running within an already booted canvas process.

[TODO] eventually write more on whether we feel like those tradeoffs are good ones,
and what the best practices are to leverage this pattern for max-gain/min-pain.

## Testing

To test all the gems:
```
cd gems
./test_all_gems.sh
```


### To test an individual gem

Run `./test.sh` inside the gem's folder. This is _basically_ the same as:

```bash
cd gems/google_drive
bundle
rspec
```


