define(function(require) {
  var Dispatcher = require('canvas_quizzes/core/dispatcher');
  var ReactSuite = require('jasmine_react');
  var _ = require('lodash');
  var config = require('config');
  var AppDelegate = require('core/delegate');

  var stockConfig = _.clone(config);
  var actionIndex = 0;

  document.body.id = 'canvas-quiz-statistics';

  afterEach(function() {
    // Reset the app if it got mounted during a spec:
    if (AppDelegate.isMounted()) {
      AppDelegate.unmount();
    }

    // Restore any config parameters changed during tests:
    AppDelegate.configure(stockConfig);
  });

  // configure jasmine-react to work with our Dispatcher for testing sendAction
  // calls from components:
  ReactSuite.config.getSendActionSpy = function(subject) {
    var dispatch = Dispatcher.dispatch.bind(Dispatcher);

    return {
      original: dispatch,
      spy: spyOn(Dispatcher, 'dispatch')
    };
  };

  ReactSuite.config.decorateSendActionRc = function(promise) {
    return {
      index: ++actionIndex,
      promise: promise
    };
  };

  // return function(startTests) {
  //   require([ 'core/delegate' ], startTests);
  // };
});