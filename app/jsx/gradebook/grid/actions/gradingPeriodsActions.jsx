define([
  'bower/reflux/dist/reflux',
  'jquery'
], function (Reflux, $) {
  var GradingPeriodsActions = Reflux.createActions([
    'select'
  ]);

  return GradingPeriodsActions;
});
