const karmaConfig = {
  basePath: '',

  frameworks: ['qunit'],

  proxies: {
    '/dist/brandable_css/': '/base/public/dist/brandable_css/',
    '/images/': '/base/public/images/'
  },

  exclude: [],

  // 'dots', 'progress', 'junit', 'growl', 'coverage', 'spec'
  reporters: ['spec', 'junit'],
  // enable the verbose reporter if you want to have more information of where/how specs fail
  // reporters: ['verbose'],

  // this is to make a nice "spec failures" report in the jenkins build instead of having to look at the log output
  junitReporter: {
    outputDir: 'coverage-js/junit-reports',
    outputFile: `karma-${process.env.JSPEC_GROUP || 'all'}.xml`,
    useBrowserName: false, // don't add browser name to report and classes names
  },
  specReporter: {
    maxLogLines: 50, // limit number of lines logged per test
    suppressErrorSummary: false, // print error summary
    showSpecTiming: true, // print the time elapsed for each spec
  },

  port: 9876,

  colors: true,

  autoWatch: true,

  // - Chrome
  // - ChromeCanary
  // - ChromeHeadless
  // - Firefox
  // - Opera (has to be installed with `npm install karma-opera-launcher`)
  // - Safari (only Mac; has to be installed with `npm install karma-safari-launcher`)
  // - PhantomJS (has to be installed with `npm install karma-phantomjs-launcher`))
  // - IE (only Windows; has to be installed with `npm install karma-ie-launcher`)
  browsers: ['Chrome'],

  // Run headless chrome with `karma start --browsers ChromeHeadlessNoSandbox`
  customLaunchers: {
    ChromeHeadlessNoSandbox: {
      base: 'ChromeHeadless',
      flags: ['--no-sandbox'] // needed for running tests in local docker
    }
  },

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
  singleRun: false,

  files: [
    {pattern: 'spec/javascripts/webpack_spec_index.js', included: true, served: true},
    {pattern: 'spec/javascripts/fixtures/*', included: false, served: true},
    {pattern: 'public/dist/brandable_css/**/*.css', included: false, served: true},
  ],

  preprocessors: {
    'spec/javascripts/webpack_spec_index.js': ['webpack']
  },

  webpack: require('./webpack.test.config'),
}

// For faster local debugging in karma, only add istanbul cruft you've explicity set the "COVERAGE" environment variable
if (process.env.COVERAGE) {
  karmaConfig.reporters.push('coverage-istanbul')
  karmaConfig.coverageIstanbulReporter = {
    reports: ['html', 'json'],
    dir: 'coverage-karma/',
    fixWebpackSourcePaths: true
  }
  karmaConfig.webpack.module.rules.unshift({
    test: /\.(js|coffee)$/,
    use: {
      loader: 'istanbul-instrumenter-loader',
      options: { esModules: true, produceSourceMap: true }
    },
    enforce: 'post',
    exclude: /(node_modules|spec|public\/javascripts\/(bower|client_apps|translations|vendor|custom_moment_locales|custom_timezone_locales))/,
  })
}

module.exports = function (config) {
  // config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
  karmaConfig.logLevel = config.LOG_INFO
  config.set(karmaConfig)
}
