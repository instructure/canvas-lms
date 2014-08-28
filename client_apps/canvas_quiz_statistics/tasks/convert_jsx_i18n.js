var glob = require('glob');
var fs = require('fs');
var convert = require('canvas_react_i18n');

module.exports = {
  description: 'Convert <Text /> blocks in JSX to Canvas-compatible I18n calls.',
  runner: function(grunt) {
    var path = 'tmp/js/canvas_quiz_statistics';

    glob.sync('**/*.jsx', { cwd: path }).forEach(function(fileName) {
      var filePath = path + '/' + fileName;
      var contents = String(fs.readFileSync(filePath));
      var newContents = convert(contents);

      if (newContents !== contents) {
        console.log('Found <Text /> in', filePath);

        fs.writeFileSync(filePath, newContents);
      }
    });
  }
};