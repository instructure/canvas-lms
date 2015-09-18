/** @jsx React.DOM */

define([
  'underscore',
  'redux',
  '../actions/ModerationActions',
  './../constants'
], function (_, Redux, ModerationActions, Constants) {

  var { combineReducers } = Redux;

  /**
   * Student Handlers
   */
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
  }

  studentHandlers[ModerationActions.UPDATED_MODERATION_SET] = (state, action) => {
    var idsAdded = action.payload.students.map((student) => student.id);
    return state.map((student) => {
      if (_.contains(idsAdded, student.id)) {
        student.in_moderation_set = true;
        return student;
      } else {
        return student;
      }
    });
  };

  /**
   * Flash Message Handlers
   */
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

  flashHandlers[ModerationActions.UPDATED_MODERATION_SET] = (state, action) => {
    // Don't mutate the existing state.
    var newState = _.extend({}, state);
    newState.time = action.payload.time;
    newState.message = action.payload.message;
    newState.error = false;
    return newState;
  };

  flashHandlers[ModerationActions.UPDATE_MODERATION_SET_FAILED] = (state, action) => {
    // Don't mutate the existing state.
    var newState = _.extend({}, state);
    newState.time = action.payload.time;
    newState.message = action.payload.message;
    newState.error = true;
    return newState;
  };

  /**
   * Moderation Stage Handlers
   */
  var moderationStageHandlers = {};

  moderationStageHandlers[ModerationActions.SELECT_STUDENT] = (state, action) => {
    return _.union(state, [action.payload.studentId]);
  };

  moderationStageHandlers[ModerationActions.UNSELECT_STUDENT] = (state, action) => {
    return _.without(state, action.payload.studentId);
  };

  moderationStageHandlers[ModerationActions.UPDATED_MODERATION_SET] = (state, action) => {
    var idsAdded = action.payload.students.map((student) => student.id);
    // Removing only the ids that were successfully added.
    // This possibly could be reworked to remove everyone from the stage.
    return _.difference(state, idsAdded);
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

  function moderationStage (state, action) {
    state = state || [];
    var handler = moderationStageHandlers[action.type]
    if (handler) return handler(state, action);
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
   moderationStage,
   markColumnSort
  });

});
