#!/usr/bin/env node

/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

// yarn-validate-workspace-deps.js: ensure that any explicit dependency on a
// local workspace package is specified using the free-range specifier "*" so
// that yarn cannot be tricked into retrieving the package from a remote
// registry in case the package's local version can no longer satisfy the
// requested one
//
// USAGE:
//
//     yarn --silent workspaces info --json |
//     node script/yarn-validate-workspace-deps.js
//
// consider the following case:
//
//     // file: package.json
//     {
//       "name": "canvas-lms",
//       "workspaces": {
//         "packages": [ "packages/*" ]
//       },
//       "dependencies": {
//         "get-cookie": "^1"
//       }
//     }
//
//     // file: packages/get-cookie/package.json
//     {
//       "name": "get-cookie",
//       "version": "2.0"
//     }
//
// since "get-cookie" got bumped up to 2 but consumer package.json is still
// requesting ^1, yarn will attempt to retrieve get-cookie@^1 from the remote
// registry, and we don't necessarily own that, which is a potential attack
// vector
//
// instead, we can guarantee that yarn will use whatever version the workspace
// package is providing by using a free specifier like "*"
//
// see SEC-4437
const path = require('path')
const fg = require('fast-glob')

const root = path.resolve(__dirname, '..')
const pMap = require('p-map')

async function main() {
  const workspaces = await parseWorkspacesFromStdin()

  console.log('Workspaces parsed successfully')

  let errors = []

  const pkgfiles = scanPkgfiles(require.resolve('../package.json'))

  console.log(`Found ${pkgfiles.length} package files to process`)

  if (pkgfiles.length === 0) {
    console.log('No package files found, exiting...')
    return
  }

  // Use concurrency for faster validation
  errors = await pMap(
    pkgfiles,
    async (pkgfile, index) => {
      const result = await validate({pkgfile, workspaces})
      return result
    },
    {concurrency: 10}
  ) // You can adjust the concurrency to fit your system

  console.log('Validation complete')

  // Flatten the array of errors
  errors = errors.flat()

  if (errors.length) {
    process.exitCode = 1
    console.log('dependencies listed below must have a specifier of "*"')
    console.log('---')

    for (const error of errors) {
      console.log('%s:%s', path.relative(root, error.pkgfile), error.dep)
    }

    console.log('---')
  } else {
    console.log('No errors found.')
  }
}

function scanPkgfiles(rootpkgfile) {
  console.log('Scanning package files...')
  let pkgfiles = [rootpkgfile]

  // eslint-disable-next-line import/no-dynamic-require
  for (const pattern of require(rootpkgfile).workspaces.packages || []) {
    console.log(`Scanning pattern: ${pattern}`)
    pkgfiles = pkgfiles.concat(
      fg.sync(`${pattern}/package.json`, {
        cwd: path.dirname(rootpkgfile),
        absolute: true,
      })
    )
  }

  console.log(`Found ${pkgfiles.length} package files`)
  return pkgfiles
}

async function validate({pkgfile, workspaces}) {
  console.log(`Validating package: ${pkgfile}`)

  // eslint-disable-next-line import/no-dynamic-require
  const {dependencies = {}} = require(pkgfile)
  const errors = []

  let depcount = 0

  for (const [dep, version] of Object.entries(dependencies)) {
    if (dep in workspaces) {
      depcount += 1

      if (version !== '*') {
        errors.push({pkgfile, dep})
      }
    }
  }

  if (depcount > 0) {
    console.error(
      'found %d workspace package dependencies and %d errors -- "%s"',
      depcount,
      errors.length,
      path.relative(root, pkgfile)
    )
  } else {
    console.error('found no workspace package dependencies -- "%s"', path.relative(root, pkgfile))
  }

  return errors
}

async function read(stream) {
  const chunks = []
  for await (const chunk of stream) {
    chunks.push(chunk)
  }

  const result = Buffer.concat(chunks).toString('utf8')
  return result
}

async function parseWorkspacesFromStdin() {
  console.log('Parsing workspaces from stdin...')
  const buffer = await read(process.stdin)
  const parsed = JSON.parse(buffer)

  // yarn 1.19.1, which is what jenkins is on, has a different output structure
  // that looks like this:
  //
  //     {
  //       "type": "log",
  //       "data": "{\"json\":\"blob\"}"
  //     }
  //
  // while yarn 1.22.1 directly emits the data with no metadata:
  //
  //     {
  //       "json": "blob"
  //     }
  //
  if (parsed.type === 'log' && parsed.hasOwnProperty('data')) {
    console.log('Detected yarn 1.19.1 log format')
    return JSON.parse(parsed.data)
  } else {
    console.log('Detected yarn 1.22.1 or other log format')
    return parsed
  }
}

console.log('Validating workspace dependencies...')
main()
