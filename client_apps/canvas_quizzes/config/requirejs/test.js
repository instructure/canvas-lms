/* global requirejs: false, jasmine: false */
requirejs.config({
  map: {
    'jasmine_react': {
      'jquery': '../../../vendor/packages/jquery'
    },

    'canvas_quizzes/config': {
      'app': '../js'
    },

    '*': {
      'react': '../../../vendor/js/alias_to_old_version_of_react',
      'str': 'canvas/str',
      'jsx/railsFlashNotificationsHelper': 'canvas/jsx/railsFlashNotificationsHelper'
    }
  },

  paths: {
    'json': '../../../vendor/js/require/json',
    'jasmine_rsvp': '../../../node_modules/jasmine_rsvp/dist/jasmine_rsvp-full',
    'jasmine_xhr': '../../../node_modules/jasmine_xhr/dist/jasmine_xhr',
    'jasmine_react': '../../../node_modules/jasmine_react/dist/jasmine_react',

    'test': '../test',
    'fixtures': '../test/fixtures',
    'canvas_quizzes': '../../common/js',
    'canvas_app': '../../vendor/canvas_app'
  },

  deps: [
    'json',
    'jasmine_react',
    'jasmine_rsvp',
    'jasmine_xhr',
  ],

  waitSeconds: 5,

  config: {
    'canvas_quizzes/config': {
      environment: 'test'
    }
  },

  callback: function() {
    // Avoid infinite loop in the pretty printer when trying to print objects
    // with circular references.
    jasmine.MAX_PRETTY_PRINT_DEPTH = 3;

    // Hide the global "launchTest" that the grunt-contrib-requirejs-template
    // unconditionally calls without respecting our callback; we must initialize
    // the app before any of the specs are run.
    var go = this.launchTest;
    this.launchTest = function() {};

    // this script actually starts the tests, must be the last one:
    require([ 'config' ], function(config) {
      config.onLoad(function() {
        require([ 'test/boot' ], function(boot) {
          if (boot instanceof Function) {
            boot(go); // boot file is async
          }
          else {
            go(); // boot file is synchronous and requires no callback
          }
        }, go); // no boot file
      });
    }, go); // no app config file
  }
});