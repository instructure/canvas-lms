requirejs.config({
  map: {
    '*': {
      'jquery': 'canvas/vendor/jquery-1.7.2',
      'jqueryui': 'canvas/vendor/jqueryui',
    },
  }
});

// Don't use this directly, use canvas_packages/tooltip instead.
define([ 'jquery', 'canvas/vendor/jqueryui/tooltip' ], function() {
});