/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(function(require, exports, module) {
  var _ = require('lodash');
    var config = require('app/config/environments/production');
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
    var env = module.config().environment || 'development';
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
      require([ 'app/config/environments/test' ], function(testConfig) {
        extend(config, testConfig);
        onLoad();
      }, onLoad);
    }
    else {
      var loadLocalConfig = function() {
        // Install development and local config:
        require([ 'app/config/environments/development_local' ], function(localConfig) {
          extend(config, localConfig);
          onLoad();
        }, function(e) {
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
