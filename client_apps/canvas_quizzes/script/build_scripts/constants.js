var path = require('path');
var glob = require('glob');
var readJSON = require('../helpers/read_json');

var K = {};
var pkg = readJSON('package.json');
var root = path.join(__dirname, '..', '..');

K.root = root;
K.pkgName = pkg.name;

K.appNames = glob.sync('*/js/main.js', { cwd: path.join(root, 'apps') }).map(function(file) {
  return file.split('/')[0];
}).filter(function(appName) {
  return appName !== 'common';
});

K.bundledDependencies = pkg.requirejs.bundledDependencies;
K.commonRoot = 'apps/common';

K.require = function(relativePath) {
  return require(path.join(root, relativePath));
};

module.exports = K;