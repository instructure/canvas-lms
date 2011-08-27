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

I18n.scoped('feedback', function(I18n) {
$(document).ready(function() {
  var dialogOpened = false;
  var $dialog = $("#feedback_dialog");
  var courses = [];
  function helpInit() {
    var $column = $("#menu .menu-item-drop-column:first")
    var text = $column.find("h2:first").text();
    if(text && text.match(/courses/i)) {
      var added_ids = {};
      $column.find("li").each(function() {
        var type = $(this).find(".subtitle").text();
        if(type && type.match(/student/i)) {
          var name = $(this).find(".name").text();
          var id = $(this).find("a:first").attr('href').split(/\//).pop();
          if(name && id) {
            if(name.length > 60) { 
              name = name.substring(0, 60) + "...";
            }
            courses.push({
              name: name,
              id: id
            });
            added_ids[id] = true;
          }
        }
      });
    }
    var role = 'user';
    if($("#identity_feedback").hasClass('admin')) {
      role = 'admin';
    } else if($("#identity_feedback").hasClass('teacher')) {
      role = 'teacher';
    } else if($("#identity_feedback").hasClass('student') && courses.length) {
      role = 'student';
    }
    $("#help_dialog").children("ul").addClass(role).end()
      .dialog('close').dialog({
        autoOpen: false,
        resizable: false
      }).dialog('open')
  }
  var feedbackInit = function(open) {
    $("#help_dialog").dialog('close');
    if(feedbackInit.already_initialized) { 
      $dialog.triggerHandler('feedback_click');
      return; 
    }
    feedbackInit.already_initialized = true;
    var populateDialog = function(init) {
      if(init) {
        $dialog.find("#feedback_form_user_email")
          .val($("#feedback_user_email").text())
          .parent().showIf(!$("#identity .user_id").text());
        
        $dialog.find(".feedback-course-select")
          .html(function(){
            return $.map(courses, function(course){
              return '<option value="' + course.id + '">' + $.htmlEscape(course.name) + '</option>';
            }).join('');
          })
          .showIf(courses.length > 0);
        $dialog.find(".feedback-type-holder, .feedback-type-teacher").showIf(courses.length > 0);
        $dialog.find(".feedback-type").change();
      }
      if(feedbackInit.default_view == 'message_teacher') {
        $dialog.find("#feedback-type-teacher").attr('checked', true);
      } else {
        $dialog.find("#feedback-type-instructure").attr('checked', true);
      }
      $dialog.find(".feedback-type-holder").showIf(feedbackInit.default_view == 'message_teacher');
      $dialog.find(".feedback_message").showIf(feedbackInit.default_view == 'problem');
      $dialog.find(".feedback-course-select option[value=" + $.trim($("#identity .course_id").text()) + "]").attr('selected', true);
      $dialog.find("#feedback_form_page_url").val(location.href);
      $dialog.find("textarea, #feedback_form_subject").val("")
      $dialog.find("#feedback_form_subject").focus().select();
    };
    var dialogParams = {
      autoOpen: false,
      title: I18n.t('titles.feedback', "Canvas Feedback"),
      width: 500,
      modal: true,
      resizable: false,
      overlay: {
        backgroundColor: "#000",
        opacity: 0.5
      },
      height: 'auto',
      open: function() {
        dialogOpened = true;
        populateDialog();
      },
      close: function() {
        $("#submit_feedback_form .sending_text").text(I18n.t('buttons.send_feedback', "Send Feedback"));
        $(this).find(".send_button").attr('disabled', false);
      }
    };
    $dialog.html("<h3>Loading Feedback Form...</h3>");
    $dialog.dialog('close').dialog(dialogParams).dialog('open');
    $.get("/partials/_feedback.html", function(html) {
      $dialog.html(html);
      populateDialog(true);
      $("#feedback_dialog .feedback-option").click(function() {
        $("#feedback_dialog .feedback-option-selected").removeClass('feedback-option-selected');
        $(this).addClass('feedback-option-selected');
      });
      $("#submit_feedback_form").formSubmit({
        formErrors: false,
        object_name: 'error',
        processData: function(data) {
          var $selected = $(this).find(".feedback-option-selected");
          if($selected.hasClass('idea')) {
            data['error[backtrace]'] = "Posted as an _IDEA_";
          } else if($selected.hasClass('compliment')) {
            data['error[backtrace]'] = "Posted as a _COMPLIMENT_";
          } else {
            data['error[backtrace]'] = "Posted as a _PROBLEM_";
          }
        },
        beforeSubmit: function(data) {
          if(!data.comments) {
            return false;
          }
          $(this)
            .find(".sending_text").text("Sending...").end()
            .find(".send_button").attr('disabled', true);
        },
        success: function(data) {
          $(this).find(".sending_text").text("Thank You!");
          dialogOpened = false;
          setTimeout(function() {
            if(!dialogOpened) {
              $("#feedback_dialog").dialog('close');
            }
          }, 2500);
        },
        error: function(data) {
          $(this).find(".sending_text").text(I18n.t('errors.send_failed', "Send Failed, please try again"));
          $(this).find(".send_button").attr('disabled', false);
        }
      });
      $dialog.bind('feedback_click', function() {
        $dialog.dialog('close').dialog(dialogParams).dialog('open');
      });
    });
  };
  $("#feedback-dialog-select").live('change', function() {
    $dialog.find(".feedback-course-select_holder").showIf($(this).val() == "teacher");
  });
  $(".feedback_link").click(function(event) {
    event.preventDefault();
    $("#feedback_link").click();
    $("#feedback_dialog .feedback-option.idea").click();
  });
  $("#feedback_link").click(function(event) {
    event.preventDefault();
    helpInit();
  });
  $("#help_dialog .message_teacher_link").click(function(event) {
    event.preventDefault();
    feedbackInit.default_view = 'message_teacher';
    feedbackInit(true);
  });
  $("#help_dialog .file_ticket_link").click(function(event) {
    event.preventDefault();
    feedbackInit.default_view = 'problem';
    feedbackInit(true);
  });
});
});
