requirejs.config({
  paths: {
  },

  map: {
    '*': {
      // needed by a loader plugin, can't scope the mapping
      'timezone_core': 'canvas/timezone_core',
      'moment': 'canvas/moment',
      'moment_formats': 'canvas/moment_formats',
      'bower': 'canvas/bower',
      'compiled': 'canvas/compiled',
      'jquery': 'canvas/vendor/jquery-1.7.2',
      'jqueryui': 'canvas/vendor/jqueryui',
      'vendor': 'canvas/vendor',
      'timezone': 'canvas/timezone_core',
      'canvas/timezone_core/index': 'symlink_to_node_modules/timezone/index'
      'jquery.instructure_date_and_time': 'canvas/jquery.instructure_date_and_time',
      'i18nObj': 'i18n',
      'moment': 'canvas/symlink_to_node_modules/moment/moment'
    },

    'canvas/jquery.instructure_date_and_time': {
      'compiled/behaviors/authenticity_token': 'canvas/compiled/behaviors/authenticity_token',
      'jqueryui': 'canvas/vendor/jqueryui',
      'timezone': 'canvas/timezone_core',
      'str/htmlEscape': 'canvas/str/htmlEscape',
      'jquery.keycodes': 'canvas/jquery.keycodes',
      'vendor/date': 'canvas/vendor/date',
      'jsx/shared/render-datepicker-time': 'canvas/jsx/shared/render-datepicker-time'
    },

    'canvas/jsx/shared/render-datepicker-time': {
      'i18n': 'i18n',
    },

    'canvas/str/htmlEscape': {
      'INST': 'canvas/INST',
    },

    'canvas/jquery': {
      'jquery.instructure_jquery_patches': 'canvas/jquery.instructure_jquery_patches'
    },

    'canvas/jquery.instructure_jquery_patches': {
      'vendor': 'canvas/vendor',
    },

    'canvas/jquery.keycodes': {
      'jquery.instructure_date_and_time': 'canvas/jquery.instructure_date_and_time'
    },

    'canvas/timezone_core': {
      'canvas/timezone_core/index': 'symlink_to_node_modules/timezone/index'
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
    }
  }
});

define([ 'canvas/jquery.instructure_date_and_time' ], function() {
});
