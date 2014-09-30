module.exports = {
  description: 'Serve the application using a local Connect server.',
  runner: function(grunt, target) {
    if (target === 'background') {
      keepalive = '';
    }
    else {
      keepalive = 'keepalive';
    }

    grunt.task.run([
      'development',
      'configureRewriteRules',
      'configureProxies:www',
      'connect:www:' + keepalive
    ]);
  }
};