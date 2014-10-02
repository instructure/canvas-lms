requirejs.config({
  map: {
    '*': {
      // needed by a loader plugin, can't scope the mapping
      'timezone_core': 'canvas/timezone_core',
      'compiled': 'canvas/compiled'
    },

    'canvas/jquery.instructure_date_and_time': {
      'compiled/behaviors/authenticity_token': 'canvas/compiled/behaviors/authenticity_token',
      'jquery': 'canvas/vendor/jquery-1.7.2',
      'jqueryui': 'canvas/vendor/jqueryui',
      'timezone': 'canvas/timezone',
      'str/htmlEscape': 'canvas/str/htmlEscape',
      'jquery.keycodes': 'canvas/jquery.keycodes',
      'vendor/date': 'canvas/vendor/date',
    },

    'canvas/jquery.keycodes': {
      'jquery.instructure_date_and_time': 'canvas/jquery.instructure_date_and_time'
    },

    'canvas/timezone': {
      'timezone_plugin': 'canvas/timezone_plugin'
    },

    'canvas/timezone_core': {
      'vendor/timezone': 'canvas/vendor/timezone'
    },

    'canvas/vendor/date': {
      'vendor/date-js/parser': 'canvas/vendor/date-js/parser'
    },

    'canvas/vendor/date-js/parser': {
      'vendor/date-js/sugarpak': 'canvas/vendor/date-js/sugarpak'
    },

    'canvas/vendor/date-js/sugarpak': {
      'vendor/date-js/core': 'canvas/vendor/date-js/core'
    },

    'canvas/vendor/date-js/core': {
      'vendor/date-js/globalization/en-US': 'canvas/vendor/date-js/globalization/en-US'
    },
  }
});

define([ 'canvas/jquery.instructure_date_and_time' ], function() {
});