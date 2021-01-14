#!/usr/bin/env node

/*
 * Copyright (C) 2021 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// this is a continuation of hacks trying to get bundlers and packages and Node
// to play together.. for more context, read the history of this file before this
// paragraph was inserted
//
// https://github.com/instructure/canvas-lms/blob/a20e69ecc99b7f775c0c2877bc76b6fa5689b6d8/script/fix_inst_esm.sh
// ---
//
// just because the root package.json contains the "exports" property, and
// although it was tuned[1] to specify entry points for both require() and
// import() consumers, it also had the effect of denying any require() to
// files NOT specified in the "exports" map!!! this is totally out of scope
// with the proposed change as it means that the authors need to either:
//
// - opt out of using "exports" in their package.json (ALONG WITH "type": "module")
// - explicitly list every file and symbol that may be consumed, i have NO idea
//   what Node.js is thinking by not allowing an incremental adoption of this
//   feature, but it is what it is (and FWIW, specifying {"./*": "./*"} for an
//   export, as is stated in the documentation, doesn't have the advertised
//   effect -- not for us at least, nor does "exports": null)
//
// example of a package after the fix:
//
//     node_modules/@instructure/ui-a11y-content/
//     ├── README.md
//     ├── es
//     │   ├── index.js
//     │   └── package.json # { "type": "module" }
//     ├── lib
//     │   ├── index.js
//     │   └── package.json # { "type": "commonjs" }
//     ├── package.json     # { -"type", -"exports", ... }
//     └── src
//        └── index.js
//
// to test if this workaround is still necessary, undo its effects (e.g. purge
// and reinstall node modules) and then try to run the mocha tests of canvas-rce
//
// [1]: https://github.com/instructure/instructure-ui/pull/301
// [2]: https://nodejs.org/api/packages.html#packages_package_entry_points

const fg = require('fast-glob')
const fs = require('fs')
const path = require('path')

const exists = fs.existsSync
const write = fs.promises.writeFile
const program = path.basename(process.argv[1])
const glob = async = pattern => fg.stream(pattern, {
  absolute: true,
  stats: false,
  followSymbolicLinks: true,
})

const main = async () => {
  for await (const pkgfile of glob('**/node_modules/**/@instructure/*/package.json')) {
    const pkg = require(pkgfile)

    if (!pkg.name || !pkg.name.startsWith('@instructure/') || pkg.type !== 'module') {
      continue
    }

    const pkgdir = path.dirname(pkgfile)

    if (exists(`${pkgdir}/es`) && !exists(`${pkgdir}/es/package.json`)) {
      await write(`${pkgdir}/es/package.json`, '{"type":"module"}', 'utf8')
    }

    if (exists(`${pkgdir}/lib`) && !exists(`${pkgdir}/lib/package.json`)) {
      await write(`${pkgdir}/lib/package.json`, '{"type":"commonjs"}', 'utf8')
    }

    const modded = Object.assign({}, pkg)

    delete modded.exports
    delete modded.type

    await write(pkgfile, JSON.stringify(modded, null, 2) + '\n', 'utf8')

    console.log('%s: patched -- %s', program, path.relative(process.cwd(), pkgfile))
  }
}

main()
