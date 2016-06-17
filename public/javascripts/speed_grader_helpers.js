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
  'underscore'
], function($, _) {
  var speedgraderHelpers = {

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
    }
  }

  return speedgraderHelpers;
});
