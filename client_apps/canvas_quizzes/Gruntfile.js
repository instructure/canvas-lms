/* jshint node:true */

var glob = require('glob');
var grunt = require('grunt');

process.env.NODE_PATH = __dirname;
require('module').Module._initPaths();

var readPackage = function() {
  return grunt.file.readJSON('package.json');
};

var loadOptions = function(path) {
  glob.sync('*', { cwd: path }).forEach(function(option) {
    var key = option.replace(/\.js$/,'').replace(/^grunt\-/, '');
    grunt.config.set(key, require(path + option));
  });
};

var loadTasks = function(path) {
  glob.sync('*.js', { cwd: path }).forEach(function(taskFile) {
    var taskRunner;
    var task = require(path + '/' + taskFile);
    var taskName = taskFile.replace(/\.js$/, '');

    taskRunner = task.runner;

    if (taskRunner instanceof Function) {
      taskRunner = function() {
        var params = [].slice.call(arguments);
        params.unshift(grunt);
        return task.runner.apply(this, params);
      };
    }

    grunt.registerTask(taskName, task.description, taskRunner);
  });
};

module.exports = function() {
  grunt.initConfig({
    pkg: readPackage()
  });

  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-connect');
  grunt.loadNpmTasks('grunt-connect-rewrite');
  grunt.loadNpmTasks('grunt-connect-proxy');
  grunt.loadNpmTasks('grunt-contrib-jasmine');
  grunt.loadNpmTasks('grunt-jsduck');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-sass');

  grunt.paths = {
    root: __dirname
  };

  loadOptions('./tasks/options/');
  loadTasks('./tasks');

  grunt.registerTask('default', 'server');
};
