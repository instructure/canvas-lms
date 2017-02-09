define(() => {
  return function createFakeStore (initialState) {
    const store =  {
      dispatchedActions: [],
      subscribe () { return function () { } },
      getState () { return initialState },
      dispatch (action) {
        if (typeof action === 'function') {
          return action(store.dispatch)
        }
        store.dispatchedActions.push(action)
      },
    }
    return store
  }
})
