requirejs.config({
  map: {
    'canvas/compiled/behaviors/tooltip': {
      'jquery': '../../vendor/packages/jquery',
      'jqueryui/tooltip': '../../vendor/packages/jqueryui/tooltip'
    }
  }
});

define([ 'canvas/compiled/behaviors/tooltip' ], function() {
});
