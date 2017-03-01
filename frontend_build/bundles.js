const glob = require('glob')

const entries = {}

const bundlesPattern = __dirname + '/../app/coffeescripts/bundles/**/*.coffee'
const pluginBundlesPattern = __dirname + '/../gems/plugins/*/app/coffeescripts/bundles/*.coffee'
const bundleNameRegexp = /\/coffeescripts\/bundles\/(.*).coffee/
const fileNameRegexp = /\/([^/]+)\.coffee/
const pluginNameRegexp = /plugins\/([^/]+)\/app/

const appBundles = glob.sync(bundlesPattern, [])
const pluginBundles = glob.sync(pluginBundlesPattern, [])

// these are bundles that are dependencies, and therefore should not be compiled
//  as entry points (webpack won't allow that).
// TODO: Ultimately we should move them to other directories.
const nonEntryPoints = ['modules/account_quota_settings', 'modules/content_migration_setup']

appBundles.forEach((entryFilepath) => {
  const entryBundlePath = entryFilepath.replace(/^.*app\/coffeescripts\/bundles/, './app/coffeescripts/bundles')
  const entryName = bundleNameRegexp.exec(entryBundlePath)[1]
  if (!nonEntryPoints.includes(entryName)) {
    entries[entryName] = entryBundlePath
  }
})

pluginBundles.forEach((entryFilepath) => {
  const pluginName = pluginNameRegexp.exec(entryFilepath)[1]
  const fileName = fileNameRegexp.exec(entryFilepath)[1]
  const bundleName = pluginName + '-' + fileName
  entries[bundleName] = entryFilepath
})

module.exports = entries
