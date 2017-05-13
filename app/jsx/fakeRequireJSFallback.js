/*
  This shim is to try to not break code of our customers that use RequireJS-style
  `require`s in their Custom JS files from ThemeEditor. It is not meant to be comprehensive.
  There will be some customers that need to change their code, but there was a lot that
  just used require to load jquery or just load an external script. this should handle
  both of those cases.

  eg:

  require([
    'underscore',
    'jquery',
    'https://code.jquery.com/color/jquery.color.js'
  ], function(_, $) {
    console.log('got', $, _, $.Color.names)
  })
  should log: underscore, jquery and the colors
*/

if (!('require' in window)) {
  const jQuery = require('jquery')

  const thingsWeStillAllowThemToRequire = {
    jquery: () => jQuery,
    // load these asynchronously so they are not downloaded unless asked for
    i18nObj: () => import('i18nObj'),
    underscore: () => import('underscore'),
    'jsx/course_wizard/ListItems': () => new Promise(resolve => {
      require.ensure([], require => {
        resolve(require('jsx/course_wizard/ListItems'))
      }, 'course_wizardListItemsAsyncChunk')
    })
  }

  const getModule = (module) => {
    if (module in thingsWeStillAllowThemToRequire) {
      return thingsWeStillAllowThemToRequire[module]()
    } else if (/^(https?:)?\/\//.test(module)) { // starts with 'http://', 'https://' or '//'
      return jQuery.getScript(module)
    } else {
      throw new Error(`Cannot load ${module}, use your own RequireJS or something else to load this script`)
    }
  }

  window.require = function fakeRequire (deps, callback) {
    if (callback.name !== 'fnCanvasUsesToLoadAccountJSAfterJQueryIsReady') {
      console.warn(
        '`require`-ing internal Canvas modules comes with no warranty, ' +
        'things can change in any release and you are responsible for making sure your custom ' +
        'JavaScript that uses it continues to work.'
      )
      if (deps.includes('jquery')) {
        console.error("You don't need to `require(['jquery...`, just use the global `$` variable directly.")
      }
    }
    Promise.all(deps.map(getModule)).then((modules) => {
      if (callback) callback(...modules)
    })
  }
}
