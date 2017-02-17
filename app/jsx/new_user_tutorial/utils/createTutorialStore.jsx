define(['jsx/shared/helpers/createStore'], (createStore) => {

  const defaultState = Object.freeze({
    isCollapsed: true
  });

  const createTutorialStore = (initialState = defaultState) => {
    const store = createStore(Object.assign({}, initialState));
    return store;
  }

  return createTutorialStore;
});
