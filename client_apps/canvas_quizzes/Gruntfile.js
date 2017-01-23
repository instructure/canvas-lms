/* jshint node:true */

const glob = require('glob');
const grunt = require('grunt');

process.env.NODE_PATH = __dirname;
require('module').Module._initPaths();

const readPackage = function () {
  return grunt.file.readJSON('package.json');
};

const loadOptions = function (path) {
  glob.sync('*', { cwd: path }).forEach((option) => {
    const key = option.replace(/\.js$/, '').replace(/^grunt\-/, '');
    grunt.config.set(key, require(path + option));
  });
};

const loadTasks = function (path) {
  glob.sync('*.js', { cwd: path }).forEach((taskFile) => {
    let taskRunner;
    const task = require(`${path}/${taskFile}`);
    const taskName = taskFile.replace(/\.js$/, '');

    taskRunner = task.runner;

    if (taskRunner instanceof Function) {
      taskRunner = function () {
        const params = [].slice.call(arguments);
        params.unshift(grunt);
        return task.runner.apply(this, params);
      };
    }

    grunt.registerTask(taskName, task.description, taskRunner);
  });
};

module.exports = function () {
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
