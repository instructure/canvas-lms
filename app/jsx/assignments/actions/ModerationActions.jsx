/** @jsx React.DOM */

define([
  'axios',
  'i18n!moderated_grading'
], function (axios, I18n) {

  var ModerationActions = {

    // Define 'constants' for types
    SELECT_STUDENT: 'SELECT_STUDENT',
    UNSELECT_STUDENT: 'UNSELECT_STUDENT',
    SELECT_ALL_STUDENTS: 'SELECT_ALL_STUDENTS',
    UNSELECT_ALL_STUDENTS: 'UNSELECT_ALL_STUDENTS',
    SELECT_MARK: 'SELECT_MARK',
    UPDATE_MODERATION_SET: 'UPDATE_MODERATION_SET',
    PUBLISHED_GRADES: 'PUBLISHED_GRADES',
    PUBLISHED_GRADES_FAILED: 'PUBLISHED_GRADES_FAILED',
    GOT_STUDENTS: 'GOT_STUDENTS',

    selectStudent (studentId) {
      return {
        type: this.SELECT_STUDENT,
        payload: { studentId }
      };
    },

    gotStudents (students) {
      return {
        type: this.GOT_STUDENTS,
        payload: { students }
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

    publishGrades (ajaxLib) {
      return (dispatch, getState) => {
        var endpoint = getState().urls.publish_grades_url;
        ajaxLib = ajaxLib || axios;
        ajaxLib.post(endpoint)
               .then((response) => {
                 dispatch(this.publishedGrades(I18n.t('Success! Grades were published to the grade book.')));
               })
               .catch((response) => {
                 if (response.status === 400) {
                   dispatch(this.publishGradesFailed(I18n.t('Assignment grades have already been published.')));
                 } else {
                   dispatch(this.publishGradesFailed(I18n.t('An error occurred publishing grades.')));
                 }
               });
      };
    },

    apiGetStudents (ajaxLib) {
      return (dispatch, getState) => {
        var endpoint = getState().urls.list_gradeable_students;
        ajaxLib = ajaxLib || axios;
        ajaxLib.get(endpoint)
               .then((response) => {
                 dispatch(this.gotStudents(response.data));
               })
               .catch((response) => {
                 throw new Error(response);
               });
      };
    }
  };

  return ModerationActions;
});
