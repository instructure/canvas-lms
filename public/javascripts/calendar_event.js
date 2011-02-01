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

var wikiSidebar;
(function() {
  var hideEditCalendarEventForm = function(redirect) {
    $("#full_calendar_event").show();
    $("#edit_calendar_event_form").hide();
    $("#edit_calendar_event_form textarea").editorBox('destroy');
    if(wikiSidebar) {
      wikiSidebar.hide();
      $("#sidebar_content").show();
    }
    if($("#edit_calendar_event_form").hasClass('new_event')) {
      location.href = $(".calendar_url").attr('href');
    }
  };
  var editCalendarEventForm = function() {
    $("#full_calendar_event").hide();
    var data = $("#full_calendar_event").getTemplateData({
      textValues: ['start_at_date_string', 'start_at_time_string', 'end_at_time_string', 'title', 'all_day', 'all_day_date']
    });
    if(data.description == "No Content") {
      data.description = "";
    }
    data.start_date = data.start_at_date_string;
    data.start_date = $("#full_calendar_event .start_at_date_string").attr('title');
    data.start_time = data.start_at_time_string;
    data.end_time = data.end_at_time_string;
    if(data.all_day == 'true') {
      if(data.all_day_date) {
        data.start_date = data.all_day_date;
      }
      data.start_time = '';
      data.end_time = '';
    }
    $("#edit_calendar_event_form").fillFormData(data, {object_name: 'calendar_event'});
    $("#edit_calendar_event_form").show();
    $("#edit_calendar_event_form textarea").editorBox();
    if(wikiSidebar) {
      wikiSidebar.attachToEditor($("#edit_calendar_event_form").find("textarea:first"));
      wikiSidebar.show();
      $("#sidebar_content").hide();
    }
  };
  $(document).ready(function() {
    if(wikiSidebar) {
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
          location.href = $(".calendar_url").attr('href');
        }
      });
    });
    $(".switch_full_calendar_event_view").click(function(event) {
      event.preventDefault();
      $("#calendar_event_description").editorBox('toggle');
    });
    $(".edit_calendar_event_link").click(function(event) {
      event.preventDefault();
      editCalendarEventForm();
    });
    $("#edit_calendar_event_form .cancel_button").click(function(event) {
      hideEditCalendarEventForm(true);
    });
    $("#edit_calendar_event_form").formSubmit({
      object_name: 'calendar_event',
      processData: function(data) {
        data['calendar_event[start_at]'] = $.datetime.process(data.start_date + " " + data.start_time);
        data['calendar_event[end_at]'] = $.datetime.process(data.start_date + " " + data.end_time);
        data['calendar_event[description]'] = $(this).find("textarea").editorBox('get_code');
        $("#full_calendar_event_holder").fillTemplateData({
          data: data,
          htmlValues: ['description']
        });
        return data;
      },
      beforeSubmit: function(data) {
        hideEditCalendarEventForm();
        $("#full_calendar_event_holder").loadingImage();
      },
      success: function(data) {
        var calendar_event = data.calendar_event;
        var start_at = $.parseFromISO(calendar_event.start_at);
        var end_at = $.parseFromISO(calendar_event.end_at);
        calendar_event.start_at_date_string = start_at.date_formatted;
        calendar_event.start_at_time_string = start_at.time_formatted;
        calendar_event.end_at_time_string = end_at.time_formatted;
        if(Date.parse(calendar_event.all_day_date)) {
          calendar_event.all_day_date = Date.parse(calendar_event.all_day_date).toString("MMM d, yyyy");
        } else {
          calendar_event.all_day_date = '';
        }
        $("#full_calendar_event_holder").find(".from_string,.to_string,.end_at_time_string").showIf(calendar_event.end_at && calendar_event.end_at != calendar_event.start_at);
        $("#full_calendar_event_holder").find(".at_string").showIf(!calendar_event.end_at || calendar_event.end_at == calendar_event.start_at);
        $("#full_calendar_event_holder").find(".not_all_day").showIf(!calendar_event.all_day);
        $("#full_calendar_event_holder").loadingImage('remove');
        $("#full_calendar_event_holder").fillTemplateData({
          data: calendar_event,
          htmlValues: ['description']
        });
        $("#full_calendar_event_holder .start_at_date_string").attr('title', calendar_event.start_at_date_string);
        $(this).find("textarea").editorBox('set_code', calendar_event.description);
        var month = null, year = null;
        if(calendar_event.start_at) {
          year = calendar_event.start_at.substring(0, 4);
          month = calendar_event.start_at.substring(5, 7);
        }
        var calendar_url = $(".base_calendar_url").attr('href');
        var split = calendar_url.split(/#/);
        var anchor = split[1], base_url = split[0];
        var json = {}
        try{
          json = JSON.parse(anchor);
        } catch(e) {
          json = {};
        }
        if(month && year) {
          json.month = month;
          json.year = year;
        }
        $(".calendar_url").attr('href', base_url + "#" + encodeURIComponent(JSON.stringify(json)));
        if($("#full_calendar_event_holder").hasClass('editing')) {
          location.href = $(".calendar_url").attr('href');
        }
      },
      error: function(data) {
        $("#full_calendar_event_holder").loadingImage('remove');
        $(".edit_calendar_event_link:first").click();
        $("#edit_calendar_event_form").formErrors(data);
      }
    });
    setTimeout(function() {
      if($("#full_calendar_event_holder").hasClass('editing')) {
        $(".edit_calendar_event_link:first").click();
      }
    }, 500);
    $(document).fragmentChange(function(event, hash) {
      if(hash == "#edit") {
        $(".edit_calendar_event_link:first").click();
      }
    });
    $.scrollSidebar();
  });
})();
