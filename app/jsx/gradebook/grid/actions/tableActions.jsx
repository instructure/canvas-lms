define([
  'bower/reflux/dist/reflux',
], function (Reflux) {
  var TableActions = Reflux.createActions([
    'enterLoadingState'
  ]);

  return TableActions;
});
