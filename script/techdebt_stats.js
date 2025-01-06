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
      {cwd: projectRoot},
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
      {cwd: projectRoot},
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
      {cwd: projectRoot},
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

async function countSinonImports() {
  try {
    const cmd =
      'git ls-files "ui/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "from [\'\\"]sinon[\'\\"]"'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    return Number.parseInt(stdout.trim().split('\n').filter(Boolean).length, 10)
  } catch (error) {
    console.error(colorize('red', `Error counting Sinon imports: ${error.message}`))
    return 0
  }
}

async function getRandomSinonImportFile() {
  try {
    const cmd =
      'git ls-files "ui/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "from [\'\\"]sinon[\'\\"]"'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    const files = stdout.trim().split('\n').filter(Boolean)
    if (files.length > 0) {
      return normalizePath(files[Math.floor(Math.random() * files.length)])
    }
  } catch (error) {
    console.error(colorize('red', `Error finding Sinon import example: ${error.message}`))
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

async function showSinonImportStats() {
  const count = await countSinonImports()
  const randomFile = await getRandomSinonImportFile()

  console.log(colorize('yellow', `- Files with Sinon imports: ${bold(count)}`))
  if (randomFile) {
    console.log(colorize('gray', `  Example: ${randomFile}`))
  }
}

async function countSkippedTests() {
  try {
    const {stdout: itSkipStdout} = await execAsync(
      `git ls-files "ui/" "packages/" | xargs grep -l "it\\.skip("`,
      {cwd: projectRoot},
    )
    const {stdout: describeSkipStdout} = await execAsync(
      `git ls-files "ui/" "packages/" | xargs grep -l "describe\\.skip("`,
      {cwd: projectRoot},
    )

    const itSkipFiles = itSkipStdout.trim().split('\n').filter(Boolean)
    const describeSkipFiles = describeSkipStdout.trim().split('\n').filter(Boolean)

    // Combine and deduplicate files
    const allFiles = [...new Set([...itSkipFiles, ...describeSkipFiles])]
    const fileCount = allFiles.length

    if (fileCount > 0) {
      console.log(colorize('yellow', `- Total files with skipped tests: ${bold(fileCount)}`))
      const randomFile = normalizePath(allFiles[Math.floor(Math.random() * fileCount)])
      console.log(colorize('gray', `  Example: ${randomFile}`))
    } else {
      console.log(
        colorize('yellow', `- Total files with skipped tests: ${colorize('green', 'None')}`),
      )
    }
  } catch (error) {
    if (error.code === 1 && !error.stdout) {
      // grep returns exit code 1 when no matches are found
      console.log(
        colorize('yellow', `- Total files with skipped tests: ${colorize('green', 'None')}`),
      )
    } else {
      console.error(colorize('red', `Error counting skipped test files: ${error.message}`))
    }
  }
}

async function checkOutdatedPackages() {
  try {
    const output = execSync('npm outdated --json', {
      cwd: projectRoot,
      stdio: ['pipe', 'pipe', 'pipe'],
      encoding: 'utf8',
    }).toString()
    handleOutdatedPackages(output)
  } catch (error) {
    // npm outdated exits with code 1 when it finds outdated packages
    // This is expected behavior, so we should still try to parse the output
    if (error.stdout) {
      handleOutdatedPackages(error.stdout)
    } else {
      console.error(colorize('red', `Error running npm outdated: ${error.message}`))
      if (error.stderr) {
        console.error(colorize('red', `stderr: ${error.stderr}`))
      }
      if (error.status) {
        console.error(colorize('red', `exit code: ${error.status}`))
      }
      if (error.signal) {
        console.error(colorize('red', `signal: ${error.signal}`))
      }
    }
  }
}

function handleOutdatedPackages(output) {
  if (output.trim()) {
    const outdatedData = JSON.parse(output)
    const majorOutdated = []

    for (const packageName in outdatedData) {
      const pkg = outdatedData[packageName]
      // Skip if we don't have all the version information
      if (!pkg.current || !pkg.latest) continue

      const currentMajor = Number.parseInt((pkg.current || '0').split('.')[0], 10)
      const latestMajor = Number.parseInt((pkg.latest || '0').split('.')[0], 10)

      if (!Number.isNaN(currentMajor) && !Number.isNaN(latestMajor) && latestMajor > currentMajor) {
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
        colorize('yellow', `- Packages outdated by major version: ${bold(majorOutdated.length)}`),
      )
      const randomPackage = majorOutdated[Math.floor(Math.random() * majorOutdated.length)]
      console.log(
        colorize(
          'gray',
          `  Example: ${randomPackage.packageName} (current: ${randomPackage.current}, wanted: ${randomPackage.wanted}, latest: ${randomPackage.latest})`,
        ),
      )
    } else {
      console.log(
        colorize('yellow', `- Packages outdated by major version: ${colorize('green', 'None')}`),
      )
    }
  } else {
    console.log(
      colorize('yellow', `- Packages outdated by major version: ${colorize('green', 'None')}`),
    )
  }
}

async function countReactDomRenderFiles() {
  try {
    // Find files containing ReactDOM.render
    const {stdout} = await execAsync(
      `git ls-files "ui/" "packages/" | xargs grep -l "ReactDOM.render"`,
      {cwd: projectRoot},
    )
    const files = stdout.trim().split('\n').filter(Boolean)
    const fileCount = files.length

    if (fileCount > 0) {
      console.log(colorize('yellow', `- Total files with ReactDOM.render: ${bold(fileCount)}`))
      const randomFile = normalizePath(files[Math.floor(Math.random() * fileCount)])
      console.log(colorize('gray', `  Example: ${randomFile}`))
    } else {
      console.log(
        colorize('yellow', `- Total files with ReactDOM.render: ${colorize('green', 'None')}`),
      )
    }
  } catch (error) {
    if (error.code === 1 && !error.stdout) {
      // grep returns exit code 1 when no matches are found
      console.log(
        colorize('yellow', `- Total files with ReactDOM.render: ${colorize('green', 'None')}`),
      )
    } else {
      console.error(colorize('red', `Error counting ReactDOM.render files: ${error.message}`))
    }
  }
}

async function countReactClassComponentFiles() {
  try {
    // Find files containing class components using both patterns
    const {stdout: reactComponentStdout} = await execAsync(
      `git ls-files "ui/" "packages/" | xargs grep -l "extends React.Component"`,
      {cwd: projectRoot},
    )
    const {stdout: componentStdout} = await execAsync(
      `git ls-files "ui/" "packages/" | xargs grep -l "extends Component"`,
      {cwd: projectRoot},
    )

    const reactComponentFiles = reactComponentStdout.trim().split('\n').filter(Boolean)
    const componentFiles = componentStdout.trim().split('\n').filter(Boolean)

    // Combine and deduplicate files
    const allFiles = [...new Set([...reactComponentFiles, ...componentFiles])]
    const fileCount = allFiles.length

    if (fileCount > 0) {
      console.log(colorize('yellow', `- Total files with class components: ${bold(fileCount)}`))
      const randomFile = normalizePath(allFiles[Math.floor(Math.random() * fileCount)])
      console.log(colorize('gray', `  Example: ${randomFile}`))
    } else {
      console.log(
        colorize('yellow', `- Total files with class components: ${colorize('green', 'None')}`),
      )
    }
  } catch (error) {
    if (error.code === 1 && !error.stdout) {
      // grep returns exit code 1 when no matches are found
      console.log(
        colorize('yellow', `- Total files with class components: ${colorize('green', 'None')}`),
      )
    } else {
      console.error(colorize('red', `Error counting class component files: ${error.message}`))
    }
  }
}

async function countReactStringRefs() {
  try {
    // Use a more specific pattern that looks for ref=" but not href="
    const cmd =
      'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "\\bref=\\"[^\\"]*\\""'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    return Number.parseInt(stdout.trim().split('\n').filter(Boolean).length, 10)
  } catch (error) {
    console.error(colorize('red', `Error counting React string refs: ${error.message}`))
    return 0
  }
}

async function getRandomReactStringRefFile() {
  try {
    // Use same specific pattern as countReactStringRefs
    const cmd =
      'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "\\bref=\\"[^\\"]*\\""'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    const files = stdout.trim().split('\n').filter(Boolean)
    if (files.length > 0) {
      return normalizePath(files[Math.floor(Math.random() * files.length)])
    }
  } catch (error) {
    console.error(colorize('red', `Error finding React string ref example: ${error.message}`))
  }
  return null
}

async function showReactStringRefStats() {
  const count = await countReactStringRefs()
  const randomFile = await getRandomReactStringRefFile()

  console.log(colorize('yellow', `- Files with React string refs: ${bold(count)}`))
  if (randomFile) {
    console.log(colorize('gray', `  Example: ${randomFile}`))
  }
}

async function countPropTypesFiles() {
  try {
    const cmd =
      'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "\\.propTypes\\s*="'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    return Number.parseInt(stdout.trim().split('\n').filter(Boolean).length, 10)
  } catch (error) {
    console.error(colorize('red', `Error counting propTypes files: ${error.message}`))
    return 0
  }
}

async function getRandomPropTypesFile() {
  try {
    const cmd =
      'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "\\.propTypes\\s*="'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    const files = stdout.trim().split('\n').filter(Boolean)
    if (files.length > 0) {
      return normalizePath(files[Math.floor(Math.random() * files.length)])
    }
  } catch (error) {
    console.error(colorize('red', `Error finding propTypes example: ${error.message}`))
  }
  return null
}

async function showPropTypesStats() {
  const count = await countPropTypesFiles()
  const randomFile = await getRandomPropTypesFile()

  console.log(colorize('yellow', `- Files with propTypes: ${bold(count)}`))
  if (randomFile) {
    console.log(colorize('gray', `  Example: ${randomFile}`))
  }
}

async function countDefaultPropsFiles() {
  try {
    const cmd =
      'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "\\.defaultProps\\s*="'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    return Number.parseInt(stdout.trim().split('\n').filter(Boolean).length, 10)
  } catch (error) {
    console.error(colorize('red', `Error counting defaultProps files: ${error.message}`))
    return 0
  }
}

async function getRandomDefaultPropsFile() {
  try {
    const cmd =
      'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "\\.defaultProps\\s*="'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    const files = stdout.trim().split('\n').filter(Boolean)
    if (files.length > 0) {
      return normalizePath(files[Math.floor(Math.random() * files.length)])
    }
  } catch (error) {
    console.error(colorize('red', `Error finding defaultProps example: ${error.message}`))
  }
  return null
}

async function showDefaultPropsStats() {
  const count = await countDefaultPropsFiles()
  const randomFile = await getRandomDefaultPropsFile()

  console.log(colorize('yellow', `- Files with defaultProps: ${bold(count)}`))
  if (randomFile) {
    console.log(colorize('gray', `  Example: ${randomFile}`))
  }
}

async function countEnzymeImports() {
  try {
    const cmd =
      'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "from [\'\\"]enzyme[\'\\"]"'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    return Number.parseInt(stdout.trim().split('\n').filter(Boolean).length, 10)
  } catch (error) {
    console.error(colorize('red', `Error counting Enzyme imports: ${error.message}`))
    return 0
  }
}

async function getRandomEnzymeImportFile() {
  try {
    const cmd =
      'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "from [\'\\"]enzyme[\'\\"]"'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    const files = stdout.trim().split('\n').filter(Boolean)
    if (files.length > 0) {
      return normalizePath(files[Math.floor(Math.random() * files.length)])
    }
  } catch (error) {
    console.error(colorize('red', `Error finding Enzyme import example: ${error.message}`))
  }
  return null
}

async function showEnzymeImportStats() {
  const count = await countEnzymeImports()
  const randomFile = await getRandomEnzymeImportFile()

  console.log(colorize('yellow', `- Files with Enzyme imports: ${bold(count)}`))
  if (randomFile) {
    console.log(colorize('gray', `  Example: ${randomFile}`))
  }
}

async function printDashboard() {
  console.log(bold(colorize('green', '\nTech Debt Summary\n')))

  console.log(`${bold(colorize('white', 'Skipped Tests'))} ${colorize('gray', '(fix or remove)')}`)
  await countSkippedTests()
  console.log('')

  console.log(
    `${bold(colorize('white', 'Enzyme Imports'))} ${colorize('gray', '(use testing-library)')}`,
  )
  await showEnzymeImportStats()
  console.log('')

  console.log(
    `${bold(colorize('white', 'React String Refs'))} ${colorize('gray', '(use createRef/useRef/forwardRef/callbackRef)')}`,
  )
  await showReactStringRefStats()
  console.log('')

  console.log(
    `${bold(colorize('white', 'PropTypes Usage'))} ${colorize('gray', '(use TypeScript interfaces/types)')}`,
  )
  await showPropTypesStats()
  console.log('')

  console.log(
    `${bold(colorize('white', 'DefaultProps Usage'))} ${colorize('gray', '(use default parameters/TypeScript defaults)')}`,
  )
  await showDefaultPropsStats()
  console.log('')

  console.log(
    `${bold(colorize('white', 'Handlebars Files'))} ${colorize('gray', '(convert to React)')}`,
  )
  await countAndShowRandomFile('.handlebars$', 'Total Handlebars files')
  console.log('')

  console.log(
    `${bold(colorize('white', 'JQuery Imports'))} ${colorize('gray', '(use native DOM)')}`,
  )
  await showJqueryImportStats()
  console.log('')

  console.log(`${bold(colorize('white', 'Sinon Imports'))} ${colorize('gray', '(use Jest)')}`)
  await showSinonImportStats()
  console.log('')

  console.log(
    `${bold(colorize('white', 'ReactDOM.render Files'))} ${colorize('gray', '(convert to createRoot)')}`,
  )
  await countReactDomRenderFiles()
  console.log('')

  console.log(
    `${bold(colorize('white', 'React Class Component Files'))} ${colorize('gray', '(convert to function components)')}`,
  )
  await countReactClassComponentFiles()
  console.log('')

  console.log(
    `${bold(colorize('white', 'JavaScript Files'))} ${colorize('gray', '(convert to TypeScript)')}`,
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
