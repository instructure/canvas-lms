var thingsToLoadWithRequireJS = []
var TEST_REGEXP = /^\/base\/spec\/.*Spec\.js$/i

// Get a list of all the test files to include
Object.keys(window.__karma__.files).forEach(function (file) {
  if (TEST_REGEXP.test(file)) {
    // Normalize paths to RequireJS module names so it works with our `baseUrl` below
    // eg: converts '/base/spec/javascripts/fooSpec.js' to '../../spec/javascripts/fooSpec'
    var normalizedTestModule = file
      .replace(/^\/base\//, '../../')
      .replace(/\.js$/, '')
    thingsToLoadWithRequireJS.push(normalizedTestModule)
  }
})

// include the english translations by default, same as would happen in
// production via common.js. this saves the test writer from having to stub
// translations anytime they need to use code that uses a no-default
// translation call (e.g. I18n.t('#date.formats.medium')) with the default
// locale
thingsToLoadWithRequireJS.push('translations/_core_en')

window.addEventListener("DOMContentLoaded", function() {
  if (!document.getElementById('fixtures')) {
    var fixturesDiv = document.createElement('div')
    fixturesDiv.id = 'fixtures'
    document.body.appendChild(fixturesDiv)
  }
}, false)

if(!window.ENV) window.ENV = {}

requirejs.config({
  baseUrl: '/base/public/javascripts',
  deps: thingsToLoadWithRequireJS, // dynamically load all test files
  callback: window.__karma__.start
});
