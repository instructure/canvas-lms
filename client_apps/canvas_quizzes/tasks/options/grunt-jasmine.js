var _ = require('lodash');
var fs = require('fs');
var grunt = require('grunt');
var merge = _.merge;

var PKG_NAME = grunt.config.get('pkg.name');

// Test config shared between all the app suites:
var SHARED_CONFIG = {
  timeout: 2500,

  host: "http://127.0.0.1:<%= grunt.config.get('connect.tests.options.port') %>/",

  template: require('grunt-template-jasmine-requirejs'),
  templateOptions: {
    deferHelpers: true,
    defaultErrors: true,

    requireConfigFile: [
      'config/requirejs/development.js',
      'config/requirejs/test.js'
    ]
  },

  // we'll keep the generated runner in case you want to try the tests out in
  // a browser; run `grunt connect:tests:keepalive` and open a /tests.html
  keepRunner: true,
  outfile: 'tests.html',

  version: '2.0.0',

  styles: [
    "vendor/canvas_public/stylesheets_compiled/new_styles_normal_contrast/pages/g_vendor.css",
    "vendor/canvas_public/stylesheets_compiled/new_styles_normal_contrast/base/c-common.css",
    "dist/<%= grunt.config.get('pkg.name') %>.css"
  ]
};

var appNames = [ 'common', 'events', 'statistics' ];
var config = appNames.reduce(function(config, appName) {
  var pathTo = function(path) {
    return [ 'apps', appName, path ].join('/');
  };

  var configFile = pathTo('test/config.js');
  var cssFile = pathTo('test/overrides.css');
  var appConfig = merge({}, SHARED_CONFIG);

  appConfig.helpers = [
    'apps/common/test/helpers/*.js',
    pathTo('test/helpers/*.js'),
  ];

  appConfig.specs = [
    pathTo('test/**/*_test.js')
  ];

  if (fs.existsSync(cssFile)) {
    appConfig.styles = SHARED_CONFIG.styles.concat([ cssFile ]);
  }

  if (fs.existsSync(configFile)) {
    appConfig.templateOptions.requireConfigFile.push(configFile);
  }

  // this allows spec files to require() modules from the app's sources
  // directly without any prefix (or relative paths, for the matter):
  appConfig.templateOptions.requireConfig = {
    baseUrl: pathTo('js')
  };

  config[appName] = { options: appConfig };

  return config;
}, {});

module.exports = config;