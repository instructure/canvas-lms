#!/usr/bin/env bash

# @instructure/ packages have a packaging problem that appears in Node 12.5+
# where ESM support is natively supported without a flag: the packages specify
# {"type": "module"} in the *root* package.json that makes Node treat everything
# under that tree as ES modules, even files inside the lib/ directory, which
# are CommonJS modules, and that is undesirable
#
# until we fix this upstream, which may take some time as we still have to
# upgrade to inst-ui@^7 in some cases and it's unlikely we can backport the
# packaging fix to inst-ui@^6, we adopt the following workaround where we
# write a package.json inside the lib/ directory that undoes what the root
# package.json is doing around specifying the module type
#
# example of a package after the fix:
#
#     node_modules/@instructure/ui-a11y-content/
#     ├── README.md
#     ├── es
#     │   └── index.js
#     ├── lib
#     │   ├── index.js
#     │   └── package.json # { "type": "commonjs" }
#     ├── package.json     # { "type" "module" }
#     └── src
#        └── index.js
#
# to test if this workaround is still necessary, undo its effects (e.g. purge
# and reinstall node modules) and then try to run the mocha tests of canvas-rce

for pkg in $(find . -type f -wholename '*/@instructure/*/package.json'); do
  read -r pkgdir < <(dirname "$pkg")

  # @instructure/ packages provide their dist "lib" dir at the root
  if [[ ! -d $pkgdir/lib ]]; then
    continue
  fi

  # we only want @instructure/ packages:
  grep -qE '"name":\s*"@instructure/' $pkg || continue
  # and ones that mark *all* their output as ESM:
  grep -qE '"type":\s*"module"' $pkg || continue

  libpkg="$pkgdir/lib/package.json"

  # if there's already a package.json in the lib directory, there's nothing
  # we can (or should, hopefully?) do
  if [[ -f $libpkg ]]; then
    echo "$0: nothing to do as package.json already exists in lib/ -- $pkg" >&2
    continue
  fi

  echo '{"type":"commonjs"}' > $libpkg || {
    echo "$0: unable to write file $libpkg"
    exit 1
  }

  echo "$0: written $libpkg"
done
