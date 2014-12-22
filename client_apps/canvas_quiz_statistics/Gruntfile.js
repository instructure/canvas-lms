/* jshint node:true */

var glob = require('glob');
var grunt = require('grunt');

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
  'use strict';

  grunt.initConfig({
    pkg: readPackage()
  });

  grunt.loadNpmTasks('grunt-contrib-requirejs');
  grunt.loadNpmTasks('grunt-react');
  grunt.loadNpmTasks('grunt-contrib-symlink');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-copy');

  grunt.appName = 'Canvas Quiz Statistics';
  grunt.moduleId = 'canvas_quiz_statistics';
  grunt.paths = {
    root: __dirname,
    canvasPackageShims: 'tmp/canvas_package_shims.json'
  };

  grunt.util.loadOptions = loadOptions;
  grunt.util.loadTasks = loadTasks;

  loadOptions('./tasks/options/');
  loadTasks('./tasks');

  // Unless invoked using `npm run [sub-script] --production`
  if (process.env.NODE_ENV !== 'production') {
    require('./Gruntfile.development');
  }
};
