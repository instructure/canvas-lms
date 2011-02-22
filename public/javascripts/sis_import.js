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

$(document).ready(function(event) {
  var state = 'nothing';
  
  $("#import_type").change(function(event) {
      event.preventDefault();
      new_type = $(this).find(":selected").val();
      $("#batch_check").hide();
      $("#import_log_holder").hide();
  });
  
  function createMessageHtml(batch){
    var output = "";
    if(batch.processing_errors && batch.processing_errors.length > 0){
      output += "<li>Errors that prevent importing\n<ul>";
      for(var i in batch.processing_errors) {
        var message = batch.processing_errors[i];
        output += "<li>" + $.htmlEscape(message[0]) + " - " + $.htmlEscape(message[1]) + "</li>";
      }
      output += "</ul>\n</li>";
    }
    if(batch.processing_warnings && batch.processing_warnings.length > 0){
      output += "<li>Warnings\n<ul>";
      for(var i in batch.processing_warnings) {
        var message = batch.processing_warnings[i];
        output += "<li>" + $.htmlEscape(message[0]) + " - " + $.htmlEscape(message[1]) + "</li>";
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
    output = "<ul><li>Imported Items<ul>";
    output += "<li>Accounts: " + batch.data.counts.accounts + "</li>";
    output += "<li>Terms: " + batch.data.counts.terms + "</li>";
    output += "<li>Courses: " + batch.data.counts.courses+ "</li>";
    output += "<li>Sections: " + batch.data.counts.sections + "</li>";
    output += "<li>Users: " + batch.data.counts.users + "</li>";
    output += "<li>Enrollments: " + batch.data.counts.enrollments + "</li>";
    output += "</ul></li></ul>";
    
    return output
  }

  function startPoll() {
    $("#sis_importer").html("Processing<div style='font-size: 0.6em;'>this may take a bit...</div>")
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
        var sis_batch = data.sis_batch;
        var progress = 0;
        if(sis_batch) {
          progress = Math.max($(".copy_progress").progressbar('option', 'value') || 0, sis_batch.progress);
          $(".copy_progress").progressbar('option', 'value', progress);
          $("#import_log").empty();
          if(sis_batch.sis_batch_log_entries) {
            for(var idx in sis_batch.sis_batch_log_entries) {
              var entry = sis_batch.sis_batch_log_entries[idx].sis_batch_log_entry;
              var lines = entry.text.split("\\n");
              if($("#import_log #log_" + entry.id).length == 0) {
                var $holder = $("<div id='log_" + entry.id + "'/>");
                for(var jdx in lines) {
                  var $div = $("<div/>");
                  $div.text(lines[jdx]);
                  $holder.append($div);
                }
                $("#import_log").append($holder);
              }
            }
          }
        }
        if(!sis_batch || sis_batch.workflow_state == 'imported') {
          $("#sis_importer").hide();
          $(".copy_progress").progressbar('option', 'value', 100);
          $(".progress_message").html("The import is complete and all records were successfully imported." + createCountsHtml(sis_batch));
        } else if(sis_batch.workflow_state == 'failed') {
          code = "sis_batch_" + sis_batch.id;
          $(".progress_bar_holder").hide();
          $("#sis_importer").hide();
          var message = "There was an error importing your SIS data. No records were imported.  Please notify your system administrator and give them the following code: \"" + code + "\"";
          $(".sis_messages .error_message").html(message);
          $(".sis_messages").show();
        } else if(sis_batch.workflow_state == 'failed_with_messages') {
          $(".progress_bar_holder").hide();
          $("#sis_importer").hide();
          var message = "No SIS records were imported. The import failed with these messages:";
          message += createMessageHtml(sis_batch);
          $(".sis_messages .error_message").html(message);
          $(".sis_messages").show();
        } else if(sis_batch.workflow_state == 'imported_with_messages') {
          $(".progress_bar_holder").hide();
          $("#sis_importer").hide();
          var message = "The SIS data was imported but with these messages:";
          message += createMessageHtml(sis_batch);
          message += createCountsHtml(sis_batch);
          $(".sis_messages").show().html(message);
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
     if(data && data.sis_batch) {
       startPoll();
     } else {
       //show error message
       $(".sis_messages .error_message").text(data.error_message);
       $(".sis_messages").show();
       if(data.batch_in_progress){
         startPoll();
       }
     }
   },
   error: function(data) {
     $(this).find(".submit_button").attr('disabled', false).text("Process Data");
     $(this).formErrors(data);
   }
  });

  function check_if_importing() {
      state = "checking";
      $.ajaxJSON(location.href, 'GET', {}, function(data) {
        state = "nothing";
        var sis_batch = data.sis_batch;
        var progress = 0;
        if(sis_batch && (sis_batch.workflow_state == "importing" || sis_batch.workflow_state == "created")) {
          state = "nothing";
          startPoll();
        }
    });
  }
  check_if_importing();

});
