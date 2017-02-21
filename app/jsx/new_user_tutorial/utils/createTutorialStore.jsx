define(['jsx/shared/helpers/createStore'], (createStore) => {
  const defaultState = Object.freeze({
    isCollapsed: false
  });

  const createTutorialStore = (initialState = defaultState) => {
    const store = createStore(Object.assign({}, initialState));
    return store;
  }

  return createTutorialStore;
});
