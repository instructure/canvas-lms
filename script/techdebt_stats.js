/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

const path = require('node:path')
const {promisify} = require('node:util')
const {exec, execSync} = require('node:child_process')

const execAsync = promisify(exec)

const projectRoot = path.resolve(__dirname, '..')

const colors = {
  reset: '\x1b[0m',
  cyan: '\x1b[36m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  gray: '\x1b[90m',
  white: '\x1b[37m',
  bold: '\x1b[1m',
}

const colorize = (color, text) => `${colors[color]}${text}${colors.reset}`
const bold = text => colorize('bold', text)

const normalizePath = filePath => filePath.replace(/\/+/g, '/')

async function countAndShowRandomFile(searchPattern, description) {
  try {
    // Use git ls-files to only get tracked files, then filter by pattern
    const {stdout} = await execAsync(
      `git ls-files "ui/" "packages/" | grep -E "${searchPattern}"`,
      {cwd: projectRoot}
    )
    const files = stdout.trim().split('\n').filter(Boolean)
    const fileCount = files.length

    if (fileCount > 0) {
      console.log(colorize('yellow', `- ${description}: ${bold(fileCount)}`))
      const randomFile = normalizePath(files[Math.floor(Math.random() * fileCount)])
      console.log(colorize('gray', `  Example: ${randomFile}`))
    } else {
      console.log(colorize('yellow', `- ${description}: ${colorize('green', 'None')}`))
    }
  } catch (error) {
    console.error(colorize('red', `Error searching for ${description}: ${error.message}`))
  }
}

async function countTsSuppressions(type) {
  try {
    const {stdout} = await execAsync(
      `git ls-files "ui/" | grep -E "\\.(ts|tsx)$" | xargs grep -l "@${type}" | wc -l`,
      {cwd: projectRoot}
    )
    return Number.parseInt(stdout.trim(), 10)
  } catch (error) {
    console.error(colorize('red', `Error counting @${type}: ${error.message}`))
    return 0
  }
}

async function getRandomTsSuppressionFile(type) {
  try {
    const {stdout} = await execAsync(
      `git ls-files "ui/" | grep -E "\\.(ts|tsx)$" | xargs grep -l "@${type}"`,
      {cwd: projectRoot}
    )
    const files = stdout.trim().split('\n').filter(Boolean)
    if (files.length > 0) {
      return normalizePath(files[Math.floor(Math.random() * files.length)])
    }
  } catch (error) {
    console.error(colorize('red', `Error finding @${type} example: ${error.message}`))
  }
  return null
}

async function showTsSuppressionStats(type) {
  const count = await countTsSuppressions(type)
  const randomFile = await getRandomTsSuppressionFile(type)

  console.log(colorize('yellow', `- Total files with @${type}: ${bold(count)}`))
  if (randomFile) {
    console.log(colorize('gray', `  Example: ${randomFile}`))
  }
}

async function countJqueryImports() {
  try {
    const cmd =
      'git ls-files "ui/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "from [\'\\"]jquery[\'\\"]"'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    return Number.parseInt(stdout.trim().split('\n').filter(Boolean).length, 10)
  } catch (error) {
    console.error(colorize('red', `Error counting jQuery imports: ${error.message}`))
    return 0
  }
}

async function getRandomJqueryImportFile() {
  try {
    const cmd =
      'git ls-files "ui/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "from [\'\\"]jquery[\'\\"]"'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    const files = stdout.trim().split('\n').filter(Boolean)
    if (files.length > 0) {
      return normalizePath(files[Math.floor(Math.random() * files.length)])
    }
  } catch (error) {
    console.error(colorize('red', `Error finding jQuery import example: ${error.message}`))
  }
  return null
}

async function showJqueryImportStats() {
  const count = await countJqueryImports()
  const randomFile = await getRandomJqueryImportFile()

  console.log(colorize('yellow', `- Files with jQuery imports: ${bold(count)}`))
  if (randomFile) {
    console.log(colorize('gray', `  Example: ${randomFile}`))
  }
}

async function checkOutdatedPackages() {
  try {
    execSync('npm outdated --json', {
      cwd: projectRoot,
      stdio: ['pipe', 'pipe', 'pipe'],
      encoding: 'utf8',
    }).toString()

    // If we get here, there were no outdated packages
    console.log(
      colorize('yellow', `- Packages outdated by major version: ${colorize('green', 'None')}`)
    )
  } catch (error) {
    // npm outdated exits with code 1 when it finds outdated packages
    if (error.stdout) {
      try {
        const outdatedData = JSON.parse(error.stdout)
        const majorOutdated = []

        for (const packageName in outdatedData) {
          const pkg = outdatedData[packageName]
          // Skip if we don't have all the version information
          if (!pkg.current || !pkg.latest) continue

          const currentMajor = Number.parseInt((pkg.current || '0').split('.')[0], 10)
          const latestMajor = Number.parseInt((pkg.latest || '0').split('.')[0], 10)

          if (
            !Number.isNaN(currentMajor) &&
            !Number.isNaN(latestMajor) &&
            latestMajor > currentMajor
          ) {
            majorOutdated.push({
              packageName,
              current: pkg.current,
              wanted: pkg.wanted || pkg.current,
              latest: pkg.latest,
            })
          }
        }

        if (majorOutdated.length > 0) {
          console.log(
            colorize(
              'yellow',
              `- Packages outdated by major version: ${bold(majorOutdated.length)}`
            )
          )
          const randomPackage = majorOutdated[Math.floor(Math.random() * majorOutdated.length)]
          console.log(
            colorize(
              'gray',
              `  Example: ${randomPackage.packageName} (current: ${randomPackage.current}, wanted: ${randomPackage.wanted}, latest: ${randomPackage.latest})`
            )
          )
        } else {
          console.log(
            colorize('yellow', `- Packages outdated by major version: ${colorize('green', 'None')}`)
          )
        }
      } catch (parseError) {
        console.error(colorize('red', `Error parsing npm outdated output: ${parseError.message}`))
      }
    } else {
      console.error(colorize('red', `Error running npm outdated: ${error.message}`))
    }
  }
}

async function countTestFiles() {
  try {
    // Find both *Spec.js* and *.test.js* files
    const {stdout} = await execAsync(
      `git ls-files "ui/" "packages/" | grep -E "Spec\\.(js|jsx)$"`,
      {cwd: projectRoot}
    )
    const files = stdout.trim().split('\n').filter(Boolean)
    const fileCount = files.length

    if (fileCount > 0) {
      console.log(colorize('yellow', `- Total test files: ${bold(fileCount)}`))
      const randomFile = normalizePath(files[Math.floor(Math.random() * fileCount)])
      console.log(colorize('gray', `  Example: ${randomFile}`))
    } else {
      console.log(colorize('yellow', `- Total test files: ${colorize('green', 'None')}`))
    }
  } catch (error) {
    console.error(colorize('red', `Error counting test files: ${error.message}`))
  }
}

async function countReactDomRenderFiles() {
  try {
    // Find files containing ReactDOM.render
    const {stdout} = await execAsync(
      `git ls-files "ui/" "packages/" | xargs grep -l "ReactDOM.render"`,
      {cwd: projectRoot}
    )
    const files = stdout.trim().split('\n').filter(Boolean)
    const fileCount = files.length

    if (fileCount > 0) {
      console.log(colorize('yellow', `- Total files with ReactDOM.render: ${bold(fileCount)}`))
      const randomFile = normalizePath(files[Math.floor(Math.random() * fileCount)])
      console.log(colorize('gray', `  Example: ${randomFile}`))
    } else {
      console.log(colorize('yellow', `- Total files with ReactDOM.render: ${colorize('green', 'None')}`))
    }
  } catch (error) {
    if (error.code === 1 && !error.stdout) {
      // grep returns exit code 1 when no matches are found
      console.log(colorize('yellow', `- Total files with ReactDOM.render: ${colorize('green', 'None')}`))
    } else {
      console.error(colorize('red', `Error counting ReactDOM.render files: ${error.message}`))
    }
  }
}

async function printDashboard() {
  console.log(bold(colorize('green', '\nTech Debt Summary\n')))

  console.log(
    `${bold(colorize('white', 'Handlebars Files'))} ${colorize('gray', '(convert to React)')}`
  )
  await countAndShowRandomFile('.handlebars$', 'Total Handlebars files')
  console.log('')

  console.log(
    `${bold(colorize('white', 'JQuery Imports'))} ${colorize('gray', '(use native DOM)')}`
  )
  await showJqueryImportStats()
  console.log('')

  console.log(
    `${bold(colorize('white', 'QUnit Test Files'))} ${colorize('gray', '(convert to Jest)')}`
  )
  await countTestFiles()
  console.log('')

  console.log(
    `${bold(colorize('white', 'ReactDOM.render Files'))} ${colorize('gray', '(convert to createRoot)')}`
  )
  await countReactDomRenderFiles()
  console.log('')

  console.log(
    `${bold(colorize('white', 'JavaScript Files'))} ${colorize('gray', '(convert to TypeScript)')}`
  )
  await countAndShowRandomFile('.(js|jsx)$', 'Total JavaScript files')
  console.log('')

  console.log(bold(colorize('white', 'TypeScript Suppressions')))
  await showTsSuppressionStats('ts-nocheck')
  await showTsSuppressionStats('ts-ignore')
  await showTsSuppressionStats('ts-expect-error')

  console.log(bold('\nOutdated Packages\n'))
  await checkOutdatedPackages()
}

printDashboard().catch(error => {
  console.error(colorize('red', `Error: ${error.message}`))
  process.exit(1)
})
