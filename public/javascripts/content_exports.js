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
  'i18n!content_exports',
  'jquery' /* $ */,
  'str/htmlEscape',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* formSubmit */,
  'jqueryui/progressbar' /* /\.progressbar/ */
], function(I18n, $, htmlEscape) {

$(document).ready(function(event) {
  var state = 'nothing';
  var current_id = null;
  var $quiz_selection = $('#quiz_selection'),
      $exporter_form = $('#exporter_form');

  function startPoll() {
    $exporter_form.html(htmlEscape(I18n.t('messages.processing', "Processing")) + "<div style='font-size: 0.8em;'>" + htmlEscape(I18n.t('messages.this_may_take_a_bit', "this may take a bit...")) + "</div>")
       .attr('disabled', true);
    $(".instruction").hide();
    $(".progress_bar_holder").slideDown();
    $(".export_progress").progressbar();
    state = "nothing";
    var fakeTickCount = 0;
    var tick = function() {
      if(state == "nothing") {
        fakeTickCount++;
        var progress = ($(".export_progress").progressbar('option', 'value') || 0) + 0.25;
        if(fakeTickCount < 10) {
          $(".export_progress").progressbar('option', 'value', progress);
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
      $.ajaxJSON(location.href + "/" + current_id, 'GET', {}, function(data) {
        state = "updating";
        var content_export = data.content_export;
        var progress = 0;
        if(content_export) {
          progress = Math.max($(".export_progress").progressbar('option', 'value') || 0, content_export.progress);
          $(".export_progress").progressbar('option', 'value', progress);
        }
        if(content_export.workflow_state == 'exported') {
          $exporter_form.hide();
          $(".export_progress").progressbar('option', 'value', 100);
          $(".progress_message").text(I18n.t("Your content has been exported."));
          $("#export_files").append('<p>' + htmlEscape(I18n.t('labels.new_export', "New Export:")) + ' <a href="' + htmlEscape(content_export.download_url) + '">' + htmlEscape(I18n.t('links.download_plain', "Click here to download")) + '</a> </p>')
        } else if(content_export.workflow_state == 'failed') {
          code = "content_export_" + content_export.id;
          $(".progress_bar_holder").hide();
          $exporter_form.hide();
          var message = I18n.t('errors.error', "There was an error exporting your content.  Please notify your system administrator and give them the following export identifier: \"%{code}\"", {code: code});
          $(".export_messages .error_message").text(message);
          $(".export_messages").show();
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

  $exporter_form.formSubmit({
   success: function(data) {
     if(data && data.content_export) {
       current_id = data.content_export.id
       startPoll();
     } else {
       //show error message
       $(".export_messages .error_message").text(data.error_message);
       $(".export_messages").show();
     }
   },
   error: function(data) {
     $(this).find(".submit_button").attr('disabled', false).text(I18n.t('buttons.process', "Process Data"));
   }
  });

  $exporter_form.delegate('.copy_all', 'click', function() {
    $('.quiz_item').prop('checked', $(this).prop('checked'));
  });

  $exporter_form.delegate('.quiz_item', 'click', function() {
    if( !$(this).prop('checked') ){
      $('.copy_all').prop('checked', false);
    }
  });

  $exporter_form.delegate('input[name=export_type]', 'click', function() {
    if( $(this).val() === 'qti' ) {
      $quiz_selection.show();
    } else {
      $quiz_selection.hide();
    }
  });

  function check_if_exporting() {
      //state = "checking";
      if( $('#current_export_id').size() ){
        //state = "nothing";
        current_id = $('#current_export_id').text()
        startPoll();
      }
  }
  check_if_exporting();

});
});
