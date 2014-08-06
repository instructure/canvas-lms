/* global requirejs: false, jasmine: false */
requirejs.config({
  baseUrl: './src/js',
  map: {
    '*': {
      'test': '../../test',
      'fixtures': 'test/fixtures'
    }
  },

  paths: {
    'json': '../../vendor/js/require/json',
    'jasmine_rsvp': '../../node_modules/jasmine_rsvp/dist/jasmine_rsvp-full',
    'jasmine_xhr': '../../node_modules/jasmine_xhr/dist/jasmine_xhr',

    // jasmine_react dependencies:
    'jquery': '../../node_modules/jquery/dist/jquery',
    'react': '../../vendor/packages/react-with-addons',
    'jasmine_react': '../../node_modules/jasmine_react/dist/jasmine_react',
  },

  deps: [
    'json',
    'jasmine_react',
    'jasmine_rsvp',
    'jasmine_xhr',
  ],

  waitSeconds: 1,

  callback: function() {
    this.__TESTING__ = true;

    // Avoid infinite loop in the pretty printer when trying to print objects with
    // circular references.
    jasmine.MAX_PRETTY_PRINT_DEPTH = 3;

    // Hide the global "launchTest" that the grunt-contrib-requirejs-template
    // unconditionally calls without respecting our callback. We must initialize
    // the app before any of the specs are run.
    this.launchTests = this.launchTest;
    this.launchTest = function() {};

    require([ 'test/boot' ], function() {});
  }
});