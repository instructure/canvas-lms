requirejs.config({
  map: {
    'canvas/vendor/jquery.cookie': {
      'vendor/jquery-1.7.2': 'canvas/vendor/jquery-1.7.2'
    }
  }
});

define([ 'canvas/vendor/jquery-1.7.2' ], function($) {
  return $;
});