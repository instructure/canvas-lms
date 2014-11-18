define(function(require) {
  var _ = require('lodash');
  var config = require('app/config/environments/production');

  if (!config) {
    config = {};
  }

  //>>excludeStart("production", pragmas.production);
  console.log('Environment:', this.__TESTING__ ? 'test' : 'development');

  // Install test config:
  if (this.__TESTING__) {
    require([ 'app/config/environments/test' ], function(testConfig) {
      config = _.extend({}, config, testConfig);
    });
  }
  else {
    var extend = _.extend;
    var loadLocalConfig = function() {
      // Install development and local config:
      require([ 'app/config/environments/development_local' ], function(localConfig) {
        extend(config, localConfig);
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
    };

    require([ 'app/config/environments/development' ], function(devConfig) {
      extend(config, devConfig);
      loadLocalConfig();
    }, function(e) {
      // don't whine if the files don't exist:
      if (e.requireType === 'scripterror') {
        console.info(
          'Hint: you can set up a development-only configuration in',
          '"config/environments/development.js".');

        loadLocalConfig();
      } else {
        throw e;
      }
    });
  }
  //>>excludeEnd("production");

  return config;
});