requirejs.config({
  map: {
    'canvas/vendor/backbone': {
      'jquery': '../../vendor/packages/jquery'
    }
  }
});

define([ 'canvas/vendor/backbone' ], function(Backbone) {
  return Backbone;
});