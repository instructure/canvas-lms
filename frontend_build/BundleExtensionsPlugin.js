// this is how we do the magic for making sure extensions in plugins get applied
// to canvas modules.  It depends upon conventional file system names (
// some file in the plugin has the same name as the coffeescript file it extends
// in canvas)
/*
# given app/coffeescripts/foo.coffee in canvas-lms, if you want to
# monkey patch it from your plugin, create
# app/coffeescripts/extensions/foo.coffee (in your plugin) like so:
#
# define ->
#   (Foo) ->
#     Foo::zomg = -> "i added this method"
#     Foo
#
# and that's it, no changes required in canvas-lms, no plugin
# bundles, etc.
#
# note that Foo is not an explicit dependency, it magically figures
# it out. also note that your module should return a function that
# accepts and returns Foo. this function will magically wrap around
# Foo so you can do stuff to it anytime somebody requires "foo" as
# per usual.
*/
const glob = require('glob')

// this is all the extensions that we can find in gems/plugins
const extensions = (() => {
  const pluginExtensionsPattern = `${__dirname}/../gems/plugins/*/app/coffeescripts/extensions/**/*.coffee`
  const pluginExtensions = glob.sync(pluginExtensionsPattern, [])
  const extensionsMap = {}
  const extensionPartsRegexp = /plugins\/([^/]*)\/app\/coffeescripts\/extensions\/(.*)\.coffee/
  pluginExtensions.forEach((extension) => {
    const extractions = extension.match(extensionPartsRegexp)
    const pluginName = extractions[1]
    const fileName = extractions[2]
    if (extensionsMap[fileName] === undefined) {
      extensionsMap[fileName] = []
    }
    extensionsMap[fileName].push(pluginName)
  })
  return extensionsMap
})()

const unextendedRegexp = /^unextended!/
const extensionRequirementRegexp = /\/extensions\//

class BundleExtensionsPlugin {
  apply (compiler) {
    compiler.plugin('normal-module-factory', (nmf) => {
      nmf.plugin('before-resolve', (result, callback) => {
        let addLoadersFor = []
        // if we're resolving an extension, we don't want to try to
        // extend the extension itself, so skip the check and move on
        if (!extensionRequirementRegexp.test(result.request)) {
          Object.keys(extensions).forEach((key) => {
            if (result.request.includes(key)) {
              if (unextendedRegexp.test(result.request)) {
                // skip, unextended loader means we really want the original
              } else {
                // we're trying to resolve a file that has an extension in at least one plugin,
                // so we'll set the flag that tells us to add the withExtensions loader
                // down below
                addLoadersFor = extensions[key]
              }
            }
          })

          if (addLoadersFor.length > 0) {
            const newRequest = `withExtensions?${addLoadersFor.join(',')}!${result.request}`
            result.request = newRequest
          }
        }
        return callback(null, result)
      })
    })
  }
}

module.exports = BundleExtensionsPlugin
