/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

define([
  'i18n!accounts' /* I18n.t */,
  'jquery' /* $ */,
  'str/htmlEscape',
  'jquery.instructure_forms' /* formSubmit */,
  'jqueryui/dialog',
  'compiled/jquery/fixDialogButtons' /* fix dialog formatting */,
  'compiled/jquery.rails_flash_notifications',
  'jquery.templateData' /* fillTemplateData */
], function(I18n, $, htmlEscape) {

  $(".add_course_link").click(function(event) {
    event.preventDefault();
    $("#add_course_form :text").val("");
    $("#add_course_dialog").dialog({
      title: I18n.t('add_course_dialog_title', "Add a New Course"),
      width: 500
    }).fixDialogButtons();
    $("#add_course_form :text:visible:first").focus().select();
  });
  $("#add_course_form").formSubmit({
    formErrors: false,
    required: ['course[name]', 'course[course_code]'],
    beforeSubmit: function(data) {
      $(this).find("button").attr('disabled', true)
        .filter(".submit_button").text(I18n.t('adding_course_message', "Adding Course..."));
    },
    success: function(data) {
      $(this).find("button").attr('disabled', false)
        .filter(".submit_button").text(I18n.t('add_course_button', "Add Course"));
      var course = data;
      if(course.enrollment_term_id == $("#current_enrollment_term_id").text()) {
        var $course = $("#course_blank").clone(true);
        var course_data = {id: course.id};
        $course.find("a.name").text(course.name);
        $course.fillTemplateData({
          data: course_data,
          hrefValues: ['id'],
          id: 'course_' + course.id
        });
        $course.find(".unpublished_icon").show();
        $("ul.courses").prepend($course);
        $course.slideDown();
      }
      $.flashMessage(htmlEscape(I18n.t('course_added_message', "%{course} successfully added!", {course: course.name})));
      $("#add_course_dialog").dialog('close');
    },
    error: function(data) {
      $(this).find("button").attr('disabled', false)
        .filter(".submit_button").text(I18n.t('course_add_failed_message', "Adding Course Failed, please try again"));
    }
  });
  $("#add_course_dialog .cancel_button").click(function() {
    $("#add_course_dialog").dialog('close');
  });
});

