/** @jsx React.DOM */

define([
  'underscore',
  'redux',
  '../actions/ModerationActions',
  './../constants'
], function (_, Redux, ModerationActions, Constants) {

  var { combineReducers } = Redux;

  var studentHandlers = {};

  studentHandlers[ModerationActions.GOT_STUDENTS] = (state, action) => {
    return state.concat(action.payload.students);
  };

  studentHandlers[ModerationActions.SORT_MARK_COLUMN] = (state, action) => {
    if(action.payload.markColumn == undefined){
      return (state || []);
    }

    // We are just toggling the sort order from what it previously was. If there was no previous
    // then we default to sorting by highest/ascending
    var studentList = _.sortBy(state, (student) => {
      var provisionalGrade = student.provisional_grades[action.payload.markColumn]
      if (provisionalGrade) {
        return provisionalGrade.score;
      }

      return 0; // no score is sorted down
    })

    // if no sort direction has been set, default to descending order
    var sortToHighest = (
      action.payload.currentSortDirection === Constants.sortDirections.LOWEST) ||
      action.payload.currentSortDirection === undefined ||
      action.payload.previousMarkColumn != action.payload.markColumn;

    if (sortToHighest){
      return studentList.reverse();
    }

    return studentList;
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

  function markColumnSort (state, action) {
    state = state || {}
    if (action.type === ModerationActions.SORT_MARK_COLUMN) {
      var newState = _.extend({}, state);

      var togglingColumn = action.payload.markColumn === state.markColumn;
      var sortDirectionIsHighest = action.payload.currentSortDirection === Constants.sortDirections.HIGHEST;
      if(togglingColumn && sortDirectionIsHighest){
        newState.currentSortDirection = Constants.sortDirections.LOWEST;
      }else{
        newState.currentSortDirection = Constants.sortDirections.HIGHEST;
      }
      newState.markColumn = action.payload.markColumn;
      return newState;
    }
    return state;
  }

  return combineReducers({
   students,
   urls,
   flashMessage,
   assignment,
   markColumnSort
  });

});
