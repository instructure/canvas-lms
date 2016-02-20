define(function(require, exports, module) {
  var _ = require('lodash');
  var config = require('./config/environments/production');
  var testConfig = require('./config/environments/test');
  var devConfig = require('./config/environments/development');

  var callbacks = [];
  var loaded;

  if (!config) {
    config = {};
  }

  config.onLoad = function(callback) {
    if (loaded) {
      callback();
    }
    else {
      callbacks.push(callback);
    }
  };

  //>>excludeStart("production", pragmas.production);
  var env = "development"
  if(typeof(module.config) !== "undefined" && module.config().environment){
    env = module.config().environment
  }

  var extend = _.extend;
  var onLoad = function() {
    console.log('\tLoaded', env, 'config.');
    loaded = true;

    while (callbacks.length) {
      callbacks.shift()();
    }
  };

  console.log('Environment:', env);

  // Install test config:
  if (env === 'test') {
    extend(config, testConfig);
    onLoad();
  }
  else {
    var global = window;
    var DEBUG = {};

    // You can use this in development_local.js to expose certain modules that
    // are hard to reach from the console. Example:
    //
    //   DEBUG.expose('stores/reports', 'reportStore');
    //   DEBUG.reportStore; // ReportStore
    DEBUG.expose = function(script, varName) {
      require([ script ], function(__script__) {
        DEBUG[varName] = __script__;
      });
    };

    global.DEBUG = global.d = DEBUG;
    extend(config, devConfig);
    onLoad();
  }
  //>>excludeEnd("production");

  return config;
});
