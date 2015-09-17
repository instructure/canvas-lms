/** @jsx React.DOM */

define([
  'underscore',
  'redux',
  '../actions/ModerationActions'
], function (_, Redux, ModerationActions) {

  var { combineReducers } = Redux;

  var studentHandlers = {};

  studentHandlers[ModerationActions.GOT_STUDENTS] = (state, action) => {
    return state.concat(action.payload.students);
  };

  var flashHandlers = {};

  flashHandlers[ModerationActions.PUBLISHED_GRADES] = (state, action) => {
    // Don't mutate the existing state.
    var newState = _.extend({}, state);
    newState.time = action.payload.time;
    newState.message = action.payload.message;
    newState.error = false;
    return newState;
  };

  flashHandlers[ModerationActions.PUBLISHED_GRADES_FAILED] = (state, action) => {
    // Don't mutate the existing state.
    var newState = _.extend({}, state);
    newState.time = action.payload.time;
    newState.message = action.payload.message;
    newState.error = true;
    return newState;
  };

  function urls (state, action) {
    return state || {};
  }

  function students (state, action) {
    state = state || [];
    var handler = studentHandlers[action.type];
    if (handler) return handler(state, action);
    return state;
  }

  function addUserToModeration (state, action) {
    // Don't mutate the existing state.
    var newState = _.extend({}, state);
    var { type, payload } = action;
    if (type === ModerationActions.SELECT_STUDENT) {
      newState.moderationStage.push(payload.studentId);
      return newState;
    }
    return {moderationStage: []};
  }

  function flashMessage (state, action) {
    state = state || {};
    var handler = flashHandlers[action.type];
    if (handler) return handler(state, action);
    return state;
  }

  function assignment (state, action) {
    state = state || {};
    if (action.type === ModerationActions.PUBLISHED_GRADES) {
      // Don't mutate the existing state.
      var newState = _.extend({}, state);
      newState.published = true;
      return newState;
    }
    return state;
  }

  return combineReducers({
   students,
   urls,
   flashMessage,
   assignment
  });

});
