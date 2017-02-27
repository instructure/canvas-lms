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

const path = require('path')

const specRoot = path.resolve(__dirname, '../spec')

function addExt (requestString) {
  const ext = /\/templates\//.test(requestString) ? '.hbs' : '.coffee'
  return requestString + ext
}

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
    return `${pluginName}/app/coffeescripts/${relativePath}.coffee`
  }
}

class CompiledReferencePlugin {
  apply (compiler) {
    compiler.plugin('normal-module-factory', (nmf) => {
      nmf.plugin('before-resolve', (input, callback) => {
        const result = input
        const requestString = result.request

        if (/^jsx\//.test(requestString)) {
          // this is a jsx file in canvas. We have to require it with its full
          // extension while we still have a require-js build or we risk loading
          // its compiled js instead
          result.request = `${requestString}.jsx`
        } else if (
          requestString.startsWith('.') &&
          path.join(input.context, input.request).includes('app/coffeescripts') &&
          !/\.coffee$/.test(requestString)
        ) {
          // this is a relative require to  a compiled coffeescript (or hbs) file
          result.request = addExt(requestString)
        } else if (/jst\//.test(requestString)) {
          // this is a handlebars file in canvas. We have to require it with its full
          // extension while we still have a require-js build or we risk loading
          // its compiled js instead
          result.request = `${requestString}.handlebars`
        } else if ((
          /^compiled\//.test(requestString) ||
          requestString.includes('ic-submission-download-dialog')
        ) && !requestString.includes('dummyI18nResource')) {
          // this references either a coffeescript or ember handlebars file in canvas
          result.request = addExt(requestString.replace('compiled/', 'coffeescripts/'))
        } else if (process.env.NODE_ENV === 'test') {
          if (/^spec\/javascripts\/compiled/.test(requestString)) {
            // this references a coffesscript spec file in canvas
            result.request = `${requestString.replace('spec/javascripts/compiled/', '')}.coffee`
          } else if (input.context.startsWith(specRoot) && requestString.startsWith('helpers/')) {
            // we have a bunch of specs that require eg: 'helpers/fakeENV'. in order to not have to add
            // `spec/coffescripts` to `resolve.modules` and '.coffee' to `resolve.extensions` (which
            // would slow everything down because it would add to the # of files it has to stat when
            // looking for things), we rewrite those requests here
            result.request = `${specRoot}/coffeescripts/${requestString}.coffee`
          }
        }

        // this references a file in a canvas plugin
        if (pluginTranspiledRegexp.test(requestString)) {
          result.request = rewritePluginPath(requestString)
        }
        return callback(null, result)
      })
    })
  }
}

module.exports = CompiledReferencePlugin
