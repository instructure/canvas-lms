module.exports = {
  description: 'Run the Jasmine unit tests.',
  runner: function(grunt, target) {
    grunt.task.run('connect:tests');
    grunt.task.run('jasmine:' + (target || ''));
  }
};