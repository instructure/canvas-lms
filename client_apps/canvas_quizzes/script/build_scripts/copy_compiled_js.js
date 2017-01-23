const fs = require('fs-extra');
const path = require('path');
const K = require('./constants');
const PKG_NAME = K.pkgName;
const APP_NAMES = K.appNames;
const basePath = path.join(K.root, 'tmp', 'dist');
const destPath = path.join(K.root, 'dist');

module.exports = function () {
  // Each app module will be placed under /dist/PKG_NAME/apps/APP_NAME.js.
  //
  // The filepath matches the convenience module we've defined at build-time (
  // the one that does not contain "/main" in the module id).
  const files = APP_NAMES.map(appName => ({
    src: path.join(basePath, PKG_NAME, 'apps', appName, 'main.js'),
    dest: path.join(destPath, PKG_NAME, 'apps', `${appName}.js`)
  }));

  // The common bundle, which is named by the name of the package and not
  // inside /apps:
  files.unshift({
    src: path.join(basePath, `${PKG_NAME}.js`),
    dest: path.join(destPath, `${PKG_NAME}.js`)
  });

  files.forEach((descriptor, index) => {
    const src = descriptor.src;
    const dest = descriptor.dest;

    if (!fs.existsSync(src)) {
      console.error(`Expected built bundle to be found at '${src}' but was not.`);
      process.exit(1);
    }

    console.log(`Asset [${index + 1}]:`);

    fs.ensureDirSync(path.dirname(dest));
    fs.copySync(src, dest);

    console.log(`\t${dest}`);
  });
};
