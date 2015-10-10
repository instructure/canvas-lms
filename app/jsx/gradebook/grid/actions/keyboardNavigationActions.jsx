define([
  'bower/reflux/dist/reflux',
  'jquery'
], function (Reflux, $) {
  var KeyboardNavigationActions = Reflux.createActions([
    'next',
    'previous',
    'up',
    'down',
    'setActiveCell'
  ]);

  return KeyboardNavigationActions;
});
