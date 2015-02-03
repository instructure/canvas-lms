requirejs.config({
  map: {
    'canvas/react': {
      'bower/react/react-with-addons': 'canvas/bower/react/react-with-addons'
    }
  }
});

define([ 'canvas/react' ], function(React) {
  return React;
});
