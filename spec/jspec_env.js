const fs = require('fs')
const path = require('path')

const config = {
  __SPEC_FILE: null,
  __SPEC_DIR: null,
}

const printErr = (...args) => {
  // wrap err output in red
  console.error('\033[31m\n', ...args, '\033[37m')
}

// make sure JSPEC env was set properly
if (process.env.JSPEC_WD && process.env.JSPEC_PATH) {
  const specPath = path.join(process.env.JSPEC_WD, process.env.JSPEC_PATH)

  try {
    const pathInfo = fs.statSync(specPath)

    if (pathInfo.isFile()) {
      config.__SPEC_FILE = specPath
    } else if (pathInfo.isDirectory()) {
      config.__SPEC_DIR = specPath
    }
  } catch (e) {
    // most likely ENOENT (file not found)
    // print error and exit so we don't continue with the webpack build
    printErr('Error reading spec path:', e.code, specPath)
    process.exit(1)
  }
}

// JSON.stringify config values since webpack plugin does a hard search-replace
module.exports = Object.keys(config).reduce((outputConfig, key) => {
  outputConfig[key] = JSON.stringify(config[key])
  return outputConfig
}, {})
