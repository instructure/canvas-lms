requirejs.config({
  map: {
    'canvas/symlink_to_node_modules/backbone/backbone': {
      'jquery': '../../../vendor/packages/jquery',
    },
  }
});

define([ 'canvas/symlink_to_node_modules/backbone/backbone' ], function(Backbone) {
  return Backbone;
});
