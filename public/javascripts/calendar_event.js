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
  'timezone',
  'i18n!calendar_events',
  'jquery' /* jQuery, $ */,
  'wikiSidebar',
  'jquery.instructure_date_and_time' /* dateString, timeString, date_field, time_field, /\$\.datetime/ */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */,
  'jquery.instructure_misc_helpers' /* encodeToHex, scrollSidebar */,
  'jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange, showIf */,
  'jquery.loadingImg' /* loadingImg, loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'compiled/tinymce',
  'tinymce.editor_box' /* editorBox */,
  'vendor/date' /* Date.parse */
], function(tz, I18n, $, wikiSidebar) {

  var noContentText = I18n.t('no_content', "No Content");

$(function($) {
  var $full_calendar_event        = $("#full_calendar_event"),
      $edit_calendar_event_form   = $("#edit_calendar_event_form"),
      $full_calendar_event_holder = $("#full_calendar_event_holder");

      
  function hideEditCalendarEventForm(redirect) {
    $full_calendar_event.show();
    $edit_calendar_event_form.hide()
      .find("textarea").editorBox('destroy');
    if (wikiSidebar) {
      wikiSidebar.hide();
      $("#sidebar_content").show();
    }
    if (redirect && $edit_calendar_event_form.hasClass('new_event')) {
      window.location.href = $(".calendar_url").attr('href');
    }
  };
  function editCalendarEventForm() {
    $full_calendar_event.hide();
    var data = $full_calendar_event.getTemplateData({
      textValues: ['start_at_date_string', 'start_at_time_string', 'end_at_time_string', 'title', 'all_day', 'all_day_date']
    });
    if (data.description == noContentText) {
      data.description = "";
    }
    data.start_date = data.start_at_date_string;
    data.start_time = data.start_at_time_string;
    data.end_time = data.end_at_time_string;
    if (data.all_day == 'true') {
      if (data.all_day_date) {
        data.start_date = data.all_day_date;
      }
      data.start_time = '';
      data.end_time = '';
    }
    $edit_calendar_event_form
      .fillFormData(data, {object_name: 'calendar_event'})
      .show()
        .find("textarea").editorBox();
    if (wikiSidebar) {
      wikiSidebar.attachToEditor($edit_calendar_event_form.find("textarea:first"));
      wikiSidebar.show();
      $("#sidebar_content").hide();
    }
  };

  if (wikiSidebar) {
    wikiSidebar.init();
  }
  $(".date_field").date_field();
  $(".time_field").time_field();
  $(".delete_event_link").click(function(event) {
    event.preventDefault();
    $("#full_calendar_event_holder").confirmDelete({
      message: "Are you sure you want to delete this event?",
      url: $(this).attr('href'),
      success: function() {
        $(this).fadeOut('slow');
        window.location.href = $(".calendar_url").attr('href');
      }
    });
  });
  $(".switch_full_calendar_event_view").click(function() {
    $("#calendar_event_description").editorBox('toggle');
    //  todo: replace .andSelf with .addBack when JQuery is upgraded.
    $(this).siblings(".switch_full_calendar_event_view").andSelf().toggle();
    return false;
  });
  $(".edit_calendar_event_link").click(function() {
    editCalendarEventForm();
    return false;
  });
  $edit_calendar_event_form.find(".cancel_button").click(function() {
    hideEditCalendarEventForm(true);
    return false;
  });
  $edit_calendar_event_form.formSubmit({
    object_name: 'calendar_event',
    processData: function(data) {
      data['calendar_event[start_at]'] = $.datetime.process(data.start_date + " " + data.start_time);
      data['calendar_event[end_at]'] = $.datetime.process(data.start_date + " " + data.end_time);
      data['calendar_event[description]'] = $(this).find("textarea").editorBox('get_code');
      $full_calendar_event_holder.fillTemplateData({
        data: data,
        except: ['description']
      });
      return data;
    },
    beforeSubmit: function(data) {
      hideEditCalendarEventForm();
      $full_calendar_event_holder.loadingImage();
    },
    success: function(data) {
      var calendar_event = data.calendar_event,
          start_at       = tz.parse(calendar_event.start_at);

      
      calendar_event.start_at_date_string = $.dateString(start_at);
      calendar_event.start_at_time_string = $.timeString(start_at);
      calendar_event.end_at_time_string = $.timeString(calendar_event.end_at);
      calendar_event.all_day_date = $.dateString(calendar_event.all_day_date);
      
      $full_calendar_event_holder.find(".from_string,.to_string,.end_at_time_string").showIf(calendar_event.end_at && calendar_event.end_at != calendar_event.start_at);
      $full_calendar_event_holder.find(".at_string").showIf(!calendar_event.end_at || calendar_event.end_at == calendar_event.start_at);
      $full_calendar_event_holder.find(".not_all_day").showIf(!calendar_event.all_day);
      $full_calendar_event_holder
        .loadingImage('remove')
        .fillTemplateData({
          data: calendar_event,
          htmlValues: ['description']
        });
      $(this).find("textarea").editorBox('set_code', calendar_event.description);
      var month = null, year = null;
      if (calendar_event.start_at) {
        year = calendar_event.start_at.substring(0, 4);
        month = calendar_event.start_at.substring(5, 7);
      }
      var calendar_url = $(".base_calendar_url").attr('href'),
          split = calendar_url.split(/#/),
          anchor = split[1], 
          base_url = split[0],
          json = {};
          
      try{
        json = $.parseJSON(anchor) || {};
      } catch(e) {
        json = {};
      }
      if (month && year) {
        json.month = month;
        json.year = year;
      }
      $(".calendar_url").attr('href', base_url + "#" + $.encodeToHex(JSON.stringify(json)));

      window.location.href = $(".calendar_url").attr('href');
    },
    error: function(data) {
      $full_calendar_event_holder.loadingImage('remove');
      $(".edit_calendar_event_link:first").click();
      $edit_calendar_event_form.formErrors(data);
    }
  });
  setTimeout(function() {
    if ($full_calendar_event_holder.hasClass('editing')) {
      $(".edit_calendar_event_link:first").click();
    }
  }, 500);
  $(document).fragmentChange(function(event, hash) {
    if (hash == "#edit") {
      $(".edit_calendar_event_link:first").click();
    }
  });
  $.scrollSidebar();

});
});
