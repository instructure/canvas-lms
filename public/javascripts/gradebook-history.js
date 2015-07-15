/**
 * Copyright (C) 2011 Instructure, Inc.
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
  'i18n!gradebook',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* datetimeString */
], function(I18n, $) {

  var GradebookHistory = {
    init: function(){
      $('.assignment_header').click(function(event) {
        event.preventDefault();
        $(this).find('.ui-icon').toggleClass('ui-icon-circle-arrow-n').end()
          .next('.assignment_details').slideToggle('fast');
      });
      $(".revert-grade-link").bind("mouseenter mouseleave", function(){
        $(this).toggleClass("ui-state-hover");
      })
      .click(GradebookHistory.handleGradeSubmit);
    },

    handleGradeSubmit: function(event){
      event.preventDefault();
      // 'this' should be the <a href> that they clicked on

      var assignment_id = $(this).parents('tr').data('assignment-id'),
          user_id = $(this).parents('tr').data('user-id'),
          grade = $(this).find('.grade').text().replace("--", ""),
          url = $(".update_submission_grade_url").attr('href'),
          method = $(".update_submission_grade_url").attr('title');

      $(".assignment_" + assignment_id + "_user_" + user_id + "_current_grade").addClass('loading');

      var formData = {
        'submission[assignment_id]': assignment_id,
        'submission[user_id]':       user_id
      };

      if(grade == "EX") {
        formData['submission[excused]'] = 1;
      } else {
        formData['submission[grade]'] = grade;
      }

      $.ajaxJSON(url, method, formData, function(submissions) {
        $.each(submissions, function(){
          var submission = this.submission;
          var el = $(".assignment_" + submission.assignment_id + "_user_" + submission.user_id + "_current_grade")
            el.removeClass('loading');
            el.attr('title', I18n.t('graded_by_me', "%{graded_time} by me", { 'graded_time': $.datetimeString(submission.graded_at) }));
            if(submission.excused) {
              el.text("EX");
            } else {
              el.text(submission.grade || "--");
            }
        });
      });
    }
  };

$(document).ready(GradebookHistory.init);
});
