const fs = require('fs')

let webpackFileExists = false;
try {
  fs.statSync(__dirname + "/config/WEBPACK")
  webpackFileExists = true
} catch (e) {
  console.log("no webpack file....")
}

var usingWebpack = (process.env.USE_WEBPACK == 'True' ||
                    process.env.USE_WEBPACK == 'true' ||
                    webpackFileExists)

console.log('using webpack?', usingWebpack)

// If we're using webpack, we don't want to load all the requirejs stuff
let karmaFiles
if (usingWebpack) {
  karmaFiles = [
    {pattern: 'spec/javascripts/webpack/*.bundle.test.js', included: true, served: true},
    {pattern: 'spec/javascripts/webpack/*.chunk*.js', included: false, served: true},
    {pattern: 'spec/javascripts/fixtures/*', included: false, served: true},
    {pattern: 'public/dist/brandable_css/**/*.css', included: false, served: true},
  ]
} else {
  karmaFiles = [
    'node_modules/sinon/pkg/sinon.js',
    'spec/javascripts/requirejs_config.js',
    'public/javascripts/vendor/require.js',
    'node_modules/karma-requirejs/lib/adapter.js',
    'spec/javascripts/support/sinon/sinon-qunit-1.0.0.js',
    {pattern: 'public/javascripts/*.js', included: false, served: true},
    {pattern: 'spec/javascripts/fixtures/*.html', included: false, served: true},
    {pattern: 'spec/javascripts/compiled/*.js', included: false, served: true},
    {pattern: 'spec/javascripts/compiled/**/*.js', included: false, served: true},
    {pattern: 'spec/**/javascripts/compiled/**/*.js', included: false, served: true},
    {pattern: 'spec/javascripts/fixtures/*', included: false, served: true},
    {pattern: 'public/javascripts/**/*.js', included: false, served: true},
    {pattern: 'public/dist/brandable_css/**/*.css', included: false, served: true},
    'spec/javascripts/load_tests.js'
  ]
}


const karmaConfig = {
  basePath: '',

  frameworks: ['qunit'],

  files: karmaFiles,

  // preprocessors: {
  //   '**/*.js': ['sourcemap']
  // },

  proxies: {
    '/dist/brandable_css/': '/base/public/dist/brandable_css/'
  },

  exclude: [],

  // 'dots', 'progress', 'junit', 'growl', 'coverage', 'spec'
  reporters: ['progress', 'coverage'],

  coverageReporter: {
    type: 'html',
    dir: 'coverage-js/',
    subdir: '.'
  },

  port: 9876,

  colors: true,

  autoWatch: true,

  // - Chrome
  // - ChromeCanary
  // - Firefox
  // - Opera (has to be installed with `npm install karma-opera-launcher`)
  // - Safari (only Mac; has to be installed with `npm install karma-safari-launcher`)
  // - PhantomJS
  // - IE (only Windows; has to be installed with `npm install karma-ie-launcher`)
  browsers: ['Chrome', 'PhantomJS'],

  // If browser does not capture in given timeout [ms], kill it
  captureTimeout: 60000,

  browserNoActivityTimeout: 2000000,

  // Continuous Integration mode
  // if true, it capture browsers, run tests and exit
  singleRun: false
}

module.exports = function (config) {
  // config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
  karmaConfig.logLevel = config.LOG_INFO,
  config.set(karmaConfig)
}
