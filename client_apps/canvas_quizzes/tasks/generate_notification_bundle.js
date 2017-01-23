const shell = require('shelljs');
const fs = require('fs');
const path = require('path');
const glob = require('glob');

module.exports = {
  description: 'Generate the notification bundle.',
  runner (grunt, target) {
    const root = grunt.paths.root;
    const outPath = path.join(root, 'src/js/bundles/notifications.js');
    const BUNDLE_PATH = path.join(root, 'src/js/notifications');
    const scripts = glob.sync('*.js', { cwd: BUNDLE_PATH }).reduce((set, script) => set.concat(script.replace(/\.js$/, '')), []);

    const template =
      `${'/** WARNING: AUTO-GENERATED, DO NOT EDIT */\n' +
      'define(['}${
        scripts.map(script => `"../notifications/${script}"`).join(',\n')
      }], function() {\nreturn [].slice.call(arguments);\n});`;

    fs.writeFileSync(outPath, template);

    console.log(`Notification bundle written to ${outPath}`);
  }
};
