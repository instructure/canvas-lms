var shell = require('shelljs');
var glob = require('glob');
var printHelp = function() {
  console.log('Usage: grunt report:TARGET');
  console.log('\nAvailable targets:');
  console.log('  - "lodash_methods": print all the used lodash methods');
};

var printAvailablePackages = function() {
  var PKG_PATH = 'vendor/packages';
  var pkgNames = glob.sync('**/*.js', { cwd: PKG_PATH }).reduce(function(set, pkg) {
    var pkgName = pkg.replace(/\.js$/, '');
    return set.concat(pkgName);
  }, []);

  console.log('There are', pkgNames.length, 'available packages:\n');

  pkgNames.forEach(function(pkgName, index) {
    console.log('  ' + (index+1) + '.', pkgName);
  });
};

module.exports = {
  description: 'Use the development, non-optimized JS sources.',
  runner: function(grunt, target) {
    switch(target) {
      case 'lodash_methods':
        shell.exec("echo 'Reporting used lodash methods:'");
        shell.exec("grep -rPoh '_\\.[^\\b|\\(|;]+' src/js/ | sort | uniq");
      break;
      case 'available_packages':
        printAvailablePackages();
      break;
      default:
        printHelp();
    }
  }
};