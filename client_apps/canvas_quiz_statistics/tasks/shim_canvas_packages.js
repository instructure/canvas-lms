/* jshint node:true */

var glob = require('glob');
var PKG_PATH = 'vendor/packages';
var PKG_PATH_RJS = '../../vendor/packages';
var _ = require('lodash');
var merge = _.merge;
var keys = _.keys;

module.exports = {
  description: 'Exclude Canvas packages from the distributable version of the app.',
  runner: function(grunt) {
    // Look for all the packages in vendor/packages/**/*.js and create an "empty:"
    // map containing all the package paths.
    //
    // For example, the following files will produce the map below:
    //   /vendor/packages/jquery.js
    //   /vendor/packages/jqueryui/dialog.js
    //
    //   {
    //     "../../vendor/packages/jquery": "empty:",
    //     "../../vendor/packages/jqueryui/dialog": "empty:",
    //   }
    //
    var pkgMap = glob.sync('**/*.js', { cwd: PKG_PATH }).reduce(function(set, pkg) {
      var pkgName = pkg.replace(/\.js$/, '');
      set[PKG_PATH_RJS + '/' + pkgName] = 'empty:';
      return set;
    }, {});

    // Go through each requirejs build target and munge the "paths" map with
    // our shimmed packages one:
    keys(grunt.config.get('requirejs')).forEach(function(target) {
      var configKey = [ 'requirejs', target, 'options' ].join('.');
      var targetOptions = grunt.config.get(configKey);

      grunt.config.set(configKey, merge({}, targetOptions, { paths: pkgMap }));
    });
  }
};