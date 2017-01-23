const shell = require('shelljs');
const glob = require('glob');
const printHelp = function () {
  console.log('Usage: grunt report:TARGET');
  console.log('\nAvailable targets:');
  console.log('  - "lodash_methods": print all the used lodash methods');
};

const printAvailablePackages = function () {
  const PKG_PATH = 'vendor/packages';
  const pkgNames = glob.sync('**/*.js', { cwd: PKG_PATH }).reduce((set, pkg) => {
    const pkgName = pkg.replace(/\.js$/, '');
    return set.concat(pkgName);
  }, []);

  console.log('There are', pkgNames.length, 'available packages:\n');

  pkgNames.forEach((pkgName, index) => {
    console.log(`  ${index + 1}.`, pkgName);
  });
};

module.exports = {
  description: 'Use the development, non-optimized JS sources.',
  runner (grunt, target) {
    switch (target) {
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
