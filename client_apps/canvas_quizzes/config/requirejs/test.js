/* global requirejs: false, jasmine: false */
requirejs.config({
  map: {
    'jasmine_react': {
      'jquery': '../../../vendor/packages/jquery'
    },

    'canvas_quizzes/config': {
      'app': '../js'
    }
  },

  paths: {
    'json': '../../../vendor/js/require/json',
    'jasmine_rsvp': '../../../node_modules/jasmine_rsvp/dist/jasmine_rsvp-full',
    'jasmine_xhr': '../../../node_modules/jasmine_xhr/dist/jasmine_xhr',
    'jasmine_react': '../../../node_modules/jasmine_react/dist/jasmine_react',

    'test': '../test',
    'fixtures': '../test/fixtures',
    'canvas_quizzes': '../../common/js'
  },

  deps: [
    'json',
    'jasmine_react',
    'jasmine_rsvp',
    'jasmine_xhr',
  ],

  waitSeconds: 5,

  callback: function() {
    this.__TESTING__ = true;

    // Avoid infinite loop in the pretty printer when trying to print objects
    // with circular references.
    jasmine.MAX_PRETTY_PRINT_DEPTH = 3;

    // Hide the global "launchTest" that the grunt-contrib-requirejs-template
    // unconditionally calls without respecting our callback; we must initialize
    // the app before any of the specs are run.
    this.launchTests = this.launchTest;
    this.launchTest = function() {};

    // this script actually starts the tests, must be the last one:
    require([ 'test/boot' ], function(boot) {
      if (boot instanceof Function) {
        boot(this.launchTests);
      }
      else {
        this.launchTests();
      }
    }, this.launchTests);
  }
});