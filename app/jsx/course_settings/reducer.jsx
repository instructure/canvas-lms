define([
  'redux',
  './actions',
  './store/initialState',
  'underscore'
], (Redux, Actions, initialState, _) => {

  const { combineReducers } = Redux;

  const courseImageHandlers = {

  };

  const courseImage = (state = initialState, action) => {
    if (courseImageHandlers[action.type]) {
      const newState = _.extend({}, state);
      return courseImageHandlers[action.type](newState, action);
    } else {
      return state;
    }
  };

  return combineReducers({
    courseImage
  });

});