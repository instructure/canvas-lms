/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

const addrPromise = new Promise(resolve => {
  require('dns').lookup(require('os').hostname(), function (_1, addr, _2) {
    resolve(addr)
  })
})

const karmaConfig = {
  basePath: '',

  frameworks: ['qunit', 'webpack'],

  proxies: {
    '/dist/brandable_css/': '/base/public/dist/brandable_css/',
    '/images/': '/base/public/images/',
  },

  exclude: [],

  // 'dots', 'progress', 'junit', 'growl', 'coverage', 'spec'
  reporters: ['spec', 'junit'],
  // enable the verbose reporter if you want to have more information of where/how specs fail
  // reporters: ['verbose'],

  // this is to make a nice "spec failures" report in the jenkins build instead of having to look at the log output
  junitReporter: {
    outputDir: process.env.TEST_RESULT_OUTPUT_DIR || 'coverage-js/junit-reports',
    outputFile: `karma-${process.env.JSPEC_GROUP || 'all'}.xml`,
    useBrowserName: false, // don't add browser name to report and classes names
  },
  specReporter: {
    maxLogLines: 50, // limit number of lines logged per test
    suppressErrorSummary: false, // print error summary
    showSpecTiming: true, // print the time elapsed for each spec
  },

  port: process.env.KARMA_PORT || 9876,

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
  browsers: [process.env.KARMA_BROWSER || 'ChromeHeadlessNoSandbox'], // docker friendly

  customLaunchers: {
    // Chrome will sometimes be in the background when specs are running,
    // leading to different behavior with things like event propagation, which
    // leads easily to bugs in production and/or spec code. To decrease the
    // chances of this, render backgrounding must be disabled when launching
    // Chrome.
    ChromeWithoutBackground: {
      base: 'Chrome',
      flags: ['--disable-renderer-backgrounding'],
    },

    // Run headless chrome with `karma start --browsers ChromeHeadlessNoSandbox`
    ChromeHeadlessNoSandbox: {
      base: 'ChromeHeadless',
      flags: ['--no-sandbox', '--disable-renderer-backgrounding'], // needed for running tests in local docker
    },

    ChromeSeleniumGridHeadless: {
      base: 'SeleniumGrid',
      gridUrl: 'http://selenium-hub:4444/wd/hub',
      browserName: 'chrome',
      arguments: ['--no-sandbox', '--headless', '--disable-renderer-backgrounding'],
    },
  },

  // If browser does not capture in given timeout [ms], kill it
  captureTimeout: 60000,

  browserDisconnectTimeout: 100000,
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
  ].concat(process.env.JSPEC_PATH ? process.env.JSPEC_PATH.split(' ') : []),

  preprocessors: {
    'spec/javascripts/webpack_spec_index.js': ['webpack'],
    '**/*Spec.js': ['webpack'],
    '**/*Spec.jsx': ['webpack'],
  },

  webpack: require('./ui-build/webpack-for-karma'),
}

// For faster local debugging in karma, only add istanbul cruft you've explicity set the "COVERAGE" environment variable
if (process.env.COVERAGE === '1') {
  karmaConfig.reporters.push('coverage-istanbul')
  karmaConfig.coverageIstanbulReporter = {
    reports: ['html', 'json'],
    dir: 'coverage-karma/',
    fixWebpackSourcePaths: true,
  }
  karmaConfig.webpack.module.rules.unshift({
    test: /\.(js|jsx|ts|tsx|coffee)$/,
    use: {
      loader: 'coverage-istanbul-loader',
      options: {esModules: true, produceSourceMap: true},
    },
    enforce: 'post',
    exclude:
      /(node_modules|spec|public\/javascripts\/(bower|canvas_quizzes|translations|vendor|custom_moment_locales|custom_timezone_locales))/,
  })
}

module.exports = async config => {
  karmaConfig.hostname = await addrPromise

  // config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
  karmaConfig.logLevel = config.LOG_INFO
  config.set(karmaConfig)
  // Allow passing in FORCED_FAILURE=true env variable to force failures in karma specs
  config.set({
    client: {
      args: process.env.FORCE_FAILURE === '1' ? ['FORCE_FAILURE'] : [],
    },
  })
}
