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
  'jsx/gradebook/shared/helpers/GradeFormatHelper',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* datetimeString */
], function (I18n, $, GradeFormatHelper) {
  var GradebookHistory = {
    init: function(){
      $('.assignment_header').click(function(event) {
        event.preventDefault();

        var toggleLink = $(this).find('.assignment-header');
        var currentState = toggleLink.attr('aria-expanded');

        toggleLink.attr('aria-expanded', currentState == 'false' ? 'true' : 'false');
        $(this).find('.ui-icon').toggleClass('ui-icon-circle-arrow-n').end()
          .next('.assignment_details').slideToggle('fast');
      });
      $(".revert-grade-link").bind("mouseenter mouseleave", function(){
        $(this).toggleClass("ui-state-hover");
      })
      .click(GradebookHistory.handleGradeSubmit);
    },

    handleGradeSubmit: function(event){
      // 'this' should be the <a href> that they clicked on
      var assignmentId = $(this).parents('tr').data('assignment-id');
      var userId = $(this).parents('tr').data('user-id');
      var grade = $(this).data('grade').toString().replace('--', '');
      var url = $('.update_submission_grade_url').attr('href');
      var method = $('.update_submission_grade_url').attr('title');

      event.preventDefault();
      $('.assignment_' + assignmentId + '_user_' + userId + '_current_grade').addClass('loading');

      var formData = {
        'submission[assignment_id]': assignmentId,
        'submission[user_id]': userId
      };

      if(grade == "EX") {
        formData['submission[excused]'] = 1;
      } else {
        formData['submission[grade]'] = grade;
      }

      $.ajaxJSON(url, method, formData, function(submissions) {
        $.each(submissions, function(){
          var submission = this.submission;
          var el = $('.assignment_' + submission.assignment_id + '_user_' + submission.user_id + '_current_grade')
            el.removeClass('loading');
            el.attr('title', I18n.t('graded_by_me', "%{graded_time} by me", { 'graded_time': $.datetimeString(submission.graded_at) }));
            if(submission.excused) {
              el.text("EX");
            } else {
              el.text(GradeFormatHelper.formatGrade(submission.grade) || '--');
            }
        });
      });
    }
  };

$(document).ready(GradebookHistory.init);
});
