import createStore from 'jsx/shared/helpers/createStore';

  const defaultState = Object.freeze({
    isCollapsed: false
  });

  const createTutorialStore = (initialState = defaultState) => {
    const store = createStore(Object.assign({}, initialState));
    return store;
  }

export default createTutorialStore;
