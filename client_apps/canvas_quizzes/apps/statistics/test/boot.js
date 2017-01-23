define((require) => {
  const Dispatcher = require('core/dispatcher');
  const ReactSuite = require('jasmine_react');
  const _ = require('lodash');
  const config = require('config');
  const AppDelegate = require('core/delegate');

  const stockConfig = _.clone(config);
  let actionIndex = 0;

  document.body.id = 'canvas-quiz-statistics';

  afterEach(() => {
    // Reset the app if it got mounted during a spec:
    if (AppDelegate.isMounted()) {
      AppDelegate.unmount();
    }

    // Restore any config parameters changed during tests:
    AppDelegate.configure(stockConfig);
  });

  // configure jasmine-react to work with our Dispatcher for testing sendAction
  // calls from components:
  ReactSuite.config.getSendActionSpy = function (subject) {
    const dispatch = Dispatcher.dispatch.bind(Dispatcher);

    return {
      original: dispatch,
      spy: spyOn(Dispatcher, 'dispatch')
    };
  };

  ReactSuite.config.decorateSendActionRc = function (promise) {
    return {
      index: ++actionIndex,
      promise
    };
  };

  // return function(startTests) {
  //   require([ 'core/delegate' ], startTests);
  // };
});
