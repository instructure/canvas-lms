define([
  'require',
  'lodash',
  './config/environments/production',
], function(require, _, ProductionConfig) {
  var config = ProductionConfig || {};

  //>>excludeStart("production", pragmas.production);
  console.log('Environment:', this.__TESTING__ ? 'test' : 'development');

  // Install test config:
  if (this.__TESTING__) {
    require([ './config/environments/test' ], function(testConfig) {
      config = _.extend(config, testConfig);
    });
  }
  else {
    // Install development and local config:
    require([
      './config/environments/development',
      './config/environments/development_local'
    ], function(devConfig, localConfig) {
      config = _.extend(config, devConfig, localConfig);
    }, function(e) {
      if (e.requireType === 'scripterror') {
        // don't whine if the files don't exist:
        console.info(
          'Hint: you can set up your own private, development-only configuration in',
          '"config/environments/development_local.js".');
      } else {
        throw e;
      }
    });
  }
  //>>excludeEnd("production");

  return config;
});