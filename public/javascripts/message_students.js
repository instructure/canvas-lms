/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import I18n from 'i18n!message_students'
import $ from 'jquery'
import numberHelper from 'jsx/shared/helpers/numberHelper'
import './jquery.instructure_forms' /* formSubmit */
import 'jqueryui/dialog'
import './jquery.instructure_misc_plugins' /* showIf */

  let currentSettings = {}

  function checkSendable() {
    const $message_students_dialog = messageStudentsDialog()
    disableSend(
      $message_students_dialog.find("#body").val().length == 0 ||
      $message_students_dialog.find(".student:not(.blank):visible").length == 0
    );
  }

  /*global messageStudents*/
  window.messageStudents = function(settings) {
    const $message_students_dialog = messageStudentsDialog()
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
      var remove_text = I18n.t("Remove %{student} from recipients", {student: settings.students[i].name});
      var $remove_button = $student.find('.remove-button');
      $remove_button.attr('title', remove_text).append($("<span class='screenreader-only'></span>").text(remove_text));
      $remove_button.click(function(event) {
        event.preventDefault();
        // hide the selected student
        var $s = $(this).closest('li');
        $s.hide('fast', checkSendable);
        // focus the next visible student, or the subject field if that was the last one in the list
        var $next = $s.nextAll(':visible:first');
        if ($next.length) {
          $('button', $next).focus();
        } else {
          $('#message_assignment_recipients #subject').focus();
        }
      });

      $student.data('id', settings.students[i].id);
      $student.user_data = settings.students[i];

      $ul.append($student.show());
      students_hash[settings.students[i].id] = $student;
    }

    $ul.show();

    const dialogTitle = I18n.t('message_student', 'Message Students for %{course_name}', {course_name: title})

    $message_students_dialog.data('students_hash', students_hash),
    $message_students_dialog.find(".asset_title").text(title);
    $message_students_dialog.find(".out_of").showIf(settings.points_possible != null);
    $message_students_dialog.find(".send_button").text(I18n.t("send_message", "Send Message"));
    $message_students_dialog.find(".points_possible").text(I18n.n(settings.points_possible));
    $message_students_dialog.find("[name=context_code]").val(settings.context_code);

    $message_students_dialog.find("textarea").val("");
    $message_students_dialog.find("select")[0].selectedIndex = 0;
    $message_students_dialog.find("select").change();
    $message_students_dialog.dialog({
      width: 600,
      modal: true,
      open: (_event, _ui) => {
        $message_students_dialog.closest('.ui-dialog')
          .attr('role', 'dialog')
          .attr('aria-label', dialogTitle)
      },
      close: (_event, _ui) => {
        $message_students_dialog.closest('.ui-dialog')
          .removeAttr('role')
          .removeAttr('aria-label')
      }
    })
    .dialog('open')
    .dialog('option', 'title', dialogTitle)
    .on('dialogclose', settings.onClose);
  };

  $(document).ready(function() {
    const $message_students_dialog = messageStudentsDialog()
    $message_students_dialog.find("button").click(function(e) {
      var btn = $(e.target);
      if (btn.hasClass("disabled")) {
        e.preventDefault();
        e.stopPropagation();
      }
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
        disableButtons(true)
        $(this).find(".send_button").text(I18n.t("Sending Message..."));
      },
      success: function(data) {
        $.flashMessage(I18n.t("Message sent!"));
        disableButtons(false);
        $(this).find(".send_button").text(I18n.t("Send Message"));
        $("#message_students_dialog").dialog('close');
      },
      error: function(data) {
        disableButtons(false);
        $(this).find(".send_button").text(I18n.t("Sending Message Failed, please try again"));
      }
    });

    var showStudentsMessageSentTo = function() {
      var idx = parseInt($message_students_dialog.find("select").val(), 10) || 0;
      var option = currentSettings.options[idx];
      var students_hash = $message_students_dialog.data('students_hash');
      var cutoff = numberHelper.parse($message_students_dialog.find('.cutoff_score').val());
      if (isNaN(cutoff)) {
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
      disableButtons(student_ids.length === 0);

      var student_ids_hash = {};
      for(var idx in student_ids) {
        if (student_ids.hasOwnProperty(idx)) {
          student_ids_hash[parseInt(student_ids[idx], 10) || 0] = true;
        }
      }
      for(var idx in students_hash) {
        students_hash[idx].showIf(student_ids_hash[idx]);
      }
    };

    var closeDialog = function() {
      $message_students_dialog.dialog('close');
    };

    $message_students_dialog.find(".cancel_button").click(closeDialog);
    $message_students_dialog.find("select").change(showStudentsMessageSentTo).change(checkSendable);
    $message_students_dialog.find(".cutoff_score").bind('change blur keyup', showStudentsMessageSentTo)
      .bind('change blur keyup', checkSendable);
    $message_students_dialog.find("#body").bind('change blur keyup', checkSendable);
  });

  function disableButtons(disabled, buttons) {
    if (buttons == null) {
      buttons = messageStudentsDialog().find("button");
    }
    buttons
      .toggleClass("disabled", disabled)
      .attr("aria-disabled", disabled);
  }

  function disableSend(disabled) {
    disableButtons(disabled, messageStudentsDialog().find(".send_button"));
  }

  function messageStudentsDialog() {
    return $('#message_students_dialog')
  }

export default messageStudents;
