fs = require 'fs'

module.exports = (grunt) ->

  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)

  grunt.initConfig
    watch:
      testTemplates:
        files: ['test/**/*.hbs']
        tasks: ['emberTemplates:test']
      build:
        files: ['lib/**/*.{js,hbs}', 'main.js']
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
          'main.js'
        ]
        dest: 'dist/main.js'

    clean:
      build: ['build']

  grunt.registerTask 'build', ['clean:build', 'emberTemplates', 'wrapTemplates', 'concat']
  grunt.registerTask 'default', ['build', 'watch']

  grunt.registerTask 'wrapTemplates', ->
    templatePath = './lib/templates.js'
    templatesSource = fs.readFileSync(templatePath).toString()
    src = """
+function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(['ember'], function(Ember) { return factory(Ember); });
  } else if (typeof exports === 'object') {
    factory(require('ember'));
  } else {
    factory(Ember);
  }
}(this, function(Ember) {

#{templatesSource}

});
    """
    fs.writeFileSync templatePath, src

