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

import axios from 'axios'
import parseLinkHeader from '../../shared/helpers/parseLinkHeader'
import I18n from 'i18n!moderated_grading'
import _ from 'underscore'

  var ModerationActions = {

    // Define 'constants' for types
    SELECT_STUDENT: 'SELECT_STUDENT',
    UNSELECT_STUDENT: 'UNSELECT_STUDENT',
    SELECT_ALL_STUDENTS: 'SELECT_ALL_STUDENTS',
    UNSELECT_ALL_STUDENTS: 'UNSELECT_ALL_STUDENTS',
    SELECT_MARK: 'SELECT_MARK',
    ACTION_DISPATCHED: 'ACTION_DISPATCHED',
    ACTION_RETURNED: 'ACTION_RETURNED',
    UPDATED_MODERATION_SET: 'UPDATED_MODERATION_SET',
    UPDATE_MODERATION_SET_FAILED: 'UPDATE_MODERATION_SET_FAILED',
    PUBLISHED_GRADES: 'PUBLISHED_GRADES',
    PUBLISHED_GRADES_FAILED: 'PUBLISHED_GRADES_FAILED',
    GOT_STUDENTS: 'GOT_STUDENTS',
    SORT_MARK1_COLUMN: 'SORT_MARK1_COLUMN',
    SORT_MARK2_COLUMN: 'SORT_MARK2_COLUMN',
    SORT_MARK3_COLUMN: 'SORT_MARK3_COLUMN',
    SELECTING_PROVISIONAL_GRADES_FAILED: 'SELECTING_PROVISIONAL_GRADES_FAILED',

    sortMark1Column () {
      return {
        type: this.SORT_MARK1_COLUMN
      };
    },

    sortMark2Column () {
      return {
        type: this.SORT_MARK2_COLUMN
      };
    },

    sortMark3Column () {
      return {
        type: this.SORT_MARK3_COLUMN
      };
    },

    selectStudent (studentId) {
      return {
        type: this.SELECT_STUDENT,
        payload: { studentId }
      };
    },

    unselectStudent (studentId) {
      return {
        type: this.UNSELECT_STUDENT,
        payload: { studentId }
      };
    },

    selectAllStudents (students) {
      return {
        type: this.SELECT_ALL_STUDENTS,
        payload: { students }
      };
    },

    unselectAllStudents () {
      return {
        type: this.UNSELECT_ALL_STUDENTS
      };
    },

    moderationStarted () {
      return {
        type: this.ACTION_DISPATCHED,
        payload: {
          name: 'review'
        }
      };
    },

    moderationFinished () {
      return {
        type: this.ACTION_RETURNED,
        payload: {
          name: 'review'
        }
      };
    },

    moderationSetUpdated (students) {
      return {
        type: this.UPDATED_MODERATION_SET,
        payload: {
          students,
          time: Date.now(),
          message: I18n.t('Reviewers successfully added')
        }
      };
    },

    moderationSetUpdateFailed () {
      return {
        type: this.UPDATE_MODERATION_SET_FAILED,
        payload: {
          time: Date.now(),
          message: I18n.t('A problem occurred adding reviewers.')
        },
        error: true
      };
    },

    gotStudents (students) {
      return {
        type: this.GOT_STUDENTS,
        payload: { students }
      };
    },

    publishStarted () {
      return {
        type: this.ACTION_DISPATCHED,
        payload: {
          name: 'publish'
        }
      };
    },

    publishFinished () {
      return {
        type: this.ACTION_RETURNED,
        payload: {
          name: 'publish'
        }
      };
    },

    publishedGrades (message) {
      return {
        type: this.PUBLISHED_GRADES,
        payload: {
          message,
          time: Date.now()
        }
      };
    },

    publishGradesFailed (message) {
      return {
        type: this.PUBLISHED_GRADES_FAILED,
        payload: {
          message,
          time: Date.now()
        },
        error: true
      };
    },

    selectingProvisionalGradesFailed (message) {
      var error = new Error(message);
      error.time = Date.now();
      return {
        type: this.SELECTING_PROVISIONAL_GRADES_FAILED,
        payload: error,
        error: true
      };
    },

    selectedProvisionalGrade (studentId, selectedProvisionalId) {
      return {
        type: this.SELECT_MARK,
        payload: {
          studentId,
          selectedProvisionalId
        }
      };
    },

    selectProvisionalGrade (selectedProvisionalId, ajaxLib) {
      return (dispatch, getState) => {
        var endpoint = getState().urls.provisional_grades_base_url + "/" + selectedProvisionalId + "/select"
        ajaxLib = ajaxLib || axios;
        ajaxLib.put(endpoint)
               .then((response) => {
                 dispatch(this.selectedProvisionalGrade(response.data.student_id, response.data.selected_provisional_grade_id));
               })
               .catch((response) => {
                 dispatch(this.selectingProvisionalGradesFailed(I18n.t('An error occurred selecting provisional grades')));
               });
      };

    },

    publishGrades (ajaxLib) {
      return (dispatch, getState) => {
        var endpoint = getState().urls.publish_grades_url;
        ajaxLib = ajaxLib || axios;
        ajaxLib.post(endpoint)
               .then((response) => {
                 dispatch(this.publishedGrades(I18n.t('Success! Grades were published to the grade book.')));
               })
               .catch((response) => {
                 const errorMessages = {
                   400: I18n.t('Assignment grades have already been published.'),
                   422: I18n.t('All submissions must have a selected grade.')
                 };
                 let message =
                   errorMessages[response.status] ||
                   I18n.t('An error occurred publishing grades.');
                 dispatch(this.publishGradesFailed(message));
               });
      };
    },

    addStudentToModerationSet (ajaxLib) {
      return (dispatch, getState) => {
        var endpoint = getState().urls.add_moderated_students;
        ajaxLib = ajaxLib || axios;
        ajaxLib.post(endpoint, {
          student_ids: _.reduce(getState().studentList.students, (ids, student) => {
            if(student.on_moderation_stage){
              ids.push(student.id);
            }
            return ids;
          }, [])
               })
               .then((response) => {
                 dispatch(this.moderationSetUpdated(response.data));
               })
               .catch((response) => {
                 dispatch(this.moderationSetUpdateFailed());
               });
      };
    },

    apiGetStudents (ajaxLib, endpoint) {
      return (dispatch, getState) => {
        endpoint = endpoint || getState().urls.list_gradeable_students;
        ajaxLib = ajaxLib || axios;
        ajaxLib.get(endpoint)
               .then((response) => {
                 var linkHeaders = parseLinkHeader(response);
                 if (linkHeaders.next) {
                   dispatch(this.apiGetStudents(ajaxLib, linkHeaders.next));
                 }
                 dispatch(this.gotStudents(response.data));
               })
               .catch((response) => {
                 throw new Error(response);
               });
      };
    }
  };

export default ModerationActions
