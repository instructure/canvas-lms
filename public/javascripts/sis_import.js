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
  'i18n!sis_import',
  'jquery' /* $ */,
  'str/htmlEscape',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* formSubmit, formErrors */,
  'jquery.instructure_misc_plugins' /* showIf, disableIf */,
  'jqueryui/progressbar' /* /\.progressbar/ */
], function(I18n, $, htmlEscape) {

$(document).ready(function(event) {
  var state = 'nothing';
  
  $("#batch_mode").change(function(event) {
    $("#batch_mode_term_id").showIf($(this).attr('checked'));
  }).change();
  
  var $override_sis_stickiness = $("#override_sis_stickiness");
  var $add_sis_stickiness = $("#add_sis_stickiness");
  var $clear_sis_stickiness = $("#clear_sis_stickiness");
  var $add_sis_stickiness_container = $("#add_sis_stickiness_container");
  var $clear_sis_stickiness_container = $("#clear_sis_stickiness_container");
  function updateSisCheckboxes(event) {
    $add_sis_stickiness_container.showIf($override_sis_stickiness.attr('checked'));
    $clear_sis_stickiness_container.showIf($override_sis_stickiness.attr('checked'));
    $add_sis_stickiness.disableIf($clear_sis_stickiness.attr('checked'));
    $clear_sis_stickiness.disableIf($add_sis_stickiness.attr('checked'));
  }

  $override_sis_stickiness.change(updateSisCheckboxes);
  $add_sis_stickiness.change(updateSisCheckboxes);
  $clear_sis_stickiness.change(updateSisCheckboxes);
  updateSisCheckboxes(null);

  function createMessageHtml(batch){
    var output = "";
    if(batch.processing_errors && batch.processing_errors.length > 0){
      output += "<li>" + htmlEscape(I18n.t('headers.import_errors', "Errors that prevent importing")) + "\n<ul>";
      for(var i in batch.processing_errors) {
        var message = batch.processing_errors[i];
        output += "<li>" + htmlEscape(message[0]) + " - " + htmlEscape(message[1]) + "</li>";
      }
      output += "</ul>\n</li>";
    }
    if(batch.processing_warnings && batch.processing_warnings.length > 0){
      output += "<li>" + htmlEscape(I18n.t('headers.import_warnings', "Warnings")) + "\n<ul>";
      for(var i in batch.processing_warnings) {
        var message = batch.processing_warnings[i];
        output += "<li>" + htmlEscape(message[0]) + " - " + htmlEscape(message[1]) + "</li>";
      }
      output += "</ul>\n</li>";
    }
    output += "</ul>";
    return output;
  }
  
  function createCountsHtml(batch){
    if(!(batch.data && batch.data.counts)){
      return '';
    }
    output = "<ul><li>" + htmlEscape(I18n.t('headers.imported_items', "Imported Items")) + "<ul>";
    output += "<li>" + htmlEscape(I18n.t('import_counts.accounts', "Accounts: %{account_count}", {account_count: batch.data.counts.accounts})) + "</li>";
    output += "<li>" + htmlEscape(I18n.t('import_counts.terms', "Terms: %{term_count}", {term_count: batch.data.counts.terms})) + "</li>";
    output += "<li>" + htmlEscape(I18n.t('import_counts.courses', "Courses: %{course_count}", {course_count: batch.data.counts.courses})) + "</li>";
    output += "<li>" + htmlEscape(I18n.t('import_counts.sections', "Sections: %{section_count}", {section_count: batch.data.counts.sections})) + "</li>";
    output += "<li>" + htmlEscape(I18n.t('import_counts.users', "Users: %{user_count}", {user_count: batch.data.counts.users})) + "</li>";
    output += "<li>" + htmlEscape(I18n.t('import_counts.enrollments', "Enrollments: %{enrollment_count}", {enrollment_count: batch.data.counts.enrollments})) + "</li>";
    output += "<li>" + htmlEscape(I18n.t('import_counts.crosslists', "Crosslists: %{crosslist_count}", {crosslist_count: batch.data.counts.xlists})) + "</li>";
    output += "<li>" + htmlEscape(I18n.t('import_counts.groups', "Groups: %{group_count}", {group_count: batch.data.counts.groups})) + "</li>";
    output += "<li>" + htmlEscape(I18n.t('import_counts.group_enrollments', "Group Enrollments: %{group_enrollments_count}", {group_enrollments_count: batch.data.counts.group_memberships})) + "</li>";
    output += "</ul></li></ul>";
    
    return output
  }

  function startPoll() {
    $("#sis_importer").html(htmlEscape(I18n.t('status.processing', "Processing")) + " <div style='font-size: 0.6em;'>" + htmlEscape(I18n.t('notices.processing_takes_awhile', "this may take a bit...")) + "</div>")
       .attr('disabled', true);
    $(".instruction").hide();
    $(".progress_bar_holder").slideDown();
    $(".copy_progress").progressbar();
    state = "nothing";
    var fakeTickCount = 0;
    var tick = function() {
      if(state == "nothing") {
        fakeTickCount++;
        var progress = ($(".copy_progress").progressbar('option', 'value') || 0) + 0.25;
        if(fakeTickCount < 10) {
          $(".copy_progress").progressbar('option', 'value', progress);
        }
        setTimeout(tick, 2000);
      } else {
        state = "nothing";
        fakeTickCount = 0;
        setTimeout(tick, 10000);
      }
    };
    var checkup = function() {
      var lastProgress = null;
      var waitTime = 1500;
      $.ajaxJSON(location.href, 'GET', {}, function(data) {
        state = "updating";
        var sis_batch = data;
        var progress = 0;
        if(sis_batch) {
          progress = Math.max($(".copy_progress").progressbar('option', 'value') || 0, sis_batch.progress);
          $(".copy_progress").progressbar('option', 'value', progress);
          $("#import_log").empty();
        }
        if(!sis_batch || sis_batch.workflow_state == 'imported') {
          $("#sis_importer").hide();
          $(".copy_progress").progressbar('option', 'value', 100);
          $(".progress_message").html($.raw(htmlEscape(I18n.t('messages.import_complete_success', "The import is complete and all records were successfully imported.")) + createCountsHtml(sis_batch)));
        } else if(sis_batch.workflow_state == 'failed') {
          code = "sis_batch_" + sis_batch.id;
          $(".progress_bar_holder").hide();
          $("#sis_importer").hide();
          var message = I18n.t('errors.import_failed_code', "There was an error importing your SIS data. No records were imported.  Please notify your system administrator and give them the following code: \"%{code}\"", {code: code});
          $(".sis_messages .sis_error_message").text(message);
          $(".sis_messages").show();
        } else if(sis_batch.workflow_state == 'failed_with_messages') {
          $(".progress_bar_holder").hide();
          $("#sis_importer").hide();
          var message = htmlEscape(I18n.t('errors.import_failed_messages', "No SIS records were imported. The import failed with these messages:"));
          message += createMessageHtml(sis_batch);
          $(".sis_messages .sis_error_message").html($.raw(message));
          $(".sis_messages").show();
        } else if(sis_batch.workflow_state == 'imported_with_messages') {
          $(".progress_bar_holder").hide();
          $("#sis_importer").hide();
          var message = htmlEscape(I18n.t('messages.import_complete_warnings', "The SIS data was imported but with these messages:"));
          message += createMessageHtml(sis_batch);
          message += createCountsHtml(sis_batch);
          $(".sis_messages").show().html($.raw(message));
        } else {
          if(progress == lastProgress) {
            waitTime = Math.max(waitTime + 500, 30000);
          } else {
            waitTime = 1500;
          }
          lastProgress = progress;
          setTimeout(checkup, 1500);
        }
      }, function() {
        setTimeout(checkup, 3000);
      });
    };
    setTimeout(checkup, 2000);
    setTimeout(tick, 1000)
  }

  $("#sis_importer").formSubmit({
   fileUpload: true,
   success: function(data) {
     if(data && data.id) {
       startPoll();
     } else {
       //show error message
       $(".sis_messages .sis_error_message").text(data.error_message);
       $(".sis_messages").show();
       if(data.batch_in_progress){
         startPoll();
       }
     }
   },
   error: function(data) {
     $(this).find(".submit_button").attr('disabled', false).text(I18n.t('buttons.process_data', "Process Data"));
     $(this).formErrors(data);
   }
  });

  function check_if_importing() {
      state = "checking";
      $.ajaxJSON(location.href, 'GET', {}, function(data) {
        state = "nothing";
        var sis_batch = data;
        var progress = 0;
        if(sis_batch && (sis_batch.workflow_state == "importing" || sis_batch.workflow_state == "created")) {
          state = "nothing";
          startPoll();
        }
    });
  }
  check_if_importing();

});
});
