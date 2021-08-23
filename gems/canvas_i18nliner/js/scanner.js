const path = require('path')
const glob = require('glob')
const fs = require('fs')

const filesByProcessor = { js: [], hbs: [] }

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

const loadConfigFromDirectory = dir => {
  const configFile = path.resolve(dir, '.i18nrc')
  const ignoreFile = path.resolve(dir, '.i18nignore')
  const config = fs.existsSync(configFile) ?
    JSON.parse(fs.readFileSync(configFile, 'utf8')) :
    {}
  ;

  config.cwd = dir
  config.ignore = fs.existsSync(ignoreFile) ? loadIgnoreFile(ignoreFile) : []

  return config
}

const scanFilesFromI18nrc = ({ cwd, files = [], ignore = [], include = [] }) => {
  const globopts = { cwd, absolute: true }

  for (const { pattern, processor } of files) {
    // need 2 passes to discover .i18nignore files
    const included = glob.sync(pattern, { ignore, ...globopts })

    filesByProcessor[processor] = filesByProcessor[processor].concat(
      glob.sync(pattern, { ignore: ignore.concat(discoverIgnores(included)), ...globopts })
    )
  }

  for (const dir of include) {
    scanFilesFromI18nrc(
      combineIgnores(ignore)(
        loadConfigFromDirectory(
          path.resolve(cwd, dir)
        )
      )
    )
  }
}

exports.getFilesForProcessor = name => filesByProcessor[name]
exports.loadConfigFromDirectory = loadConfigFromDirectory
exports.scanFilesFromI18nrc = scanFilesFromI18nrc
exports.reset = () => {
  for (const processor of Object.keys(filesByProcessor)) {
    filesByProcessor[processor].splice(0)
  }
}
