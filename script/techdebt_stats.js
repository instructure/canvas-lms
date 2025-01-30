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

const {execSync, exec} = require('child_process')
const util = require('util')
const path = require('path')
const {ESLint} = require('eslint')
const pluginReactCompiler = require('eslint-plugin-react-compiler')

const execAsync = util.promisify(exec)
const projectRoot = path.resolve(__dirname, '..')

const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  gray: '\x1b[90m',
  bold: '\x1b[1m',
  white: '\x1b[37m',
}

function colorize(color, text) {
  return `${colors[color]}${text}${colors.reset}`
}

function bold(text) {
  return colorize('bold', text)
}

const sections = {
  skipped: 'skipped',
  enzyme: 'enzyme',
  reactStringRefs: 'string-refs',
  propTypes: 'proptypes',
  defaultProps: 'defaultprops',
  handlebars: 'handlebars',
  jquery: 'jquery',
  sinon: 'sinon',
  reactDom: 'reactdom',
  classComponents: 'class',
  javascript: 'javascript',
  typescript: 'typescript',
  outdatedPackages: 'outdated',
  reactCompiler: 'react-compiler',
}

// Parse command line arguments
function parseArgs() {
  const args = process.argv.slice(2)
  const options = {
    section: null,
    verbose: false,
    help: false,
  }

  for (let i = 0; i < args.length; i++) {
    const arg = args[i]
    switch (arg) {
      case '-h':
      case '--help':
        options.help = true
        break
      case '-v':
      case '--verbose':
        options.verbose = true
        break
      case '-s':
      case '--section':
        if (i + 1 < args.length) {
          options.section = args[i + 1]
          i++ // Skip the next argument since we used it
        }
        break
    }
  }

  return options
}

function printHelp() {
  console.log(`
Usage: node techdebt_stats.js [options]

Options:
  -h, --help                Show this help message
  -v, --verbose            Show all files instead of just examples
  -s, --section <name>     Show only a specific section

Available sections:
  skipped         - Skipped tests
  enzyme          - Enzyme imports
  string-refs     - React string refs
  proptypes       - PropTypes usage
  defaultprops    - DefaultProps usage
  handlebars      - Handlebars files
  jquery          - jQuery imports
  sinon           - Sinon imports
  reactdom        - ReactDOM.render files
  class           - React class components
  javascript      - JavaScript files
  typescript      - TypeScript suppressions
  outdated        - Outdated packages
  react-compiler  - React Compiler Rule Violations
`)
  process.exit(0)
}

const normalizePath = filePath => filePath.replace(/\/+/g, '/')

async function getMatchingFiles(searchPattern, verbose = false) {
  try {
    const {stdout} = await execAsync(
      `git ls-files "ui/" "packages/" | grep -E "${searchPattern}"`,
      {cwd: projectRoot},
    )
    return stdout.trim().split('\n').filter(Boolean)
  } catch (error) {
    return []
  }
}

async function getGrepMatchingFiles(filePattern, grepPattern, verbose = false) {
  try {
    const cmd = `git ls-files "ui/" "packages/" | grep -E "${filePattern}" | xargs grep -l "${grepPattern}"`
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    return stdout.trim().split('\n').filter(Boolean)
  } catch (error) {
    return []
  }
}

async function countAndShowFiles(searchPattern, description, verbose = false) {
  try {
    const files = await getMatchingFiles(searchPattern, verbose)
    const fileCount = files.length

    if (fileCount > 0) {
      console.log(colorize('yellow', `- ${description}: ${bold(fileCount)}`))
      if (verbose) {
        files.sort().forEach(file => {
          console.log(colorize('gray', `  ${file}`))
        })
      } else {
        const randomFile = normalizePath(files[Math.floor(Math.random() * fileCount)])
        console.log(colorize('gray', `  Example: ${randomFile}`))
      }
    } else {
      console.log(colorize('yellow', `- ${description}: ${colorize('green', 'None')}`))
    }
  } catch (error) {
    console.error(colorize('red', `Error searching for ${description}: ${error.message}`))
  }
}

async function countTsSuppressions(type, verbose = false) {
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

async function getRandomTsSuppressionFile(type, verbose = false) {
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

async function showTsSuppressionStats(type, verbose = false) {
  const count = await countTsSuppressions(type, verbose)
  console.log(colorize('yellow', `- Total files with @${type}: ${bold(count)}`))

  if (count > 0) {
    const files = await getGrepMatchingFiles('\\.(ts|tsx)$', `@${type}`, verbose)
    if (verbose) {
      files.sort().forEach(file => {
        console.log(colorize('gray', `  ${file}`))
      })
    } else {
      const randomFile = await getRandomTsSuppressionFile(type, verbose)
      if (randomFile) {
        console.log(colorize('gray', `  Example: ${randomFile}`))
      }
    }
  }
}

async function countJqueryImports(verbose = false) {
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

async function getRandomJqueryImportFile(verbose = false) {
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

async function showJqueryImportStats(verbose = false) {
  const count = await countJqueryImports(verbose)
  console.log(colorize('yellow', `- Files with jQuery imports: ${bold(count)}`))

  if (count > 0) {
    if (verbose) {
      const cmd =
        'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
        'xargs grep -l "\\$\\|\\bjQuery\\b\\|\\bimport.*jquery\\b"'
      const {stdout} = await execAsync(cmd, {cwd: projectRoot})
      const files = stdout.trim().split('\n').filter(Boolean)
      files.sort().forEach(file => {
        console.log(colorize('gray', `  ${file}`))
      })
    } else {
      const randomFile = await getRandomJqueryImportFile(verbose)
      if (randomFile) {
        console.log(colorize('gray', `  Example: ${randomFile}`))
      }
    }
  }
}

async function countSinonImports(verbose = false) {
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

async function getRandomSinonImportFile(verbose = false) {
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

async function showSinonImportStats(verbose = false) {
  const count = await countSinonImports(verbose)
  console.log(colorize('yellow', `- Files with Sinon imports: ${bold(count)}`))

  if (count > 0) {
    const files = await getGrepMatchingFiles(
      '__tests__.*\\.(js|jsx|ts|tsx)$',
      '\\bsinon\\b',
      verbose,
    )
    if (verbose) {
      files.sort().forEach(file => {
        console.log(colorize('gray', `  ${file}`))
      })
    } else {
      const randomFile = await getRandomSinonImportFile(verbose)
      if (randomFile) {
        console.log(colorize('gray', `  Example: ${randomFile}`))
      }
    }
  }
}

async function countEnzymeImports(verbose = false) {
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

async function getRandomEnzymeImportFile(verbose = false) {
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

async function showEnzymeImportStats(verbose = false) {
  const count = await countEnzymeImports(verbose)
  console.log(colorize('yellow', `- Files with Enzyme imports: ${bold(count)}`))

  if (count > 0) {
    if (verbose) {
      const cmd =
        'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
        'xargs grep -l "from [\'\\"]enzyme[\'\\"]"'
      const {stdout} = await execAsync(cmd, {cwd: projectRoot})
      const files = stdout.trim().split('\n').filter(Boolean)
      files.sort().forEach(file => {
        console.log(colorize('gray', `  ${file}`))
      })
    } else {
      const randomFile = await getRandomEnzymeImportFile(verbose)
      if (randomFile) {
        console.log(colorize('gray', `  Example: ${randomFile}`))
      }
    }
  }
}

async function countSkippedTests(verbose = false) {
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
      if (verbose) {
        allFiles.sort().forEach(file => {
          console.log(colorize('gray', `  ${file}`))
        })
      } else {
        const randomFile = normalizePath(allFiles[Math.floor(Math.random() * fileCount)])
        console.log(colorize('gray', `  Example: ${randomFile}`))
      }
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

async function checkOutdatedPackages(verbose = false) {
  try {
    const output = execSync('npm outdated --json', {
      cwd: projectRoot,
      stdio: ['pipe', 'pipe', 'pipe'],
      encoding: 'utf8',
    }).toString()
    handleOutdatedPackages(output, verbose)
  } catch (error) {
    // npm outdated exits with code 1 when it finds outdated packages
    // This is expected behavior, so we should still try to parse the output
    if (error.stdout) {
      handleOutdatedPackages(error.stdout, verbose)
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

function handleOutdatedPackages(output, verbose = false) {
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
      if (verbose) {
        majorOutdated.forEach(pkg => {
          console.log(
            colorize(
              'gray',
              `  ${pkg.packageName} (current: ${pkg.current}, wanted: ${pkg.wanted}, latest: ${pkg.latest})`,
            ),
          )
        })
      } else {
        const randomPackage = majorOutdated[Math.floor(Math.random() * majorOutdated.length)]
        console.log(
          colorize(
            'gray',
            `  Example: ${randomPackage.packageName} (current: ${randomPackage.current}, wanted: ${randomPackage.wanted}, latest: ${randomPackage.latest})`,
          ),
        )
      }
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

async function countReactDomRenderFiles(verbose = false) {
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
      if (verbose) {
        files.sort().forEach(file => {
          console.log(colorize('gray', `  ${file}`))
        })
      } else {
        const randomFile = normalizePath(files[Math.floor(Math.random() * fileCount)])
        console.log(colorize('gray', `  Example: ${randomFile}`))
      }
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

async function countReactClassComponentFiles(verbose = false) {
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
      if (verbose) {
        allFiles.sort().forEach(file => {
          console.log(colorize('gray', `  ${file}`))
        })
      } else {
        const randomFile = normalizePath(allFiles[Math.floor(Math.random() * fileCount)])
        console.log(colorize('gray', `  Example: ${randomFile}`))
      }
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

async function countReactStringRefs(verbose = false) {
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

async function getRandomReactStringRefFile(verbose = false) {
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

async function showReactStringRefStats(verbose = false) {
  const count = await countReactStringRefs(verbose)
  console.log(colorize('yellow', `- Files with React string refs: ${bold(count)}`))
  if (count > 0) {
    if (verbose) {
      const cmd =
        'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
        'xargs grep -l "\\bref=\\"[^\\"]*\\""' // Fix the string-refs grep pattern
      const {stdout} = await execAsync(cmd, {cwd: projectRoot})
      const files = stdout.trim().split('\n').filter(Boolean)
      files.sort().forEach(file => {
        console.log(colorize('gray', `  ${file}`))
      })
    } else {
      const randomFile = await getRandomReactStringRefFile(verbose)
      if (randomFile) {
        console.log(colorize('gray', `  Example: ${randomFile}`))
      }
    }
  }
}

async function countPropTypesFiles(verbose = false) {
  try {
    const cmd =
      'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx|ts|tsx)$" | ' +
      'xargs grep -l "\\.propTypes\\s*="'
    const {stdout} = await execAsync(cmd, {cwd: projectRoot})
    return Number.parseInt(stdout.trim().split('\n').filter(Boolean).length, 10)
  } catch (error) {
    console.error(colorize('red', `Error counting PropTypes files: ${error.message}`))
    return 0
  }
}

async function getRandomPropTypesFile(verbose = false) {
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
    console.error(colorize('red', `Error finding PropTypes example: ${error.message}`))
  }
  return null
}

async function showPropTypesStats(verbose = false) {
  const count = await countPropTypesFiles(verbose)
  console.log(colorize('yellow', `- Files with PropTypes: ${bold(count)}`))
  if (count > 0) {
    if (verbose) {
      const cmd =
        'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx)$" | ' +
        'xargs grep -l "PropTypes\\."'
      const {stdout} = await execAsync(cmd, {cwd: projectRoot})
      const files = stdout.trim().split('\n').filter(Boolean)
      files.sort().forEach(file => {
        console.log(colorize('gray', `  ${file}`))
      })
    } else {
      const randomFile = await getRandomPropTypesFile(verbose)
      if (randomFile) {
        console.log(colorize('gray', `  Example: ${randomFile}`))
      }
    }
  }
}

async function countDefaultPropsFiles(verbose = false) {
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

async function getRandomDefaultPropsFile(verbose = false) {
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

async function showDefaultPropsStats(verbose = false) {
  const count = await countDefaultPropsFiles(verbose)
  console.log(colorize('yellow', `- Files with defaultProps: ${bold(count)}`))
  if (count > 0) {
    if (verbose) {
      const cmd =
        'git ls-files "ui/" "packages/" | grep -E "\\.(js|jsx)$" | ' +
        'xargs grep -l "\\.defaultProps\\s*="'
      const {stdout} = await execAsync(cmd, {cwd: projectRoot})
      const files = stdout.trim().split('\n').filter(Boolean)
      files.sort().forEach(file => {
        console.log(colorize('gray', `  ${file}`))
      })
    } else {
      const randomFile = await getRandomDefaultPropsFile(verbose)
      if (randomFile) {
        console.log(colorize('gray', `  Example: ${randomFile}`))
      }
    }
  }
}

// Add loading indicator helpers
function startSpinner(message) {
  const frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
  let i = 0
  process.stdout.write('\r' + frames[0] + ' ' + message)
  return setInterval(() => {
    i = (i + 1) % frames.length
    process.stdout.write('\r' + frames[i] + ' ' + message)
  }, 80)
}

function stopSpinner(interval) {
  clearInterval(interval)
  process.stdout.write('\r\x1b[K') // Clear the line
}

function createReactCompilerESLint() {
  return new ESLint({
    cache: true,
    baseConfig: {
      plugins: {
        'react-compiler': pluginReactCompiler,
      },
      rules: {
        'react-compiler/react-compiler': 'warn',
      },
    },
  })
}

async function countReactCompilerViolations() {
  try {
    const spinner = startSpinner('Analyzing files in `ui/` for react-compiler violations...')
    const eslint = createReactCompilerESLint()

    const results = await eslint.lintFiles(['ui/**/*.{js,jsx,ts,tsx}'])
    stopSpinner(spinner)

    const violations = results.flatMap(result =>
      result.messages.filter(msg => msg.ruleId === 'react-compiler/react-compiler'),
    )
    return violations.length
  } catch (error) {
    console.error(colorize('red', `Error counting react-compiler violations: ${error.message}`))
    return 0
  }
}

async function getRandomReactCompilerViolationFile() {
  try {
    const spinner = startSpinner('Finding files with react-compiler violations...')
    const eslint = createReactCompilerESLint()

    const results = await eslint.lintFiles(['ui/**/*.{js,jsx,ts,tsx}'])
    stopSpinner(spinner)

    const filesWithViolations = results
      .filter(result => result.messages.some(msg => msg.ruleId === 'react-compiler/react-compiler'))
      .map(result => {
        const message = result.messages.find(msg => msg.ruleId === 'react-compiler/react-compiler')
        return `${result.filePath}:${message.line}:${message.column}`
      })

    if (filesWithViolations.length === 0) {
      return null
    }

    const randomFile = filesWithViolations[Math.floor(Math.random() * filesWithViolations.length)]
    return normalizePath(path.relative(projectRoot, randomFile))
  } catch (error) {
    console.error(
      colorize('red', `Error finding react-compiler violation example: ${error.message}`),
    )
    return null
  }
}

async function showReactCompilerViolationStats(verbose = false) {
  const count = await countReactCompilerViolations()
  console.log(colorize('yellow', `- Files with react-compiler violations: ${bold(count)}`))

  if (count > 0) {
    if (verbose) {
      const spinner = startSpinner('Getting detailed list of react-compiler violations...')
      const eslint = createReactCompilerESLint()

      const results = await eslint.lintFiles(['ui/**/*.{js,jsx,ts,tsx}'])
      stopSpinner(spinner)

      const filesWithViolations = results
        .filter(result =>
          result.messages.some(msg => msg.ruleId === 'react-compiler/react-compiler'),
        )
        .map(result => {
          const message = result.messages.find(
            msg => msg.ruleId === 'react-compiler/react-compiler',
          )
          return normalizePath(
            `${path.relative(projectRoot, result.filePath)}:${message.line}:${message.column}`,
          )
        })
        .sort()

      filesWithViolations.forEach(file => {
        console.log(colorize('gray', `  ${file}`))
      })
    } else {
      const randomFile = await getRandomReactCompilerViolationFile()
      if (randomFile) {
        console.log(colorize('gray', `  Example: ${randomFile}`))
      } else {
        console.log(colorize('green', `No violations found!`))
      }
    }
  }
}

function getSectionTitle(section) {
  const titles = {
    skipped: ['Skipped Tests', '(fix or remove)'],
    enzyme: ['Enzyme Imports', '(use testing-library)'],
    'string-refs': ['React String Refs', '(use createRef/useRef/forwardRef/callbackRef)'],
    proptypes: ['PropTypes Usage', '(use TypeScript interfaces/types)'],
    defaultprops: ['DefaultProps Usage', '(use default parameters/TypeScript defaults)'],
    handlebars: ['Handlebars Files', '(convert to React)'],
    jquery: ['JQuery Imports', '(use native DOM)'],
    sinon: ['Sinon Imports', '(use Jest)'],
    reactdom: ['ReactDOM.render Files', '(convert to createRoot)'],
    class: ['React Class Component Files', '(convert to function components)'],
    javascript: ['JavaScript Files', '(convert to TypeScript)'],
    typescript: ['TypeScript Suppressions', ''],
    outdated: ['Outdated Packages', ''],
    reactCompiler: ['React Compiler Rule Violations', ''],
  }

  const [title, note] = titles[section] || [section, '']
  return note
    ? colorize('white', bold(title)) + ' ' + colorize('gray', note)
    : colorize('white', bold(title))
}

async function printDashboard() {
  try {
    const options = parseArgs()

    if (options.help) {
      printHelp()
    }

    console.log(bold(colorize('green', '\nTech Debt Summary\n')))

    const selectedSection = options.section
    const verbose = options.verbose

    if (!selectedSection || selectedSection === 'skipped') {
      console.log(getSectionTitle('skipped'))
      await countSkippedTests(verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'enzyme') {
      console.log(getSectionTitle('enzyme'))
      await showEnzymeImportStats(verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'string-refs') {
      console.log(getSectionTitle('string-refs'))
      await showReactStringRefStats(verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'proptypes') {
      console.log(getSectionTitle('proptypes'))
      await showPropTypesStats(verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'defaultprops') {
      console.log(getSectionTitle('defaultprops'))
      await showDefaultPropsStats(verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'handlebars') {
      console.log(getSectionTitle('handlebars'))
      await countAndShowFiles('\\.handlebars$', 'Total Handlebars files', verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'jquery') {
      console.log(getSectionTitle('jquery'))
      await showJqueryImportStats(verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'sinon') {
      console.log(getSectionTitle('sinon'))
      await showSinonImportStats(verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'reactdom') {
      console.log(getSectionTitle('reactdom'))
      await countReactDomRenderFiles(verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'class') {
      console.log(getSectionTitle('class'))
      await countReactClassComponentFiles(verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'javascript') {
      console.log(getSectionTitle('javascript'))
      await countAndShowFiles('\\.(js|jsx)$', 'Total JavaScript files', verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'typescript') {
      console.log(getSectionTitle('typescript'))
      await showTsSuppressionStats('ts-nocheck', verbose)
      await showTsSuppressionStats('ts-ignore', verbose)
      await showTsSuppressionStats('ts-expect-error', verbose)
      console.log()
    }

    if (!selectedSection || selectedSection === 'outdated') {
      console.log(getSectionTitle('outdated'))
      console.log()
      await checkOutdatedPackages(verbose)
    }

    if (!selectedSection || selectedSection === 'react-compiler') {
      console.log(getSectionTitle('react-compiler'))
      await showReactCompilerViolationStats(verbose)
      console.log()
    }
  } catch (error) {
    console.error(colorize('red', `Error: ${error.message}`))
    process.exit(1)
  }
}

printDashboard().catch(error => {
  console.error(colorize('red', `Error: ${error.message}`))
  process.exit(1)
})
