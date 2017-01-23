module.exports = {
  description: 'Serve the application using a local Connect server.',
  runner (grunt, appName) {
    const availableApps = grunt.file.expand('apps/*').filter(name => name !== 'apps/common').map(name => name.substr(5));

    if (availableApps.indexOf(appName) === -1) {
      grunt.fail.fatal(
        `${'You must specify an app name to serve.\n' +
        'Available apps are: '}${JSON.stringify(availableApps)}\n` +
        `For example: \`grunt server:${availableApps[0]}\``
      );
    }

    grunt.config.set('currentApp', appName);
    grunt.task.run([
      'development',
      'configureRewriteRules',
      'configureProxies:www',
      'connect:www',
      'connect:tests',
      'connect:docs',
      'watch'
    ]);
  }
};
