/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import _ from 'underscore'
import { combineReducers } from 'redux'
import ModerationActions from '../actions/ModerationActions'
import Constants from './../constants'

  // CONSTANTS //
  var ASCENDING = Constants.sortDirections.ASCENDING;
  var DESCENDING = Constants.sortDirections.DESCENDING;
  var MARK1 = Constants.markColumnNames.MARK_ONE;
  var MARK2 = Constants.markColumnNames.MARK_TWO;
  var MARK3 = Constants.markColumnNames.MARK_THREE;
  var MARK1_PROVISIONAL_GRADE_INDEX = 0;
  var MARK2_PROVISIONAL_GRADE_INDEX = 1;
  var MARK3_PROVISIONAL_GRADE_INDEX = 2;

  // PRIVATE FUNCTIONS //
  function __sortMarkColumn(state, action, column, provisionalGradeIndex) {
    var newState = _.extend({}, state);

    var previouslySortedAsDescending = state.sort.column === column && state.sort.direction === DESCENDING
    if(previouslySortedAsDescending){
      newState.students = __sortStudentsByMark(newState.students, ASCENDING, provisionalGradeIndex);
      newState.sort.direction = ASCENDING;
    }else{
      newState.students = __sortStudentsByMark(newState.students, DESCENDING, provisionalGradeIndex);
      newState.sort.direction = DESCENDING
    }

    newState.sort.column = column;
    return newState;
  }

  function __sortStudentsByMark(students, direction, provisionalGradeIndex) {
    var studentList = _.sortBy(students, (student) => {
      var provisionalGrade = student.provisional_grades[provisionalGradeIndex]
      if (provisionalGrade) {
        return provisionalGrade.score;
      }

      return 0; // no score is sorted down
    });

    if(direction === DESCENDING){
      studentList.reverse();
    }

    return studentList;
  }

  /**
   * Student Handlers
   */
  var studentHandlers = {};
  studentHandlers[ModerationActions.GOT_STUDENTS] = (state, action) => {
    var newState = _.extend({}, state);
    const students = newState.students.concat(action.payload.students);
    newState.students = _.uniq(students, student => student.id);
    return newState;
  };

  studentHandlers[ModerationActions.SORT_MARK1_COLUMN] = (state, action) => {
    return (__sortMarkColumn(state, action, MARK1, MARK1_PROVISIONAL_GRADE_INDEX));
  };

  studentHandlers[ModerationActions.SORT_MARK2_COLUMN] = (state, action) => {
    return (__sortMarkColumn(state, action, MARK2, MARK2_PROVISIONAL_GRADE_INDEX));
  };

  studentHandlers[ModerationActions.SORT_MARK3_COLUMN] = (state, action) => {
    return (__sortMarkColumn(state, action, MARK3, MARK3_PROVISIONAL_GRADE_INDEX));
  };

  studentHandlers[ModerationActions.SELECT_ALL_STUDENTS] = (state, action) => {
    var newState = _.extend({}, state);

    newState.students = newState.students.map((student) => {
      student.on_moderation_stage = true;
      return student;
    });

    newState.selectedCount = newState.students.length;

    return newState;
  };

  studentHandlers[ModerationActions.UNSELECT_ALL_STUDENTS] = (state, action) => {
    var newState = _.extend({}, state);

    newState.students = newState.students.map((student) => {
      student.on_moderation_stage = false;
      return student;
    });

    newState.selectedCount = 0;

    return newState;
  };

  studentHandlers[ModerationActions.SELECT_STUDENT] = (state, action) => {
    var newState = _.extend({}, state);
    // For some odd stupid reason, our underscore/lodash doesn't have _.findIndex
    var studentObj = _.find(newState.students, (student) => {
      return student.id === action.payload.studentId;
    });
    var studentIndex = newState.students.indexOf(studentObj);
    if (studentIndex > -1) {
      newState.students[studentIndex].on_moderation_stage = true;
      newState.selectedCount += 1;
    }
    return newState;
  };

  studentHandlers[ModerationActions.UNSELECT_STUDENT] = (state, action) => {
    var newState = _.extend({}, state);
    // For some odd stupid reason, our underscore/lodash doesn't have _.findIndex
    var studentObj = _.find(newState.students, (student) => {
      return student.id === action.payload.studentId;
    });
    var studentIndex = newState.students.indexOf(studentObj);
    if (studentIndex > -1) {
      newState.students[studentIndex].on_moderation_stage = false;
      newState.selectedCount += -1;
    }
    return newState;
  };

  studentHandlers[ModerationActions.UPDATED_MODERATION_SET] = (state, action) => {
    var newState = _.extend({}, state);
    var idsAdded = action.payload.students.map((student) => student.id);
    var studentsUpdated = 0;
    newState.students = newState.students.map((student) => {
      if (_.contains(idsAdded, student.id)) {
        student.in_moderation_set = true;
        student.on_moderation_stage = false;
        studentsUpdated += 1;
        return student;
      } else {
        return student;
      }
    });

    newState.selectedCount -= studentsUpdated;

    return newState;
  };

  studentHandlers[ModerationActions.SELECT_MARK] = (state, action) => {
    var newState = _.extend({}, state);
    // For some odd stupid reason, our underscore/lodash doesn't have _.findIndex
    var studentObj = _.find(newState.students, (student) => {
      return student.id === action.payload.studentId;
    });
    var studentIndex = newState.students.indexOf(studentObj);
    if (studentIndex > -1) {
      newState.students[studentIndex].selected_provisional_grade_id = action.payload.selectedProvisionalId
    }
    return newState;
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
    newState.error = action.payload.error || false;
    return newState;
  };

  flashHandlers[ModerationActions.PUBLISHED_GRADES_FAILED] = (state, action) => {
    // Don't mutate the existing state.
    var newState = _.extend({}, state);
    newState.time = action.payload.time;
    newState.message = action.payload.message;
    newState.error = action.payload.error || true;
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

  flashHandlers[ModerationActions.SELECTING_PROVISIONAL_GRADES_FAILED] = (state, action) => {
    // Don't mutate the existing state.
    var newState = _.extend({}, state);
    newState.time = action.payload.time;
    newState.message = action.payload.message;
    newState.error = action.error;
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

  moderationStageHandlers[ModerationActions.SELECT_ALL_STUDENTS] = (state, action) => {
    // Extract out just the studentIds
    var ids = action.payload.students.map((student) => student.id);
    // Make sure we don't have dulplicates hence the union
    return _.union(state, ids);
  };

  moderationStageHandlers[ModerationActions.UNSELECT_ALL_STUDENTS] = (state, action) => {
    return [];
  };

  moderationStageHandlers[ModerationActions.UPDATED_MODERATION_SET] = (state, action) => {
    var idsAdded = action.payload.students.map((student) => student.id);
    // Removing only the ids that were successfully added.
    // This possibly could be reworked to remove everyone from the stage.
    return _.difference(state, idsAdded);
  };

  /**
   * Inflight Action Handlers
   */
  function __landAction(state, action_name) {
    var newState = _.extend({}, state);
    newState[action_name] = false;

    return newState;
  }

  var inflightActionHandlers = {};

  inflightActionHandlers[ModerationActions.ACTION_DISPATCHED] = (state, action) => {
    var newState = _.extend({}, state);
    newState[action.payload.name] = true;
    return newState;
  };

  inflightActionHandlers[ModerationActions.PUBLISHED_GRADES] = (state, action) => {
    return __landAction(state, 'publish');
  };

  inflightActionHandlers[ModerationActions.PUBLISHED_GRADES_FAILED] = (state, action) => {
    return __landAction(state, 'publish');
  };

  inflightActionHandlers[ModerationActions.UPDATED_MODERATION_SET] = (state, action) => {
    return __landAction(state, 'review');
  };

  inflightActionHandlers[ModerationActions.UPDATE_MODERATION_SET_FAILED] = (state, action) => {
    return __landAction(state, 'review');
  };

  function inflightAction (state, action) {
    state = state || {};

    var handler = inflightActionHandlers[action.type];

    if (handler) return handler(state, action);

    return state;
  }


  function urls (state, action) {
    return state || {};
  }

  function studentList (state, action) {
    state = state || {
      selectedCount: 0,
      students: [],
      sort: {
        direction: '',
        column: ''
      }
    };

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

export default combineReducers({
    studentList,
    urls,
    flashMessage,
    assignment,
    inflightAction
  });
