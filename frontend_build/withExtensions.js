// This loader knows how to build a glue module that requires both the original
// unextended file from canvas, and any extensions from plugins, and builds
// a chain of calls to apply the extensions.  This is a replacement for any
// place in the app the original file is required.

function extractFileName (remainingRequest) {
  const loaderedPieces = remainingRequest.split('!')
  const unloaderedRequest = loaderedPieces[loaderedPieces.length - 1]
  return unloaderedRequest.replace(/^.*\/app\/coffeescripts\//, '')
}

module.exports = function (source) {
  throw 'Should not ever make it to the actual extensions loader because the pitching function does the work'
}

module.exports.pitch = function (remainingRequest, precedingRequest, data) {
  this.cacheable()

  const fileName = extractFileName(remainingRequest)
  const plugins = this.query.replace('?', '').split(',')
  const originalRequire = `unextended!coffeescripts/${fileName}`
  const pluginPaths = [originalRequire]
  const pluginArgs = []
  plugins.forEach((plugin, i) => {
    const pluginExtension = `${plugin}/app/coffeescripts/extensions/${fileName}`
    pluginPaths.push(pluginExtension)
    pluginArgs.push(`p${i}`)
  })

  let pluginChain = 'orig'

  let i = pluginArgs.length - 1
  while (i >= 0){
    const pluginCall = pluginArgs[i]
    pluginChain = `${pluginCall}(${pluginChain})`
    i--
  }

  const extendedJavascript = `
    define(${JSON.stringify(pluginPaths)},function(orig, ${pluginArgs.join(",")}){
      return ${pluginChain}
    });
  `

  return extendedJavascript
}
