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

var wikiSidebar,
    hideFullAssignmentForm,
    addGroupCategory;

jQuery(function($){
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
      data.due_at = $.parseFromISO(parsedDate && parsedDate.toISOString()).datetime_formatted;
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
    event.preventDefault();
    $edit_assignment_form.find(".more_options_link").hide();
    $edit_assignment_form.find(".more_assignment_values").show();
  });
  $(".edit_full_assignment_link").click(function(event) {
    event.preventDefault();
    editFullAssignment();
  });
  $edit_assignment_form.find(".time_field").timepicker();
  $edit_assignment_form.find(".date_field").datetime_field();
  $edit_assignment_form.find(".assignment_type").change(function(event) {
    var val = $(this).val();
    $edit_assignment_form.find(".assignment_content").showIf(val == "assignment" || val == "discussion_topic");
    $edit_assignment_form.find(".submission_content").showIf(val == "assignment");
    $edit_assignment_form.find(".quiz_content").showIf(val == "quiz");
    $edit_assignment_form.find(".discussion_topic_content").showIf(val == "discussion_topic");
    $edit_assignment_form.find(".not_graded_content").showIf(val == "not_graded");
    $edit_assignment_form.find(".more_assignment_values.assignment_content").showIf((val == "assignment" || val == "discussion_topic") && !$edit_assignment_form.find(".more_options_link:visible").length);
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
    $(this).toggleClass('hide_options').text(hadClass ? "more grading options" : "hide grading options");
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
          return "The assignment should be unlocked before it's due";
        }
      },
      'lock_at': function(value, data) {
        var lock_date = Date.parse(data.lock_at);
        var due_date = Date.parse(data.due_at);
        if(lock_date && due_date && lock_date < due_date) {
          return "The assignment shouldn't be locked again until after the due date";
        }
      },
      '=submission_type': function(value, data) {
        if(value == "online") {
          if(!data.online_upload && !data.online_text_entry && !data.online_url && !data.media_recording) {
            return "Please choose at least one type of online submission";
          }
        }
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
      return data;
    }, beforeSubmit: function(data) {
      hideFullAssignmentForm();
      return $("#full_assignment").fillTemplateData({
        data: $.extend($(this).getFormData({ object_name: 'assignment' }), {
          description: $(this).find("textarea:first").editorBox('get_code'),
          due_date_string: data.due_date,
          due_time_string: data.due_time
        }),
        htmlValues: ['description']
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
        window.location.href = $(this).attr('href') + "#assignment_" + assignment.id;
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
  $edit_assignment_form.find(".edit_letter_grades_link").click(function(event) {
    event.preventDefault();
    $("#edit_letter_grades_form").dialog('close').dialog({
      title: "View/Edit Grading Scheme",
      autoOpen: false,
      width: 600,
      height: 300
    }).dialog('open');
  });
  $(".rubric .long_description_link").click(function(event) {
    event.preventDefault();
    if (!$(this).parents(".rubric").hasClass('editing')) {
      var data = $(this).parents(".criterion").getTemplateData({textValues: ['long_description', 'description']}),
          $dialog = $("#rubric_long_description_dialog");
      
      $dialog.fillTemplateData({data: data});
      $dialog.find(".editing").hide();
      $dialog.find(".displaying").show();
      $dialog.dialog('close').dialog({
        autoOpen: false,
        title: "Criterion Long Description",
        width: 400
      }).dialog('open');
    }
  });
  $(".grading_standard .edit_grading_standard_link").click(function(event) {
    event.preventDefault();
    var $standard = $(this).parents(".grading_standard");
    $standard.addClass('editing');
    if($(this).hasClass('read_only')) {
      $standard.attr('id', 'grading_standard_blank');
    }
    $standard.find(".grading_standard_row").each(function() {
      var data = $(this).getTemplateData({textValues: ['max_score', 'name']});
      $(this).find(".standard_value").val(data.max_score).end()
        .find(".standard_name").val(data.name);
    });
    $standard.find(":text:first").blur();
  });
  $(".grading_standard .grading_standard_brief").find(".collapse_data_link,.expand_data_link").click(function(event) {
    event.preventDefault();
    var $brief = $(this).parents(".grading_standard_brief");
    $brief.find(".collapse_data_link,.expand_data_link").toggle();
    $brief.find(".details").slideToggle();
  });
  $(".grading_standard .grading_standard_select a").click(function(event) {
    event.preventDefault();
    var id = $(this).parents(".grading_standard_select").getTemplateData({textValues: ['id']}).id;
    $(".grading_standard .grading_standards_select .grading_standard_select").removeClass('selected_side_tab');
    $(this).parents(".grading_standard_select").addClass('selected_side_tab');
    $(".grading_standard .grading_standards .grading_standard_brief").hide();
    $("#grading_standard_brief_" + id).show();
  });
  $(".grading_standard").find(".find_grading_standard_link,.cancel_find_grading_standard_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".grading_standard").find(".display_grading_standard,.find_grading_standard").toggle();
    var $find = $(this).parents(".grading_standard").find(".find_grading_standard:visible");
    if($find.length > 0 && !$find.hasClass('loaded')) {
      $find.find(".loading_message").text("Loading Grading Standards...");
      var url = $find.find(".grading_standards_url").attr('href');
      $.ajaxJSON(url, 'GET', {}, function(data) {
        if(data.length === 0) {
          $find.find(".loading_message").text("No grading standards found");
        } else {
          $find.find(".loading_message").remove();
          for(var idx in data) {
            var standard = data[idx].grading_standard;
            standard.user_name = standard.display_name;
            var $standard_select = $find.find(".grading_standards_select .grading_standard_select.blank:first").clone(true);
            $standard_select.fillTemplateData({
              data: standard
            });
            $find.find(".grading_standards_select").append($standard_select.show());
            var $standard = $find.find(".grading_standard_brief.blank:first").clone(true);
            $standard.fillTemplateData({
              data: standard,
              id: 'grading_standard_brief_' + standard.id
            });
            $standard.removeClass('blank');
            for(var jdx = 0; jdx < standard.data.length; jdx++) {
              var list = standard.data[jdx];
              var row = {name: list[0], value: Math.round(list[1] * 100), next_value: 100};
              if(standard.data[jdx - 1]) {
                row.next_value = Math.round(standard.data[jdx - 1][1] * 100) - 1;
              }
              var $row = $standard.find(".details_row.blank:first").clone(true);
              $row.removeClass('blank');
              $row.fillTemplateData({data: row});
              $standard.find(".details > table").append($row.show());
            }
            $find.find(".grading_standards").append($standard);
          }
          $find.find(".grading_standards_select .grading_standard_select:visible:first a:first").click();
        }
        $find.addClass('loaded');
        $find.find(".grading_standards_holder").slideDown();
      }, function(data) {
        $find.find(".loading_message").text("Loading Grading Standards Failed.  Please Try Again");
      });
    }
  });
  $(".grading_standard .grading_standard_brief .select_grading_standard_link").click(function(event) {
    event.preventDefault();
    var id = $(this).parents(".grading_standard_brief").getTemplateData({textValues: ['id']}).id;
    var title = $(this).parents(".grading_standard_brief").getTemplateData({textValues: ['title']}).title;
    var data = [];
    $(this).parents(".grading_standard_brief").find(".details_row:not(.blank)").each(function() {
      var name = $(this).find(".name").text();
      var val = parseInt($(this).find(".value").text(), 10) / 100.0;
      if(isNaN(val)) { val = ""; }
      data.push([name, val]);
    });
    $(this).parents(".grading_standard").triggerHandler('grading_standard_updated', {
      id: id,
      data: data,
      title: title
    });
    $(this).parents(".grading_standard").find(".edit_grading_standard_link").addClass('read_only');
    $(this).parents(".find_grading_standard").find(".cancel_find_grading_standard_link").click();
  });
  $(".grading_standard .cancel_button").click(function(event) {
    $(this).parents(".grading_standard").removeClass('editing')
      .find(".insert_grading_standard").hide();
    var $standard = $(this).parents(".grading_standard");
    $standard.find(".to_add").remove();
    $standard.find(".to_delete").removeClass('to_delete').show();
  });
  $(".grading_standard").bind('grading_standard_updated', function(event, standard) {
    var $standard = $(this);
    $standard.addClass('editing');
    $standard.find(".update_grading_standard_url").attr('href', $("#update_grading_standard_url").attr('href'));
    $standard.fillTemplateData({
      data: standard,
      id: 'grading_standard_' + standard.id,
      hrefValues: ['id']
    });
    var $link = $standard.find(".insert_grading_standard:first").clone(true);
    var $row = $standard.find(".grading_standard_row:first").clone(true).removeClass('blank');
    var $table = $standard.find(".grading_standard_data");
    $table.empty();
    $table.append($link.clone(true).show());
    for(var idx in standard.data) {
      var $row_instance = $row.clone(true);
      var row = standard.data[idx];
      $row_instance.removeClass('to_delete').removeClass('to_add');
      $row_instance.find(".standard_name").val(row[0]).end()
        .find(".standard_value").val(row[1] * 100);
      $table.append($row_instance.show());
      $table.append($link.clone(true).show());
    }
    $table.find(":text:first").blur();
    $table.append($row.hide());
    $table.append($link.hide());
    $standard.find(".grading_standard_row").each(function() {
      $(this).find(".name").text($(this).find(".standard_name").val()).end()
        .find(".max_score").text($(this).find(".standard_value").val()).end()
        .find(".min_score").text($(this).find(".edit_min_score").text());
    });
    $standard.removeClass('editing');
    $standard.find(".insert_grading_standard").hide();
    var put_data = {
      'assignment[grading_standard_id]': standard.id,
      'assignment[grading_type]': 'letter_grade'
    };
    $.ajaxJSON($("#edit_assignment_form").attr('action'), 'PUT', put_data, function(data) {
    }, function() {});
  });
  $(".grading_standard .save_button").click(function(event) {
    var $standard = $(this).parents(".grading_standard");
    var url = $("#edit_letter_grades_form .create_grading_standard_url").attr('href');
    var method = 'POST';
    if($standard.attr('id') != 'grading_standard_blank') {
      url = $(this).parents(".grading_standard").find(".update_grading_standard_url").attr('href');
      method = 'PUT';
    }
    var data = $standard.find(".standard_title,.grading_standard_row:visible").getFormData();
    $standard.loadingImage();
    $.ajaxJSON(url, method, data, function(data) {
      var standard = data.grading_standard;
      $standard.loadingImage('remove');
      $standard.triggerHandler('grading_standard_updated', standard);
    });
  });
  $(".grading_standard thead").mouseover(function(event) {
    if(!$(this).parents(".grading_standard").hasClass('editing')) { return; }
    $(this).parents(".grading_standard").find(".insert_grading_standard").hide();
    $(this).parents(".grading_standard").find(".insert_grading_standard:first").show();
  });
  $(".grading_standard .grading_standard_row").mouseover(function(event) {
    if(!$(this).parents(".grading_standard").hasClass('editing')) { return; }
    $(this).parents(".grading_standard").find(".insert_grading_standard").hide();
    var y = event.pageY;
    var offset = $(this).offset();
    var height = $(this).height();
    if(y > offset.top + (height / 2)) {
      $(this).next(".insert_grading_standard").show();
    } else {
      $(this).prev(".insert_grading_standard").show();
    }
  });
  $(".grading_standard .insert_grading_standard_link").click(function(event) {
    event.preventDefault();
    if($(this).parents(".grading_standard").find(".grading_standard_row").length > 40) { return; }
    var $standard = $(this).parents(".grading_standard");
    var $row = $standard.find(".grading_standard_row:first").clone(true).removeClass('blank');
    var $link = $standard.find(".insert_grading_standard:first").clone(true);
    var temp_id = null;
    while(!temp_id || $(".standard_name[name='grading_standard[standard_data][scheme_" + temp_id + "][name]']").length > 0) {
      temp_id = Math.round(Math.random() * 10000);    
    }
    $row.find(".standard_name").val("-").attr('name', 'grading_standard[standard_data][scheme_' + temp_id + '][name]');
    $row.find(".standard_value").attr('name', 'grading_standard[standard_data][scheme_' + temp_id + '][value]');
    $(this).parents(".insert_grading_standard").after($row.show());
    $row.after($link);
    $standard.find(":text:first").blur();
    $row.find(":text:first").focus().select();
    $row.addClass('to_add');
  });
  $(".grading_standard .delete_row_link").click(function(event) {
    event.preventDefault();
    if($(this).parents(".grading_standard").find(".grading_standard_row:visible").length < 2) { return; }
    var $standard = $(this).parents(".grading_standard_row");
    if($standard.prev(".insert_grading_standard").length > 0) {
      $standard.prev(".insert_grading_standard").remove();
    } else {
      $standard.next(".insert_grading_standard").remove();
    }
    $standard.fadeOut(function() {
      $(this).addClass('to_delete');
    });
  });
  $(".grading_standard input[type='text']").bind('blur change', function() {
    var $standard = $(this).parents(".grading_standard");
    var val = parseInt($(this).parents(".grading_standard_row").find(".standard_value").val(), 10);
    if(isNaN(val)) { val = null; }
    var lastVal = val || 100;
    var prevVal = val || 0;
    var $list = $standard.find(".grading_standard_row:not(.blank,.to_delete)");
    for(var idx = $list.index($(this).parents(".grading_standard_row")) + 1; idx < $list.length; idx++) {
      var $row = $list.eq(idx);
      var points = parseInt($row.find(".standard_value").val(), 10);
      if(isNaN(points)) { points = null; }
      if(idx == 0) { 
        points = 100; 
      }
      else if(!points || points > lastVal - 2) {
        points = lastVal - 2;
      }
      $row.find(".standard_value").val(points);
      lastVal = points;
    }
    for(var idx = $list.index($(this).parents(".grading_standard_row")) - 1; idx  >= 0; idx--) {
      var $row = $list.eq(idx);
      var points = parseInt($row.find(".standard_value").val(), 10);
      if(isNaN(points)) { points = null; }
      if(idx == 0) { 
        points = 100; 
      }
      else if(!points || points < prevVal + 2) {
        points = prevVal + 2;
      }
      prevVal = points;
      $row.find(".standard_value").val(points);
    }
    lastVal = 100;
    $list.each(function(idx) {
      var points = parseInt($(this).find(".standard_value").val(), 10);
      var idx = $list.index(this);
      if(isNaN(points)) { points = null; }
      if(idx == 0) { 
        points = 100; 
      }
      else if(!points || points > lastVal - 2) {
        points = lastVal - 2;
      }
      $(this).find(".standard_value").val(points);
      lastVal = points;
    });
    prevVal = 0;
    for(var idx = $list.length - 1; idx  >= 0; idx--) {
      var $row = $list.eq(idx);
      var points = parseInt($row.find(".standard_value").val(), 10);
      if(isNaN(points)) { points = null; }
      if(idx == 0) { 
        points = 100; 
      }
      else if(!points || points < prevVal + 2) {
        points = prevVal + 2;
      }
      prevVal = points;
      $row.find(".standard_value").val(points);
    }
    $list.each(function(idx) {
      var $next = $list.eq(idx + 1);
      var min_score = 0;
      if($next && $next.length > 0) {
        min_score = parseInt($next.find(".standard_value").val(), 10) + 1;
        if(isNaN(min_score)) { min_score = 0; }
        $(this).find(".edit_min_score").text(min_score);
      }
    });
    $list.filter(":last").find(".edit_min_score").text(0);
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
        var category = $(this).data('category_name') || "Category";
        var $option = $(document.createElement('option'));
        $option.text(category).val(category);//.toLowerCase().replace(/\s/g, "_"));
        $select.find("option:last").before($option);
        $select.val(category.toLowerCase().replace(/\s/g, "_"));
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
