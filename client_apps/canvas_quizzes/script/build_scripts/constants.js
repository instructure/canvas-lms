const path = require('path');
const glob = require('glob');
const readJSON = require('../helpers/read_json');

const K = {};
const pkg = readJSON('package.json');
const root = path.join(__dirname, '..', '..');

K.root = root;
K.pkgName = pkg.name;

K.appNames = glob.sync('*/js/main.js', { cwd: path.join(root, 'apps') }).map(file => file.split('/')[0]).filter(appName => appName !== 'common');

K.bundledDependencies = pkg.requirejs.bundledDependencies;
K.commonRoot = 'apps/common';

K.require = function (relativePath) {
  return require(path.join(root, relativePath));
};

module.exports = K;
