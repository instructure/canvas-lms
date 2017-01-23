const fs = require('fs-extra');
const glob = require('glob');
const path = require('path');
const transform = require('react-tools').transform;
const convertTextBlocks = require('canvas_react_i18n');

const processJSX = function (rawJSX) {
  return transform(convertTextBlocks(rawJSX));
};

module.exports = function (srcDir, destDir) {
  if (!destDir) {
    destDir = srcDir;
  }

  glob.sync('**/*.jsx', { cwd: srcDir }).forEach((file) => {
    let compiled,
      outfile;

    console.log('Compiling JSX:', file);

    compiled = processJSX(fs.readFileSync(path.join(srcDir, file), 'utf8'));
    outfile = path.join(destDir, file.replace(/\.jsx$/, '.js'));

    fs.ensureDirSync(path.dirname(outfile));
    fs.writeFileSync(outfile, compiled);
  });
};
