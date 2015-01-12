var fs = require('fs-extra');
var glob = require('glob');
var path = require('path');
var transform = require('react-tools').transform;
var convertTextBlocks = require('canvas_react_i18n');

var processJSX = function(rawJSX) {
  return transform(convertTextBlocks(rawJSX));
};

module.exports = function(srcDir, destDir) {
  if (!destDir) {
    destDir = srcDir;
  }

  glob.sync('**/*.jsx', { cwd: srcDir }).forEach(function(file) {
    var compiled, outfile;

    console.log('Compiling JSX:', file);

    compiled = processJSX(fs.readFileSync(path.join(srcDir, file), 'utf8'));
    outfile = path.join(destDir, file.replace(/\.jsx$/, '.js'));

    fs.ensureDirSync(path.dirname(outfile));
    fs.writeFileSync(outfile, compiled);
  });
};