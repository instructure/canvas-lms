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
require([
  'INST' /* INST */,
  'i18n!full_assignment',
  'jquery' /* jQuery, $ */,
  'wikiSidebar',
  'str/htmlEscape',
  'jquery.instructure_date_and_time' /* parseFromISO, dateString, timeString, date_field, time_field, datetime_field, /\.timepicker/ */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, getFormData, formErrors */,
  'jquery.instructure_jquery_patches' /* /\.dialog/ */,
  'jquery.instructure_misc_helpers' /* replaceTags, scrollSidebar */,
  'jquery.instructure_misc_plugins' /* ifExists, showIf */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'tinymce.editor_box' /* editorBox */,
  'vendor/date' /* Date.parse */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */
], function(INST, I18n, $, wikiSidebar, htmlEscape) {

  // TODO: get these out of global ns
  // hideFullAssignmentForm;
  // addGroupCategory;

  $(function(){
    hideFullAssignmentForm = function(redirect) {
      var $assignment = $("#full_assignment");
      var $form = $("#edit_assignment_form");
      $form.hide();
      if(wikiSidebar) {
        wikiSidebar.hide();
        $("#sidebar_content").show();
      }
      $assignment.find(".description").show();
      $assignment.find(".edit_full_assignment_link").show();
    };

    function doFocus(id) {
      if(!$("#" + id).editorBox('focus')) {
        setTimeout(function(){
          doFocus(id);
        }, 500);
      }
    }

    function editFullAssignment() {
      var $assignment = $("#full_assignment"),
          $form = $("#edit_assignment_form");

      if($form.css('display') === 'none') {
        var data = $assignment.getTemplateData({
          textValues: ['title', 'due_date_string', 'due_time_string', 'points_possible', 'points_type']
        });
        if(data.description == "No Content") {
          data.description = "";
        }
        data.due_date = data.due_date_string;
        data.due_time = data.due_time_string;
        var parsedDate = Date.parse($.trim(data.due_date + " " + data.due_time));
        data.due_at = parsedDate && ($.dateString(parsedDate) + " at " + $.timeString(parsedDate));
        $form.find("select[name='points_type']").change();
        $form.fillFormData(data, {object_name: 'assignment'});
        $assignment.find(".description, .edit_full_assignment_link").hide();
        $form.show().find("textarea:first").editorBox();
        if (wikiSidebar) {
          wikiSidebar.attachToEditor($form.find("textarea:first"));
          wikiSidebar.show();
          $("#sidebar_content").hide();
        }
        $form.find(".more_options_link").show();
        $form.find(".more_assignment_values").hide();
        setTimeout(function(){
          doFocus($form.find("textarea:first").attr('id'));
        }, 500);
        if (!$form.parents(".ui-dialog").length ) {
          $("html,body").scrollTo($form);
        }
        setTimeout(function() {
          $form.find(".assignment_type").change();
        }, 500);
      }
    }

    if(wikiSidebar) {
      wikiSidebar.init();
    }
    var $edit_assignment_form = $('#edit_assignment_form');
    $edit_assignment_form.find(".more_options_link").click(function(event) {
      $(this).focus(); // to ensure its errorBox gets cleaned up (if it has one)
      event.preventDefault();
      $edit_assignment_form.find(".more_options_link").hide();
      $edit_assignment_form.find(".more_assignment_values").show();
      $edit_assignment_form.find(".assignment_type").change();
    });
    $(".edit_full_assignment_link").click(function(event) {
      event.preventDefault();
      editFullAssignment();
    });
    $edit_assignment_form.find(".time_field").timepicker();
    $edit_assignment_form.find(".date_field").datetime_field();
    $edit_assignment_form.find(".assignment_type").change(function(event) {
      var val = $(this).val();
      $edit_assignment_form.find(".assignment_content").showIf(val == "assignment" || val == "discussion_topic" || val == "external_tool");
      $edit_assignment_form.find(".submission_content").showIf(val == "assignment");
      $edit_assignment_form.find(".quiz_content").showIf(val == "quiz");
      $edit_assignment_form.find(".discussion_topic_content").showIf(val == "discussion_topic");
      $edit_assignment_form.find(".external_tool_content").showIf(val == "external_tool");
      $edit_assignment_form.find(".not_graded_content").showIf(val == "not_graded");
      $edit_assignment_form.find(".more_assignment_values.assignment_content").showIf((val == "assignment" || val == "discussion_topic") && !$edit_assignment_form.find(".more_options_link:visible").length);
      if (val == "external_tool" && $("#assignment_external_tool_tag_attributes_url").val() == "") {
        // show the selector immediately
        $("#edit_external_tool_url").click();
      }
    }).triggerHandler('change');
    $edit_assignment_form.find(".points_possible").change(function(event) {
      var points = parseFloat($(this).val());
      if(isNaN(points) || !isFinite(points)) {
        $(this).val("");
        return;
      }
      var $form = $("#edit_assignment_form");
      var data = $form.getFormData({object_name: 'assignment'});
      var oldPoints = $(this).data('old_value');
      var newData = {};
      newData['points_possible'] = points;
      if(!data.mastery_score || (oldPoints && data.mastery_score == Math.round(oldPoints * 0.75 * 10) / 10.0)) {
        var mastery = Math.round(points * 0.75 * 10) / 10.0;
        newData['mastery_score'] = mastery;
      }
      if(!data.max_score || data.max_score == oldPoints) {
        newData['max_score'] = points;
      }
      if(!data.min_score) {
        newData['min_score'] = 0;
      }
      $form.fillFormData(newData, {object_name: 'assignment', call_change: false});
      $(this).data('old_value', points);
    }).change();
    $(".more_grading_options_link").click(function() {
      var hadClass = $(this).hasClass('hide_options');
      $(this).toggleClass('hide_options').text(hadClass ? I18n.t('links.more_grading_options', "more grading options") : I18n.t('links.hide_grading_options', "hide grading options"));
      $(".more_grading_options").showIf(!hadClass);
      return false;
    });
    $(".switch_full_assignment_view").click(function() {
      $edit_assignment_form.find("textarea:first").editorBox('toggle');
      return false;
    });
    $edit_assignment_form.find(".submission_type_option").change(function() {
      $edit_assignment_form.find(".online_submission_types").showIf($(this).val() == "online");
    }).change();
    $edit_assignment_form.formSubmit({
      required: ['title'],
      object_name: 'assignment',
      property_validations: {
        'unlock_at': function(value, data) {
          var unlock_date = Date.parse(data.unlock_at);
          var due_date = Date.parse(data.due_at);
          if(unlock_date && due_date && unlock_date > due_date) {
            return I18n.t('messages.unlock_before_due', "The assignment should be unlocked before it's due");
          }
        },
        'lock_at': function(value, data) {
          var lock_date = Date.parse(data.lock_at);
          var due_date = Date.parse(data.due_at);
          if(lock_date && due_date && lock_date < due_date) {
            return I18n.t('messages.lock_after_due', "The assignment shouldn't be locked again until after the due date");
          }
        },
        '=submission_type': function(value, data) {
          if(value == "online" && data.assignment_type == 'assignment') {
            if(!data.online_upload && !data.online_text_entry && !data.online_url && !data.media_recording) {
              return I18n.t('messages.need_online_submission_type', "Please choose at least one type of online submission");
            }
          }
        },
        'external_tool_tag_attributes[url]': function(value, data) {
          // no, this isn't real url validation
          if (data.assignment_type == 'external_tool' && (value.length < 3 || value.indexOf(' ') >= 0)) {
            return I18n.t('messages.need_url', "Please specify a valid URL");
          }
        }
      },
      onFormError: function(errors) {
        var hiddenErrors = [];
        $.each(errors, function(name, details) {
          if (!details.object.is(':visible')) hiddenErrors.push(htmlEscape(details.message));
        });
        if (hiddenErrors.length) {
          $(this).find('a.more_options_link').errorBox(htmlEscape(I18n.t('messages.hidden_errors', 'There were errors on one or more advanced options')));
        }
      },
      processData: function(data) {
        var date;
        if($(this).find(".more_grading_options").css('display') == 'none') {
          delete data['assignment[min_score]'];
          delete data['assignment[max_score]'];
          delete data['assignment[mastery_score]'];
          delete data['never_drop'];
        }
        $.each(['unlock_at', 'lock_at', 'due_at'], function(i, dateType) {
          if ( (dateType == 'due_at') || data['assignment[' + dateType + ']'] ) {
            date = Date.parse(data['assignment[' + dateType + ']']);
            if(date) {
              data['assignment[' + dateType + ']'] = date.toString('yyyy-MM-ddTHH:mm:ss');
            }
          }
        });
        $.extend(data, {
          'assignment[submission_types]': data.submission_type,
          due_date: $.dateString(date),
          description: $(this).find("textarea:first").editorBox('get_code'),
          'assignment[description]': data.description
        });
        if(data.submission_type == "online") {
          data['assignment[submission_types]'] = $.map(["online_upload", "online_text_entry", "online_url", "media_recording"], function(item) {
            return data[item] && item;
          }).join(",") || "none";
        }
        if(data.assignment_type == 'quiz') { data['assignment[submission_types]'] = 'online_quiz'; }
        if(data.assignment_type == 'not_graded') { data['assignment[submission_types]'] = 'not_graded'; }
        if(data.assignment_type == 'discussion_topic') { data['assignment[submission_types]'] = 'discussion_topic'; }
        if(data.assignment_type == 'external_tool') { data['assignment[submission_types]'] = 'external_tool'; }
        return data;
      }, beforeSubmit: function(data) {
        hideFullAssignmentForm();
        return $("#full_assignment").fillTemplateData({
          data: $.extend($(this).getFormData({ object_name: 'assignment' }), {
            description: $(this).find("textarea:first").editorBox('get_code'),
            due_date_string: data.due_date,
            due_time_string: data.due_time
          }),
          except: ['description']
        }).loadingImage();
      }, success: function(data, $assignment) {
        var assignment = data.assignment,
            date_data = $.parseFromISO(assignment.due_at, 'due_date'),
            $assignment = $("#full_assignment");

        $.extend(assignment, {
          due_date: date_data.date_formatted,
          due_time: date_data.time_formatted,
          timestamp: date_data.timestamp,
          due_date_string: date_data.date_string,
          due_time_string: date_data.time_string,
          lock_at: $.parseFromISO(assignment.lock_at).datetime_formatted,
          unlock_at: $.parseFromISO(assignment.unlock_at).datetime_formatted
        });

        $assignment.find(".quiz_content").showIf(assignment.submission_types == "online_quiz" && assignment.quiz);
        $assignment.find(".discussion_topic_content").showIf(assignment.submission_types == "discussion_topic" && assignment.discussion_topic);
        $("#turnitin_enabled").showIf(assignment.turnitin_enabled);
        $(".readable_submission_types").text(assignment.readable_submission_types || "").showIf(assignment.readable_submission_types);
        if(assignment.quiz) {
          $.extend(assignment, {
            quiz_id: assignment.quiz.id,
            quiz_title: assignment.quiz.title
          });
        }
        if(assignment.discussion_topic) {
          $.extend(assignment, {
            discussion_topic_id: assignment.discussion_topic.id,
            discussion_topic_title: assignment.discussion_topic.title
          });
        }
        $(this).find("textarea:first").editorBox('set_code', assignment.description);
        $(this).fillFormData(assignment, {object_name: 'assignment'});
        $assignment.fillTemplateData({
          data: assignment,
          htmlValues: ['description']
        });
        $("#full_assignment_holder").find(".points_text").showIf(assignment.points_possible || assignment.points_possible === 0);
        $assignment.find(".assignment_quiz_link").attr('href', $.replaceTags($assignment.find(".assignment_quiz_url").attr('href'), 'quiz_id', assignment.quiz_id));
        $assignment.find(".assignment_topic_link").attr('href', $.replaceTags($assignment.find(".assignment_topic_url").attr('href'), 'discussion_topic_id', assignment.discussion_topic_id));
        $assignment.loadingImage('remove');
        $(this).triggerHandler('assignment_updated', data);
        $("#full_assignment_holder .redirect_on_finish_url").ifExists(function(){
          var return_to = $(this).attr('href');
          if (return_to.indexOf('#') > 0) {
            return_to = return_to.substr(0, return_to.indexOf('#'));
          }
          window.location.href = return_to + "#assignment_" + assignment.id;
        });
      },
      error: function(errors, $assignment) {
        editFullAssignment();
        $assignment.loadingImage('remove');
        $edit_assignment_form.formErrors(errors);
      }
    });
    $edit_assignment_form.find(".cancel_button").click(function() {
      hideFullAssignmentForm(true);
    });
    $edit_assignment_form.find("select.grading_type").change(function(event) {
      $edit_assignment_form.find(".edit_letter_grades_link").showIf($(this).val() == "letter_grade");
    });
    $edit_assignment_form.find("#auto_peer_reviews,#manual_peer_reviews").change(function() {
      $edit_assignment_form.find(".auto_peer_reviews").showIf($("#auto_peer_reviews").attr('checked'));
    }).change();
    $(".rubric .long_description_link").click(function(event) {
      event.preventDefault();
      if (!$(this).parents(".rubric").hasClass('editing')) {
        var data = $(this).parents(".criterion").getTemplateData({textValues: ['long_description', 'description']}),
            is_learning_outcome = $(this).parents(".criterion").hasClass("learning_outcome_criterion"),
            $dialog = $("#rubric_long_description_dialog");

        $dialog.fillTemplateData({data: data, htmlValues: ( is_learning_outcome ? ['long_description'] : [] )});
        $dialog.find(".editing").hide();
        $dialog.find(".displaying").show();
        $dialog.dialog('close').dialog({
          autoOpen: false,
          title: I18n.t('titles.criterion_long_description', "Criterion Long Description"),
          width: 400
        }).dialog('open');
      }
    });
    $("#edit_external_tool_url, #assignment_external_tool_tag_attributes_url").click(function(event) {
      event.preventDefault();
      INST.selectContentDialog({
        'select_button_text': I18n.t('buttons.select_url', 'Select'),
        'no_name_input': true,
        'submit': function(item_data) {
          $('#assignment_external_tool_tag_attributes_url').val(item_data['item[url]']);
          $('#assignment_external_tool_tag_attributes_new_tab').val(item_data['item[new_tab]']);
        }
      });
      $("#external_tool_create_url").val($('#assignment_external_tool_tag_attributes_url').val());
    });
    $edit_assignment_form.find(":input").keycodes("esc", function(event) {
      event.preventDefault();
      $(this).parents("form").find(".cancel_button").click();
    });
    var $group = $edit_assignment_form.find("#assignment_assignment_group_id");
    attachAddAssignmentGroup($group);
    if(editIfNoContent) {
      var description = $.trim($("#full_assignment").find(".description").text());
      if(!description || description == "" || description == "No Content") {
        setTimeout(editFullAssignment, 500);
      }
    }
    $("#assignment_group_assignment").change(function() {
      $("#assignment_group_category").showIf($(this).attr('checked'));
      if(!$(this).attr('checked')) {
        $("#assignment_group_category").val("");
      }
    }).change();
    $("#assignment_turnitin_enabled").change(function() {
      $("#assignment_turnitin_settings").showIf($(this).attr('checked'));
    }).change();
    $("#assignment_peer_reviews").change(function() {
      $("#assignment_peer_reviews_options").showIf($(this).attr('checked'));
      if(!$(this).attr('checked')) {
        $("#assignment_peer_reviews_options :text").val("");
      }
    }).change();
    $.scrollSidebar();
    $("#assignment_group_category_select").change(function() {
      var $select = $(this);
      if($(this).val() == "new" && addGroupCategory) {
        addGroupCategory(function(data) {
          var group_category = data[0].group_category;
          var $option = $(document.createElement('option'));
          $option.text(group_category.name).val(group_category.id);
          $select.find("option:last").before($option);
          $select.val(group_category.id);
        });
      }
    });
    $("#assignment_online_upload").change(function() {
      $("#restrict_file_extensions_options").showIf($(this).attr('checked'));
    }).change();
    $("#assignment_restrict_file_extensions").change(function() {
      var $options_div = $('#allowed_extensions_options');
      if ($(this).attr('checked')) {
        $options_div.show();
      } else {
        $options_div.hide();
        $('#assignment_allowed_extensions').val('');
      }
    }).change();
    setTimeout(function() {
      if(location.hash == '#add_rubric') {
        $(".add_rubric_link:visible:first").click();
      } else if(location.hash == '#edit_rubric') {
        var $link = $(".edit_rubric_link:visible:first");
        $("html,body").scrollTo($link.closest(".rubric"));
        $link.click();
      } else if($("#full_assignment_holder").hasClass('editing')) {
        $(".edit_full_assignment_link:first").click();
        $("#full_assignment_holder .more_options_link:first").click();
      }
    }, 500);
  });
});
