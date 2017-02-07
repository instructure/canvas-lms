createFakeStore = function(initialState) {
  var store = {
    dispatchedActions: [],
    subscribe: function() { return function() { }; },
    getState: function() { return initialState; },
    dispatch: function(action) {
      if (typeof action === 'function') {
        return action(store.dispatch);
      }
      store.dispatchedActions.push(action);
    },
  };
  return store;
}
