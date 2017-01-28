// We have a lot of references to "compiled" directories right now,
// but since webpack can load and compile coffeescript on the fly,
// we can just use a coffeescript loader.  The problem, though, is
// that we don't want to have to change the current references everywhere,
// and it's technically possible to have naming conflicts today.
// to bridge the gap, we'll add "app" to the search path for webpack in
// the config, and replace "compiled" references with "coffeescripts" in The
// path, which should both differentiate them from files in the public/javascripts
// directory with the same name, and load them directly rather than needing
// a compile step ahead of time.

const pluginTranspiledRegexp = /^([^/]+)\/compiled\//
const jsxRegexp = /compiled\/jsx/

function rewritePluginPath (requestString) {
  const pluginName = pluginTranspiledRegexp.exec(requestString)[1]
  const relativePath = requestString.replace(`${pluginName}/compiled/`, '')
  if (jsxRegexp.test(requestString)) {
    // this references a JSX file which already has "jsx" in its file path
    return `${pluginName}/app/${relativePath}`
  } else {
    // this references a coffeescript file which needs "coffeescripts" to
    // replace the "compiled" part of the path
    return `${pluginName}/app/coffeescripts/${relativePath}`
  }
}

class CompiledReferencePlugin {
  apply (compiler) {
    compiler.plugin('normal-module-factory', nmf => {
      nmf.plugin('before-resolve', (input, callback) => {
        const result = input
        const requestString = result.request

        if (/^jsx\//.test(requestString)) {
          // this is a jsx file in canvas. We have to require it with its full
          // extension while we still have a require-js build or we risk loading
          // its compiled js instead
          result.request = `${requestString}.jsx`
        } else if (/^jst\//.test(requestString)) {
          // this is a handlebars file in canvas. We have to require it with its full
          // extension while we still have a require-js build or we risk loading
          // its compiled js instead
          result.request = `${requestString}.handlebars`
        } else if (/^compiled\//.test(requestString)) {
          // this references a coffesscript file in canvas
          result.request = requestString.replace('compiled/', 'coffeescripts/')
        } else if (/^spec\/javascripts\/compiled/.test(requestString)) {
          // this references a coffesscript spec file in canvas
          result.request = requestString.replace('spec/javascripts/compiled/', '')
        }

        // this references a file in a canvas plugin
        const pluginTranspiledRegexp = /^([^/]+)\/compiled\//
        if (pluginTranspiledRegexp.test(requestString)) {
          result.request = rewritePluginPath(requestString)
        }
        return callback(null, result)
      })
    })
  }
}

module.exports = CompiledReferencePlugin
