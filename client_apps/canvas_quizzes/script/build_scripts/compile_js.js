#!/usr/bin/env node

const fs = require('fs-extra');
const path = require('path');
const glob = require('glob');
const requirejs = require('requirejs');
const _ = require('lodash');
const K = require('./constants');
const generateRuntimeLoaderConfig = require('./generate_runtime_loader_config');
const runtimeStartFragment = fs.readFileSync('config/requirejs/runtime_start.frag.tmpl.js', 'utf8');
const runtimeEndFragment = fs.readFileSync('config/requirejs/runtime_end.frag.tmpl.js', 'utf8');

const merge = _.merge;
const extend = _.extend;
const template = _.template;

const PKG_NAME = K.pkgName;
const APP_NAMES = K.appNames;

module.exports = function (onSuccess, onError) {
  let config;
  const commonModuleId = PKG_NAME;

  // We'll use the dev config as the base for the build config:
  const devConfig = require('./extract_development_config')();

  // The list of all module IDs to include in the common script.
  const commonModules = require('./extract_common_modules')();

  // The following value will be used as an r.js "bundle" entry to the common
  // script so that it knows which modules are defined in that file.
  const commonBundle = require('./extract_common_bundle')(commonModules);

  const canvasPackageStubs = require('./generate_canvas_package_stubs')();

  config = extend({}, devConfig);
  config.baseUrl = '.';
  config.appDir = 'tmp/compiled/js';
  config.dir = 'tmp/dist';
  config.optimize = 'none';
  config.skipDirOptimize = true;
  config.removeCombined = false;
  config.inlineText = true;
  config.preserveLicenseComments = false;

  config.pragmas = {
    production: true
  };

  config.jsx = {
    fileExtension: '.jsx',
    moduleId: ''
  };

  config.paths = extend({}, {
    // defer the resolution of config files until an app's bundle is loaded:
    config: 'empty:',
    'app/config/environments/production': 'empty:',
  }, devConfig.paths, canvasPackageStubs);

  config.onBuildWrite = function (moduleName, modulePath, contents) {
    return contents
      // Text and JSX modules get inlined by the post-processor and become
      // regular modules so get rid of the plugin prefix in module ids:
      .replace(/(text!|jsx!)/g, '')

      // Rewrite all modules that start with "canvas_packages/" to be without
      // that prefix since when they're embedded in Canvas, the module IDs will
      // just match:
      .replace(/(['"])canvas_packages\//g, '$1');
  };

  config.modules = [];

  // The "common" bundle:
  config.modules.push({
    name: commonModuleId,
    create: true,
    include: commonModules,
    exclude: ['text', 'jsx', 'i18n']
  });

  APP_NAMES.forEach((appName) => {
    let override;
    const appModuleId = [commonModuleId, 'apps', appName, 'main'].join('/');

    // This is the ID people will use to require the app module:
    const appPublicModuleId = [commonModuleId, 'apps', appName].join('/');

    const appConfig = {};
    const runtimeConfig = generateRuntimeLoaderConfig(commonBundle, appName);

    appConfig.name = appModuleId;

    // We need the "common" bundle to be loaded before the actual app bundle:
    appConfig.deps = [commonModuleId];

    // The app's config file must be explicitly included because it's loaded
    // only by the config loader found in the common bundle:
    appConfig.include = [
      `${appPublicModuleId}/config/environments/production`
    ];

    appConfig.exclude = [
      'text',
      'jsx',
      'i18n',
      commonModuleId
    ];

    override = appConfig.override = {};
    override.wrap = {
      // requirejs.config() call for runtime:
      start: template(runtimeStartFragment, {
        appName: `${PKG_NAME}::${appName}`,
        rjsConfig: runtimeConfig,
      }),

      // public module alias definition:
      end: template(runtimeEndFragment, {
        moduleId: appModuleId,
        publicModuleId: appPublicModuleId
      })
    };

    config.modules.push(appConfig);
  });

  return requirejs.optimize(config, onSuccess, onError);
};
