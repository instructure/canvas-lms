var glob = require('glob');
var fs = require('fs');
var path = require('path');
var child_process = require('child_process');

module.exports = {
  description: 'Run the compiled CQS JavaScript through the Canvas I18n parser.',
  runner: function(grunt) {
    var rootPath = path.join(__dirname, '..', '..', '..');
    var targetPath = path.join('client_apps', grunt.moduleId, 'dist');
    var targetFile = grunt.moduleId + '.js';
    var done = this.async();
    var child;

    console.log('Running script"');
    child = child_process.exec("gems/canvas_i18nliner/bin/i18nliner check --directory " + targetPath + " --only " + targetFile, {
      cwd: rootPath
    }, function (error, stdout, stderr) {
      console.log(stdout);
      console.log(stderr);
    });

    child.on('exit', function() {
      console.log('Done!');
      done()
    });
  }
};
