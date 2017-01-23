define((require, exports, module) => {
  const _ = require('lodash');
  let config = require('app/config/environments/production');
  const callbacks = [];
  let loaded;

  if (!config) {
    config = {};
  }

  config.onLoad = function (callback) {
    if (loaded) {
      callback();
    } else {
      callbacks.push(callback);
    }
  };

    // >>excludeStart("production", pragmas.production);
  const env = module.config().environment || 'development';
  const extend = _.extend;
  const onLoad = function () {
    console.log('\tLoaded', env, 'config.');
    loaded = true;

    while (callbacks.length) {
      callbacks.shift()();
    }
  };

  console.log('Environment:', env);

    // Install test config:
  if (env === 'test') {
    require(['app/config/environments/test'], (testConfig) => {
      extend(config, testConfig);
      onLoad();
    }, onLoad);
  } else {
    const loadLocalConfig = function () {
        // Install development and local config:
      require(['app/config/environments/development_local'], (localConfig) => {
        extend(config, localConfig);
        onLoad();
      }, (e) => {
        if (e.requireType === 'scripterror') {
          onLoad();

            // don't whine if the files don't exist:
          console.info(
              'Hint: you can set up your own private, development-only configuration in',
              '"config/environments/development_local.js".');
        } else {
          throw e;
        }
      });
    };

    const global = window;
    const DEBUG = {};

      // You can use this in development_local.js to expose certain modules that
      // are hard to reach from the console. Example:
      //
      //   DEBUG.expose('stores/reports', 'reportStore');
      //   DEBUG.reportStore; // ReportStore
    DEBUG.expose = function (script, varName) {
      require([script], (__script__) => {
        DEBUG[varName] = __script__;
      });
    };

    global.DEBUG = global.d = DEBUG;

    require(['app/config/environments/development'], (devConfig) => {
      extend(config, devConfig);
      loadLocalConfig();
    }, (e) => {
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
    // >>excludeEnd("production");

  return config;
});
