module.exports = function(config) {
  config.set({
    basePath: '',

    frameworks: ['qunit'],

    files: [
      'spec/javascripts/requirejs_config.js',
      'spec/javascripts/tests.js',
      'public/javascripts/vendor/require.js',
      'node_modules/karma-requirejs/lib/adapter.js',
      'spec/javascripts/support/sinon/sinon-1.7.3.js',
      'spec/javascripts/support/sinon/sinon-patch.js',
      'spec/javascripts/support/sinon/sinon-qunit-1.0.0.js',
      {pattern: 'public/javascripts/*.js', included: false, served: true},
      {pattern: 'spec/javascripts/fixtures/*.html', included: false, served: true},
      {pattern: 'spec/javascripts/tests.js', included: false, served: true},
      {pattern: 'spec/javascripts/compiled/*.js', included: false, served: true},
      {pattern: 'spec/javascripts/compiled/**/*.js', included: false, served: true},
      {pattern: 'spec/**/javascripts/compiled/**/*.js', included: false, served: true},
      {pattern: 'spec/javascripts/fixtures/*', included: false, served: true},
      {pattern: 'public/javascripts/**/*.js', included: false, served: true},
      'spec/javascripts/load_tests.js'
    ],

    exclude: [],

    // 'dots', 'progress', 'junit', 'growl', 'coverage', 'spec'
    reporters: ['progress'],

    port: 9876,

    colors: true,

    // config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,

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

    // Continuous Integration mode
    // if true, it capture browsers, run tests and exit
    singleRun: false
  });
};
