var grunt = require('grunt');

module.exports = {
  js: {
    options: {
      message: "<%= grunt.appName %> JS has been compiled.",
    }
  },

  css: {
    options: {
      message: "<%= grunt.appName %> CSS has been compiled."
    }
  },

  docs: {
    options: {
      message: "<%= grunt.appName %> API docs have been generated."
    }
  },
};