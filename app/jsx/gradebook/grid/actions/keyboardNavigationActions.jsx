define([
  'bower/reflux/dist/reflux',
  'jquery'
], function (Reflux, $) {
  var KeyboardNavigationActions = Reflux.createActions([
    'setActiveCell',
    'constructKeyboardNavManager',
    'handleKeyboardEvent'
  ]);

  return KeyboardNavigationActions;
});
