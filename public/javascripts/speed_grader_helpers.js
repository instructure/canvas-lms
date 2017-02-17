/**
 * Copyright (C) 2015 Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'jquery',
  'underscore',
  'i18n!gradebook',
  'jquery.instructure_date_and_time'
], function($, _, I18n) {
  var speedgraderHelpers = {
    urlContainer: function(submission, defaultEl, originalityReportEl) {
      if (submission.has_originality_report) {
        return originalityReportEl
      }
      return defaultEl
    },

    buildIframe: function(src, options){
      options = options || {};
      var parts = ['<iframe'];
      parts.push(' id="speedgrader_iframe"');
      parts.push(' src="' + src + '"');
      Object.keys(options).forEach(function(key){
        var value = options[key];
        if (key === 'className') {
          key = 'class';
        }
        parts.push(' ' + key + '="' + value + '"');
      });
      parts.push('></iframe>');
      return parts.join('');
    },

    determineGradeToSubmit: function(use_existing_score, student, grade){
      if (use_existing_score) {
        return student.submission["score"].toString();
      }
      return grade.val();
    },

    iframePreviewVersion: function(submission){
      //check if the submission object is valid
      if (submission == null) {
        return '';
      }
      //check if the index is valid (multiple submissions)
      var currentSelectedIndex = submission.currentSelectedIndex;
      if (currentSelectedIndex == null || isNaN(currentSelectedIndex)) {
        return '';
      }
      var select = '&version=';
      //check if the version is valid, or matches the index
      var version = submission.submission_history[currentSelectedIndex].submission.version;
      if (version == null || isNaN(version)) {
        return select + currentSelectedIndex;
      }
      return select + version;
    },

    setRightBarDisabled: function(isDisabled){
      var elements = ['#grading-box-extended', '#speedgrader_comment_textarea', '#add_attachment',
                      '#media_comment_button', '#comment_submit_button',
                      '#speech_recognition_button'];

      _.each(elements, function(element){
        if(isDisabled) {
          $(element).addClass('ui-state-disabled');
          $(element).attr('aria-disabled', true);
          $(element).attr('readonly', true);
        } else {
          $(element).removeClass('ui-state-disabled');
          $(element).removeAttr('aria-disabled');
          $(element).removeAttr('readonly');
        }
      });
    },


    classNameBasedOnStudent: function(student){
      var raw = student.submission_state;
      var formatted;
      switch(raw) {
      case "graded":
      case "not_gradeable":
        formatted = I18n.t('graded', "graded");
        break;
      case "not_graded":
        formatted = I18n.t('not_graded', "not graded");
        break;
      case "not_submitted":
        formatted = I18n.t('not_submitted', 'not submitted');
        break;
      case "resubmitted":
        formatted = I18n.t('graded_then_resubmitted', "graded, then resubmitted (%{when})",
                           {'when': $.datetimeString(student.submission.submitted_at)});
        break;
      }
      return {raw: raw, formatted: formatted};
    },

    submissionState: function(student, grading_role){
      var submission = student.submission;
      if (submission && submission.workflow_state != 'unsubmitted' && (submission.submitted_at || !(typeof submission.grade == 'undefined'))) {
        if ((grading_role == 'provisional_grader' || grading_role == 'moderator')
            && !student.needs_provisional_grade && submission.provisional_grade_id === null) {
          // if we are a provisional grader and it doesn't need a grade (and we haven't given one already) then we shouldn't be able to grade it
          return "not_gradeable";
        } else if (!(submission.final_provisional_grade && submission.final_provisional_grade.grade) && !submission.excused &&
                   (typeof submission.grade == 'undefined' || submission.grade === null || submission.workflow_state == 'pending_review')) {
          return "not_graded";
        } else if (submission.grade_matches_current_submission) {
          return "graded";
        } else {
          return "resubmitted";
        }
      } else {
        return "not_submitted";
      }
    }

  }

  return speedgraderHelpers;
});
