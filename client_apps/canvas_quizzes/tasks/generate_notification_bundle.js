var shell = require('shelljs');
var fs = require('fs');
var path = require('path');
var glob = require('glob');

module.exports = {
  description: 'Generate the notification bundle.',
  runner: function(grunt, target) {
    var root = grunt.paths.root;
    var outPath = path.join(root, 'src/js/bundles/notifications.js');
    var BUNDLE_PATH = path.join(root, 'src/js/notifications');
    var scripts = glob.sync('*.js', { cwd: BUNDLE_PATH }).reduce(function(set, script) {
      return set.concat(script.replace(/\.js$/, ''));
    }, []);

    var template =
      '/** WARNING: AUTO-GENERATED, DO NOT EDIT */\n' +
      'define([' +
        scripts.map(function(script) {
          return '"../notifications/' + script + '"';
        }).join(',\n') +
      '], function() {\nreturn [].slice.call(arguments);\n});';

    fs.writeFileSync(outPath, template);

    console.log('Notification bundle written to ' + outPath);
  }
};