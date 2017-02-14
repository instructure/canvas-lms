const useWebpack = (/true/i).test(process.env.USE_WEBPACK) || require('fs').existsSync(`${__dirname}/config/WEBPACK`)
console.log('using webpack?', useWebpack)

const karmaConfig = Object.assign({
  basePath: '',

  frameworks: ['qunit'],

  proxies: {
    '/dist/brandable_css/': '/base/public/dist/brandable_css/'
  },

  exclude: [],

  // 'dots', 'progress', 'junit', 'growl', 'coverage', 'spec'
  reporters: ['progress', 'coverage'],
  // enable the verbose reporter if you want to have more information of where/how specs fail
  // reporters: ['verbose'],


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
  browsers: ['Chrome'],

  // If browser does not capture in given timeout [ms], kill it
  captureTimeout: 60000,

  browserNoActivityTimeout: 2000000,

  reportSlowerThan: 1000,

  // normally QUnit wraps each test in a try/catch so a single spec failing
  // doesn't stop the whole test suite. In dev, if you want to click the
  // "pause on exception" thing in chrome and have it stop on your failing test, enable notrycatch
  // client: {qunit: {notrycatch: true}},

  // by default we keep the browser open so it refreshes with any changes
  // but in `npm test` (which is what jenkins CI runs) we override it so
  // it just runs once and then exits.
  singleRun: false
}, useWebpack ? {

  files: [
    {pattern: 'spec/javascripts/webpack_spec_index.js', included: true, served: true},
    {pattern: 'spec/javascripts/fixtures/*', included: false, served: true},
    {pattern: 'public/dist/brandable_css/**/*.css', included: false, served: true},
  ],

  preprocessors: {
    'spec/javascripts/webpack_spec_index.js': ['webpack']
  },

  webpack: require('./webpack.test.config'),

} : {
  files: [
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
})

module.exports = function (config) {
  // config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
  karmaConfig.logLevel = config.LOG_INFO,
  config.set(karmaConfig)
}
