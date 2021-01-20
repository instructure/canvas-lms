const path = require('path')
const glob = require('glob')
const fs = require('fs')

const processorFiles = { js: [], hbs: [] }

const loadIgnoreFile = file => (
  fs.readFileSync(file, 'utf8')
    .trim()
    .split(/\r?\n|\r/)
    .filter(x => x.length > 0)
    .map(pattern => path.normalize(`${path.dirname(file)}/${pattern}`))
);

const combineIgnores = ignore => next => ({ ...next, ignore: ignore.concat(next.ignore) })
const discoverIgnores = files => {
  const ignoreLists = []
  const ignoreFiles = {}

  for (const file of files) {
    const dir = path.dirname(file)

    if (!ignoreFiles[dir]) {
      const ignoreFile = path.join(dir, '.i18nignore')

      ignoreFiles[dir] = true

      if (fs.existsSync(ignoreFile)) {
        ignoreLists.push(loadIgnoreFile(ignoreFile))
      }
    }
  }

  return ignoreLists.flat()
}

const loadConfigFromI18nrc = file => {
  const config = JSON.parse(fs.readFileSync(file, 'utf8'))
  const ignoreFile = path.resolve(path.dirname(file), '.i18nignore')

  config.cwd = path.dirname(file)
  config.ignore = fs.existsSync(ignoreFile) ? loadIgnoreFile(ignoreFile) : []

  return Object.assign(config, { cwd: path.dirname(file) })
}

const scanFilesFromI18nrc = ({ cwd, files = [], ignore = [], include = [] }) => {
  const globopts = { cwd, absolute: true }

  for (const { pattern, processor } of files) {
    // need 2 passes to discover .i18nignore files
    const included = glob.sync(pattern, { ignore, ...globopts })

    processorFiles[processor] = processorFiles[processor].concat(
      glob.sync(pattern, { ignore: ignore.concat(discoverIgnores(included)), ...globopts })
    )
  }

  for (const subConfigFile of include) {
    scanFilesFromI18nrc(
      combineIgnores(ignore)(
        loadConfigFromI18nrc(
          path.resolve(cwd, subConfigFile)
        )
      )
    )
  }
}

exports.processorFiles = processorFiles
exports.loadConfigFromI18nrc = loadConfigFromI18nrc
exports.scanFilesFromI18nrc = scanFilesFromI18nrc
exports.reset = () => {
  for (const processor of Object.keys(processorFiles)) {
    processorFiles[processor] = []
  }
}
