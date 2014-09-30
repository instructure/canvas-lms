/* jshint node:true */
var grunt = require('grunt');
var readPackage = function() {
  return grunt.file.readJSON('package.json');
};

grunt.loadNpmTasks('grunt-contrib-watch');
grunt.loadNpmTasks('grunt-contrib-connect');
grunt.loadNpmTasks('grunt-connect-rewrite');
grunt.loadNpmTasks('grunt-connect-proxy');
grunt.loadNpmTasks('grunt-contrib-jasmine');
grunt.loadNpmTasks('grunt-jsduck');
grunt.loadNpmTasks('grunt-contrib-jshint');
grunt.loadNpmTasks('grunt-notify');
grunt.loadNpmTasks('grunt-newer');
grunt.loadNpmTasks('grunt-sass');

grunt.registerTask('default', [
  'server:background',
  'connect:tests',
  'watch'
]);

grunt.registerTask('updatePkg', function () {
  grunt.config.set('pkg', readPackage());
});

grunt.util.loadOptions('./tasks/development/options/');
grunt.util.loadTasks('./tasks/development');
