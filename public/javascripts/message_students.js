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
  'i18n!message_students',
  'jquery' /* $ */,
  'jquery.instructure_forms' /* formSubmit */,
  'jqueryui/dialog',
  'compiled/jquery/fixDialogButtons' /* fix dialog formatting */,
  'jquery.instructure_misc_plugins' /* showIf */
], function(I18n, $) {

  var $message_students_dialog = $("#message_students_dialog");
  var currentSettings = {};
  window.messageStudents = function(settings) {
    currentSettings = settings;
    $message_students_dialog.find(".message_types").empty();
    for(var idx=0, l=settings.options.length; idx < l; idx++) {
      var $option = $("<option/>");
      var option = settings.options[idx];
      $option.val(idx).text(option.text);
      $message_students_dialog.find(".message_types").append($option);
    }

    var title = settings.title,
        $li = $message_students_dialog.find("ul li.blank:first"),
        $ul = $message_students_dialog.find("ul"),
        students_hash = {};

    $message_students_dialog.find("ul li:not(.blank)").remove();

    for (var i = 0; i < settings.students.length; i++) {
      var $student = $li.clone(true).removeClass('blank');

      $student.find('.name').text(settings.students[i].name);
      $student.find('.score').text(settings.students[i].score);
      $student.data('id', settings.students[i].id);
      $student.user_data = settings.students[i];

      $ul.append($student.show());
      students_hash[settings.students[i].id] = $student;
    }

    $ul.show();

    $message_students_dialog.data('students_hash', students_hash),
    $message_students_dialog.find(".asset_title").text(title);
    $message_students_dialog.find(".out_of").showIf(settings.points_possible != null);
    $message_students_dialog.find(".send_button").text(I18n.t("send_message", "Send Message"));
    $message_students_dialog.find(".points_possible").text(settings.points_possible);
    $message_students_dialog.find("[name=context_code]").val(settings.context_code);

    $message_students_dialog.find("textarea").val("");
    $message_students_dialog.find("select")[0].selectedIndex = 0;
    $message_students_dialog.find("select").change();
    $message_students_dialog.dialog({
      width: 600,
      modal: true
    }).fixDialogButtons().dialog('open').dialog('option', 'title', I18n.t("message_student", "Message Students for %{course_name}", {course_name: title}));
  };
  $(document).ready(function() {
    $message_students_dialog.find(".cutoff_score").bind('change blur keyup', function() {
      $message_students_dialog.find("select").change();
    });
    $message_students_dialog.find(".cancel_button").click(function() {
      $message_students_dialog.dialog('close');
    });
    $("#message_assignment_recipients").formSubmit({
      processData: function(data) {
        var ids = [];
        $(this).find(".student:visible").each(function() {
          ids.push($(this).data('id'));
        });
        if(ids.length == 0) { return false; }
        data['recipients'] = ids.join(",");
        return data;
      },
      beforeSubmit: function(data) {
        $(this).find("button").attr('disabled', true).filter(".send_button").text(I18n.t("buttons.sending_message", "Sending Message..."));
      },
      success: function(data) {
        $(this).find(".send_button").text("Message Sent!");
        var $form = $(this);
        setTimeout(function() {
          $form.find("button").attr('disabled', false).filter(".send_button").text(I18n.t("buttons.send_message", "Send Message"));
          $("#message_students_dialog").dialog('close');
        }, 2000);
      },
      error: function(data) {
        $(this).find("button").attr('disabled', false).filter(".send_button").text(I18n.t("buttons.send_message_failed", "Sending Message Failed, please try again"));
      }
    });
    $message_students_dialog.find("select").change(function() {
      var idx = parseInt($(this).val(), 10) || 0;
      var option = currentSettings.options[idx];
      var students_hash = $message_students_dialog.data('students_hash'),
          cutoff = parseFloat($message_students_dialog.find(".cutoff_score").val(), 10);
      if (!cutoff && cutoff !== 0) {
        cutoff = null;
      }
      var student_ids = null;
      var students_list = [];
      for(var idx in students_hash) {
        students_list.push(students_hash[idx]);
      }
      if(students_hash) {
        if(option && option.callback) {
          student_ids = option.callback.call(window.messageStudents, cutoff, students_list);
        } else if(currentSettings.callback) {
          student_ids = currentSettings.callback.call(window.messageStudents, option.text, cutoff, students_list);
        }
      }
      student_ids = student_ids || [];

      if (currentSettings.subjectCallback) {
        $message_students_dialog.find("[name=subject]").val(currentSettings.subjectCallback(option.text, cutoff));
      }
      $message_students_dialog.find(".cutoff_holder").showIf(option.cutoff);

      $message_students_dialog.find(".student_list").toggleClass('show_score', !!(option.cutoff || option.score));
      $message_students_dialog.find("button").attr('disabled', student_ids.length == 0);

      var student_ids_hash = {};
      for(var idx in student_ids) {
        if (student_ids.hasOwnProperty(idx)) {
          student_ids_hash[parseInt(student_ids[idx], 10) || 0] = true;
        }
      }
      for(var idx in students_hash) {
        students_hash[idx].showIf(student_ids_hash[idx]);
      }
    });
  });

  return messageStudents;
});
