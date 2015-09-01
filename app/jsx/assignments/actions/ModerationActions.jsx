/** @jsx React.DOM */

define([
  'jquery',
  'i18n!moderated_grading',
  'axios',
  'compiled/jquery.rails_flash_notifications'
], function ($, I18n, axios) {
  class ModerationActions {
    constructor (store, opts) {
      this.store = store;
      if (opts && opts.publish_grades_url) {
        this.publish_grades_url = opts.publish_grades_url;
      }
    }

    updateSubmission (submission) {
      // Update the submission and then update the store
    }

    loadInitialSubmissions (submissions_url) {
      axios.get(submissions_url)
           .then(function (response) {
             this.store.addSubmissions(response.data);
           }.bind(this))
           .catch(function (response) {
             console.log('finished');
           });
    }

    publishGrades () {
      var axiosPostOptions = {
        xsrfCookieName: '_csrf_token',
        xsrfHeaderName: 'X-CSRF-Token'
      };
      axios.post(this.publish_grades_url, {}, axiosPostOptions)
           .then((response) => {
             $.flashMessage(I18n.t('Success! Grades were published to the grade book.'));
           })
           .catch((response) => {
             if ((response.status === 400) && (response.data.message)){
               $.flashError(response.data.message);
             } else {
               $.flashError(I18n.t('Error! A problem happened publishing grades.'));
             }
           });
    }
  }

  return ModerationActions;
});
