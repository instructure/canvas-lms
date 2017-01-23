module.exports = {
  description: 'Use the development, non-optimized JS sources.',
  runner (grunt) {
    grunt.task.run('compile_css');
  }
};
