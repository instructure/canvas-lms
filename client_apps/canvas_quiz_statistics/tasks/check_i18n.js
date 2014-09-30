var glob = require('glob');
var fs = require('fs');
var path = require('path');
var child_process = require('child_process');

module.exports = {
  description: 'Run the compiled CQS JavaScript through the Canvas I18n parser.',
  runner: function(grunt) {
    var rawScript = fs.readFileSync(path.join(__dirname, 'check_i18n', 'script.rb'));
    var gemPath = path.join(__dirname, '..', '..', '..', 'gems', 'i18n_extraction');
    var scriptName = '.__check_i18n.rb';
    var scriptPath = path.join(gemPath, scriptName);
    var targetPath = path.join(__dirname, '..', 'dist', grunt.moduleId + '.js');
    var done = this.async();
    var child;

    console.log('Running things in:', gemPath);

    if (!fs.existsSync(scriptPath)) {
      fs.writeFileSync(scriptPath, rawScript);
      console.log('Script created at:', scriptPath);
    }

    console.log('Running script using "bundle exec"');
    child = child_process.exec("bundle exec ruby " + scriptName + ' ' + targetPath, {
      cwd: gemPath
    }, function (error, stdout, stderr) {
      console.log(stdout);
      console.log(stderr);
      // if (error !== null) {
      //   console.log('exec error: ' + error);
      // }
    });

    child.on('exit', function() {
      console.log('Done!');

      fs.unlinkSync(scriptPath);
      done()
    });
  }
};