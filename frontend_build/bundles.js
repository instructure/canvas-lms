const path = require('path')
const glob = require('glob')

const entries = {}

const appBundles    = glob.sync(path.join(__dirname, '/../app/coffeescripts/bundles/**/*.coffee'))
const pluginBundles = glob.sync(path.join(__dirname, '/../gems/plugins/*/app/coffeescripts/bundles/*.coffee'))

// these are bundles that are dependencies, and therefore should not be compiled
//  as entry points (webpack won't allow that).
// TODO: Ultimately we should move them to other directories.
const nonEntryPoints = ['modules/account_quota_settings', 'modules/content_migration_setup']

const bundleNameRegexp = /\/coffeescripts\/bundles\/(.*).coffee/
appBundles.forEach((entryFilepath) => {
  const entryBundlePath = entryFilepath.replace(/^.*app\/coffeescripts\/bundles/, './app/coffeescripts/bundles')
  const entryName = bundleNameRegexp.exec(entryBundlePath)[1]
  if (!nonEntryPoints.includes(entryName)) {
    entries[entryName] = entryBundlePath
  }
})

// TODO: Include this from source rather than after the ember app compilation step.
//      This whole "compiled" folder should eventually go away
entries.screenreader_gradebook = './public/javascripts/compiled/bundles/screenreader_gradebook.js'

const fileNameRegexp = /\/([^/]+)\.coffee/
const pluginNameRegexp = /plugins\/([^/]+)\/app/
pluginBundles.forEach((entryFilepath) => {
  const pluginName = pluginNameRegexp.exec(entryFilepath)[1]
  const fileName = fileNameRegexp.exec(entryFilepath)[1]
  const bundleName = pluginName + '-' + fileName
  entries[bundleName] = entryFilepath
})

module.exports = entries
