fs = require 'fs'

module.exports = (grunt) ->

  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)

  grunt.initConfig
    watch:
      testTemplates:
        files: ['test/**/*.hbs']
        tasks: ['emberTemplates:test']
      build:
        files: ['lib/**/*.{js,hbs}', 'lib/main.js']
        tasks: ['build']

    emberTemplates:
      options:
        templateCompilerPath: 'bower_components/ember-template-compiler/index.js'
        handlebarsPath: 'bower_components/handlebars/handlebars.js'
      lib:
        options:
          templateBasePath: 'lib/templates/'
        files:
          'lib/templates.js': 'lib/templates/{,*/}*.hbs'
      test:
        options:
          templateBasePath: 'test/support/'
        files:
          'test/support/templates.js': 'test/support/{,*/}*.hbs'

    concat:
      build:
        src: [
          'lib/*/**/*.js'
          'lib/templates.js'
          'lib/main.js'
        ]
        dest: 'dist/main.js'

    clean:
      build: ['build']

  grunt.registerTask 'build', ['clean:build', 'emberTemplates', 'concat']
  grunt.registerTask 'default', ['build', 'watch']

