module.exports = {
  unit: {
    options : {
      timeout: 10000,
      outfile: 'tests.html',

      host: 'http://127.0.0.1:<%= grunt.config.get("connect.tests.options.port") %>/',

      template: require('grunt-template-jasmine-requirejs'),
      templateOptions: {
        requireConfigFile: [
          'src/js/main.js',
          'test/config.js',
        ],
        deferHelpers: true,
        defaultErrors: true
      },

      keepRunner: true,

      version: '2.0.0',

      styles: [ "www/dist/<%= grunt.moduleId %>.css" ],

      helpers: [
        'test/support/*.js',
        'test/helpers/*.js',
      ],

      specs: [
        'test/unit/**/*.js'
      ]
    }
  }
};