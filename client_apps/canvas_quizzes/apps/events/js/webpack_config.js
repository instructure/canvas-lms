let config = require('./config/environments/production');
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

if (process.env.NODE_ENV !== 'production') {
  const extend = require('lodash').extend;
  const onLoad = function () {
    console.log('\tLoaded', process.env.NODE_ENV, 'config.');
    loaded = true;

    while (callbacks.length) {
      callbacks.shift()();
    }
  };

  console.log('Environment:', process.env.NODE_ENV);

  const onEnvSpecificConfigLoaded = function (envSpecificConfig) {
    extend(config, envSpecificConfig);
    onLoad();
  }
  if (process.env.NODE_ENV === 'test') {
    require(['./config/environments/test'], onEnvSpecificConfigLoaded);
  } else {
    require(['./config/environments/development'], onEnvSpecificConfigLoaded);
  }
}

module.exports = config;
