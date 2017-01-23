const compileJSX = require('script/build_scripts/compile_jsx');
const fs = require('fs-extra');

module.exports = {
  description: 'Compile the JSX sources for post-processing (like docs, or jshint).',
  runner (grunt) {
    fs.ensureDirSync('tmp/compiled_jsx');
    compileJSX('apps', 'tmp/compiled_jsx');
  }
};
