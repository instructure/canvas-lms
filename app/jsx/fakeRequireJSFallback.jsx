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

  const thingsWeStillAllowThemToRequire  = {
    jquery: () => jQuery,
    // load these asynchronously so they are not downloaded unless asked for
    underscore: () => new Promise(resolve => require(['underscore'], resolve)),
    'jsx/course_wizard/ListItems': () => new Promise(resolve => require(['jsx/course_wizard/ListItems'], resolve))
  }

  const getModule = module => {
    if (module in thingsWeStillAllowThemToRequire) {
      return thingsWeStillAllowThemToRequire[module]()
    } else if (/^(https?:)?\/\//.test(module)) { //starts with 'http://', 'https://' or '//'
      return jQuery.getScript(module)
    } else {
      throw new Error(`Can't load ${module}, use your own RequireJS or something else to load this script`)
    }
  }

  window.require = function fakeRequire (deps, callback) {
    console.error(
      `Canvas no longer uses RequireJS. We're providing
      this global window.require shim as convience to try to
      prevent existing code from breaking, but you should fix
      your Custom JS to do you own script loading and not
      depend on this fallback.`,
      'modules required:', deps, 'callback:',callback
    )
    Promise.all(deps.map(getModule)).then((modules) => {
      if (callback) callback(...modules)
    })
  }
}
