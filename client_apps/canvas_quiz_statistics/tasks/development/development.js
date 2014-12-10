module.exports = {
  description: 'Use the development, non-optimized JS sources.',
  runner: function(grunt) {
    grunt.task.run('symlink:development');
    grunt.task.run('generate_notification_bundle');
    grunt.task.run('compile_css');
  }
};