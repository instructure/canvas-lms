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
  'INST' /* INST */,
  'i18n!calendars',
  'jquery' /* $ */,
  'timezone',
  'compiled/userSettings',
  'calendar_move' /* calendarMonths */,
  'jqueryui/draggable' /* /\.draggable/ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* parseDateTime, formatDateTime, parseFromISO, dateString, datepicker, date_field, time_field, datetime_field, /\$\.datetime/ */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, getFormData, hideErrors */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* encodeToHex, decodeFromHex, replaceTags */,
  'jquery.instructure_misc_plugins' /* .dim, confirmDelete, fragmentChange, showIf */,
  'jquery.keycodes' /* keycodes */,
  'compiled/jquery.rails_flash_notifications',
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'vendor/date' /* Date.parse */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/datepicker' /* /\.datepicker/ */,
  'jqueryui/resizable' /* /\.resizable/ */,
  'jqueryui/sortable' /* /\.sortable/ */,
  'jqueryui/tabs' /* /\.tabs/ */
], function(INST, I18n, $, tz, userSettings, calendarMonths) {

  window.calendar = {
    activateEventId: ENV.CALENDAR.ACTIVE_EVENT,
    viewItem: function(context_string, item_id, item_type) {
    },
    showingUndatedEvents: false,
    appendToCache: function(url, data) {
      var items = {}
      calendarMonthDataCache[url] = calendarMonthDataCache[url] || [];
      $.each(data, function(i, val) {
        var asset_string = null;
        if(val.calendar_event) {
          asset_string = "calendar_event_" + val.calendar_event.id;
        } else {
          asset_string = "assignment_" + val.assignment.id;
        }
        items[asset_string] = val;
      });
      $.each(calendarMonthDataCache[url], function(i, val) {
        var asset_string = null;
        if(val.calendar_event) {
          asset_string = "calendar_event_" + val.calendar_event.id;
        } else {
          asset_string = "assignment_" + val.assignment.id;
        }
        if(items[asset_string]) {
          calendarMonthDataCache[url][i] = items[asset_string];
          items[asset_string] = null;
        }
      });
      $.each(items, function(i, val) {
        if(val) {
          calendarMonthDataCache[url].push(val);
        }
      });
    },
    removeFromCache: function(options) {
      for(var url in calendarMonthDataCache) {
        var events = $.merge([], calendarMonthDataCache[url]);
        var new_events = []
        var changed = false;
        for(var i = 0; i < events.length; i++) {
          var event_type = events[i].assignment ? "assignment" : "calendar_event";
          var event = events[i][event_type];
          var asset_string = event_type + "_" + event.id;
          if(options.asset_string && options.asset_string == asset_string) {
            changed = true;
          } else {
            new_events.push(events[i]);
          }
        }
        if(changed) {
          calendarMonthDataCache[url] = new_events;
        }
      }
    },
    lastUpdate: {}
  }

  function eventDragStart(event, ui) {
    $(document).data('dragging', true);
    $(this).parents(".calendar_day_holder").addClass('selected');
    if($(this).hasClass("event_pending") || !($(this).data('event_data') || {}).can_edit) {
      event.preventDefault();
      event.stopPropagation();
      return false;
    }
    setTimeout(measureCalendar, 50);
    $(this).addClass("event_pending");
  }

  function measureCalendar() {
    $(".calendar_month, .calendar_week, .calendar_day, .calendar_undated, .mini_calendar, .mini_calendar_week, .mini_calendar_day").each(function() {
      if($(this).data('drag_position')) { return; }
      var $obj = $(this);
      var offset = $obj.offset();
      var width = $obj.outerWidth();
      var height = $obj.outerHeight();
      if($(this).hasClass('.calendar_week')) {
        height = $obj.find(".calendar_day:first").outerHeight();
      }
      $(this).data('drag_position', {
        offset: offset,
        width: width,
        height: height
      });
    });
  }

  var $lastIntersection = null;
  function eventIntersect(event, ui) {
    event = event.originalEvent;
    var x = event.pageX;
    var y = event.pageY;
    var $month = null;
    var $week = null;
    var $day = null;
    if(!$(".calendar_day_undated").data('drag_position')) { return; }
    if($lastIntersection) {
      var position = $lastIntersection.data('drag_position');
      if(x >= position.offset.left && x <= position.offset.left + position.width 
          && y >= position.offset.top && y <= position.offset.top + position.height) {
        return $lastIntersection;
      }
    }
    $(".calendar_day_undated").each(function() {
      var position = $(this).data('drag_position');
      if(x >= position.offset.left && x <= position.offset.left + position.width 
          && y >= position.offset.top && y <= position.offset.top + position.height) {
        $day = $(this);
        return false;
      }
    });
    if($day) {
      return $day;
    }
    $(".calendar_month,.mini_calendar").each(function() {
      var position = $(this).data('drag_position');
      if(x >= position.offset.left && x <= position.offset.left + position.width 
          && y >= position.offset.top && y <= position.offset.top + position.height) {
        $month = $(this);
        return false;
      }
    });
    if($month) {
      $month.find(".calendar_week,.mini_calendar_week").each(function() {
        var position = $(this).data('drag_position');
        if(x >= position.offset.left && x <= position.offset.left + position.width 
            && y >= position.offset.top && y <= position.offset.top + position.height) {
          $week = $(this);
          return false;
        }
      });
      if($week) {
        $week.find(".calendar_day,.mini_calendar_day").each(function() {
          var position = $(this).data('drag_position');
          if(x >= position.offset.left && x <= position.offset.left + position.width 
              && y >= position.offset.top && y <= position.offset.top + position.height) {
            $day = $(this);
            return false;
          }
        });
      }
    }
    $lastIntersection = $day;
    return $day;
  }

  function eventDragStop(event, ui) {
    $(document).data('dragging', false);
    $("td.selected").removeClass('selected');
    $(".drop_target").removeClass('drop_target');
    var $day = eventIntersect(event, ui);
    var $event = $(this);
    if($day && $day[0] != $event.parents(".calendar_day")[0]) {
      var data = $.extend({}, $event.getTemplateData({
        textValues: ['start_date_string', 'start_time_string', 'end_time_string', 'event_type', 'id', 'context_id', 'context_type', 'all_day']
      }), $event.data('event_data'));
      var context = data.context_type.toLowerCase() + "_" + data.context_id;
      var startTime, endTime, eventType = data.event_type;
      if(data.all_day == 'true') {
        data.start_time_string = '';
        data.end_time_string = '';
      }
      if($day.hasClass('calendar_day_undated')) {
        startTime = null;
        endTime = null;
      } else {
        var old_date = $event.parents(".calendar_day").find(".day_number").attr('title');
        var new_date = $day.find(".day_number").attr('title');
        startTime = $.parseDateTime(new_date, data.start_time_string);
        endTime = $.parseDateTime(new_date, data.end_time_string);
      }
      var action = $("#context_urls ." + context + "_event_url").attr('href');
      if(eventType == "assignment") {
        data = $.extend(data, $.formatDateTime(startTime, {
          object_name: 'assignment',
          property_name: 'due_at'
        }));
        action = $("#context_urls ." + context + "_assignment_url").attr('href');
      } else {
        data = $.extend(data, $.formatDateTime(startTime, {
          object_name: 'calendar_event',
          property_name: 'start_at'
        }));
        data = $.extend(data, $.formatDateTime(endTime, {
          object_name: 'calendar_event',
          property_name: 'end_at'
        }));
      }
      action = $.replaceTags(action, 'id', data.id);
      var day_code = null;
      if($day.hasClass('mini_calendar_day')) {
        day_code = ($day.find(".day_number").attr('title') || '');
        var date = Date.parse(day_code);
        if(date) {
          $day = $("#day_" + date.toString('yyyy_MM_dd')).find(".calendar_day");
        }
      }
      addEventToDay($event, $day.parent());
      $.ajaxJSON(action, 'PUT', data, function(data) {
        $event.removeClass('event_pending');
        updateEvent(data);
        updateEventInCache(data);
        if(!$day.length && day_code) {
          $.flashMessage(I18n.t('notices.event_moved', "%{event} was moved to %{day}", {event: ($event.find(".title").text() || I18n.t('default_title', "event")), day: day_code}));
        }
      });
    } else {
      $(this).removeClass("event_pending");
    }
  }

  var eventDraggable = {
    helper: function() {
      var width = $(this).outerWidth();
      var $result = $(this).clone();
      $result.width(width).css('zIndex', 20);
      $(this).parents(".calendar_container").append($result);
      return $result;
    },
    scroll: true, 
    drag: function(event, ui) {
      if($.browser['msie']) {
        return;
      }
      var $day = eventIntersect(event, ui);
      if($day && $day.hasClass('drop_target')) { return; }
      $(".drop_target").removeClass('drop_target');
      if($day) {
        $day.closest('.calendar_day_holder,.mini_calendar_day').addClass('drop_target');
      }
    },
    start: eventDragStart, 
    stop: eventDragStop
  };
  function addEventToDay($event, $day, add_to_end) {
    $before = null;
    if($day.length === 0) { $event.remove(); }
    if(!add_to_end) {
      $day.find(".calendar_event").each(function() {
        var a_time = ($(this).data('event_data') || {}).time_sortable || "";
        var b_time = ($event.data('event_data') || {}).time_sortable || "";
        if(a_time > b_time) {
          $before = $(this);
          return false;
        } else if(a_time == b_time && $(this).find(".title").text() > $event.find(".title").text()) {
          $before = $(this);
          return false;
        }
      });
    }
    if($before && !add_to_end) {
      $before.before($event.show());
    } else {
      $day.children("div.calendar_day").append($event.show());
    }
    return $event;
  }
  function changeCalendarMonth($month, change) {
    calendarMonths.changeMonth($month, change);
    if(!$month.hasClass('mini_month')) {
      setTimeout(doRefreshMonth, 500);
    }
  }
  function doRefreshMonth() {
    $month = $(".calendar_container .calendar_month");
    refreshMonthData($month, true);
  }
  var calendarMonthDataCache = {};
  function updateEventInCache(event) {
    var obj = event.calendar_event || event.assignment;
    var id = obj.id
    for(var url in calendarMonthDataCache) {
      calendar.appendToCache(url, [event]);
    }
  }
  function deleteEventInCache($event) {
    var id = $event.attr('id').split('_').pop();
    var event_type = $event.hasClass('assignment') ? 'assignment' : 'calendar_event';
    calendar.removeFromCache({asset_string: event_type + "_" + id});
  }
  $.fn.monthLoading = function(action) {
    $.fn.monthLoading.cnt = Math.max($.fn.monthLoading.cnt || 0, 0);
    if(action) {
      $.fn.monthLoading.cnt--;
    } else {
      $.fn.monthLoading.cnt++;
    }
    this.find(".refresh_calendar_link").find(".static").showIf($.fn.monthLoading.cnt <= 0).end()
      .find(".animated").showIf($.fn.monthLoading.cnt > 0);
    return this;
  }

  function updateEvents(events, batch) {
    var cnt = 0;
    var draggables = [];
    var nextEvent = function(finish) {
      if(events.length > 0) {
        var event = events.shift();
        cnt++;
        if(event) {
          var id = updateEvent(event, null, batch);
          draggables.push("#event_" + id);
        }
        if(cnt > 50) {
          cnt = 0;
          setTimeout(function() { nextEvent(finish) }, 500);
        } else {
          nextEvent(finish);
        }
      } else if(finish) {
        var find = draggables.join(",");
      }
    };
    setTimeout(function() { nextEvent(true); }, 10);
  }
  function refreshMonthData($month, cache, timeout, include_undated) {
    var month, year;
    var isShowing = true;
    if(typeof($month) == "string") {
      var date = $month.split("/");
      month = date[0];
      year = date[1];
      $month = $(".calendar_month:first");
      isShowing = false;
    } else {
      $month.monthLoading();
      month = parseInt($month.find(".month_number").text(), 10);
      year = parseInt($month.find(".year_number").text(), 10);
    }
    var url = "/calendar?" + $.param({ month: month, year: year });
    var requestUrl = url + (include_undated == false ? "" : "&include_undated=1");
    var contexts_to_load = [];
    if(!calendarMonthDataCache[url]) {
      calendarMonthDataCache[url] = [];
    }
    calendarMonthDataCache[url].contexts_last_update_at = calendarMonthDataCache[url].contexts_last_update_at || {};
    calendarMonthDataCache[url].contexts_loading = calendarMonthDataCache[url].contexts_loading || {};
    var lastUpdateAt = null;
    var allContextsLoaded = true;
    $(".calendar_links .group_reference_checkbox:checked").each(function() {
      var code = $(this).attr('id').substring(6);
      if(!calendarMonthDataCache[url].contexts_last_update_at[code]) {
        allContextsLoaded = false;
      }
      if(lastUpdateAt != "" && calendarMonthDataCache[url].contexts_last_update_at[code]) {
        if(!lastUpdateAt || calendarMonthDataCache[url].contexts_last_update_at[code] < lastUpdateAt) {
          lastUpdateAt = calendarMonthDataCache[url].contexts_last_update_at[code];
        }
      } else {
        lastUpdateAt = "";
      }
      if(!calendarMonthDataCache[url].contexts_loading[code]) {
        if(!cache || !calendarMonthDataCache[url].contexts_last_update_at[code]) {
          contexts_to_load.push(code);
        }  
      }
    });

    requestUrl = requestUrl + "&last_update_at=" + (lastUpdateAt || "");
    var month_events = {}
    if(isShowing) {
      $month.find(".calendar_event").each(function() {
        if($(this).attr('id')) {
          month_events[$(this).attr('id')] = true;
        }
      });
    }
    delete month_events['event_blank'];
    delete month_events['event_new'];
    delete month_events['event_id'];
    
    if(cache && allContextsLoaded && calendarMonthDataCache[url] && (calendarMonthDataCache[url].dont_retry || calendarMonthDataCache[url].length > 0)) {
      var data = $.merge([], calendarMonthDataCache[url]);
      if(isShowing) {
        updateEvents(data)
        $month.monthLoading('remove');
      }
    } else {
      if(isShowing) {
        $month.monthLoading('remove');
      }
      var options = {};
      if(timeout) {
        options['timeout'] = 2000;
      }
      var clumps = [];
      var clump = []
      for(var idx in contexts_to_load) {
        clump.push(contexts_to_load[idx]);
        if(clump.length >= 5) {
          clumps.push(clump);
          clump = []
        }
      }
      if(clump.length > 0) {
        clumps.push(clump);
      }
      for(var idx in clumps) {
        if(isShowing) {
          $month.monthLoading();
        }
        (function(codes, url, requestUrl) {
          for(var jdx in codes) {
            calendarMonthDataCache[url].contexts_loading[codes[jdx]] = true;
          }
          var newUrl = requestUrl + "&only_contexts=" + codes.join(",");
          $.ajaxJSON(newUrl, 'GET', {}, function(data) {
            // can't just assign this variable if you're looking to ping only for what's
            // been updated or this will overwrite the cache as an empty list
            calendar.appendToCache(url, data);
            $.each(data, function(i, val) {
              var code = (val.calendar_event || val.assignment).context_code;
              var updated_at = (val.calendar_event || val.assignment).updated_at;
              if(!calendar.lastUpdate[url] || updated_at > calendar.lastUpdate[url]) {
                calendar.lastUpdate[url] = updated_at;
              }
              if(!calendarMonthDataCache[url].contexts_last_update_at[code] || updated_at > calendarMonthDataCache[url].contexts_last_update_at[code]) {
                calendarMonthDataCache[url].contexts_last_update_at[code] = updated_at;
              }
            });
            var lastUpdateAt = (new Date()).toString("u");
            for(var jdx in codes) {
              calendarMonthDataCache[url].contexts_last_update_at[codes[jdx]] = calendarMonthDataCache[url].contexts_last_update_at[codes[jdx]] || lastUpdateAt;
              calendarMonthDataCache[url].contexts_loading[codes[jdx]] = false;
            }
            if(isShowing) {
              updateEvents(data, true);
              $month.monthLoading('remove');
            }
          }, function(data) {
            if(calendarMonthDataCache[url] && calendarMonthDataCache[url].dont_retry) {
              calendarMonthDataCache[url].dont_retry = false;
            }
            for(var jdx in codes) {
              calendarMonthDataCache[url].contexts_loading[codes[jdx]] = false;
            }
            if(isShowing) {
              $month.monthLoading('remove');
            }
          });
        })(clumps[idx], url, requestUrl);
      }
    }
  }

  var calendar_event_url = $("#event_details").find('.calendar_event_url').attr('href');
  var assignment_url = $("#event_details").find('.assignment_url').attr('href');
  var $event_blank = $("#event_blank");
  var $undated_count = $(".show_undated_link .undated_count");

  // Internal: Pad a number with zeroes until it is max length.
  //
  // n - The number to pad.
  // max - The desired length.
  //
  // Returns a zero-padded string.
  function pad(n, max) {
    var result = n.toString();

    if (n < 0) throw new Error('n cannot be negative');

    while (result.length < max) {
      result = '0' + result;
    }

    return result;
  }

  function updateEvent(data, $event, batch) {
    var event = $.extend({}, data.assignment);
    var id = null;
    var details_url = null;
    if(data.calendar_event) {
      event = $.extend({}, data.calendar_event);
      var start_date_data = $.parseFromISO(event.start_at);
      var end_date_data = $.parseFromISO(event.end_at);
      event.datetime = (start_date_data && start_date_data.datetime);
      event.start_time_string = start_date_data.time_string;
      event.end_time_string = end_date_data.time_string;
      event.start_time_formatted = start_date_data.time_formatted;
      event.start_date_string = start_date_data.date_formatted;
      event.end_time_formatted = end_date_data.time_formatted;
      event.time_sortable = start_date_data.time_sortable;
      event.event_type = "calendar_event";
      id = "calendar_event_" + event.id;
      updateEvent.details_urls = updateEvent.details_urls || {};
      key = 'calendar_event_' + event.context_type + event.context_id;
      if(!updateEvent.details_urls[key]) {
        var url = calendar_event_url;
        url = $.replaceTags(url, 'context_id', event.context_id)
        url = $.replaceTags(url, 'context_type', event.context_type.toLowerCase());
        updateEvent.details_urls[key] = url;
      }
      details_url = updateEvent.details_urls[key];
    } else {
      var date_data = $.parseFromISO(event.due_at);
      event.datetime = (date_data && date_data.datetime);
      event.start_time_string = date_data.time_string;
      event.end_time_string = date_data.time_string;
      event.start_time_formatted = date_data.time_formatted;
      event.start_date_string = date_data.date_formatted;
      event.end_time_formatted = date_data.time_formatted;
      event.time_sortable = date_data.time_sortable;
      event.start_at = event.due_at;
      event.event_type = "assignment";
      id = "assignment_" + event.id;
      updateEvent.details_urls = updateEvent.details_urls || {};
      key = 'assignment_' + event.context_type + event.context_id;
      if(!updateEvent.details_urls[key]) {
        var url = assignment_url;
        url = $.replaceTags(url, 'context_id', event.context_id)
        url = $.replaceTags(url, 'context_type', event.context_type.toLowerCase());
        updateEvent.details_urls[key] = url;
      }
      details_url = updateEvent.details_urls[key];
      details_url = $.replaceTags(details_url, 'id', event.id)
      details_url = $.replaceTags(details_url, 'context_id', event.context_id)
      details_url = $.replaceTags(details_url, 'context_type', event.context_type.toLowerCase());
    }
    if($event && $event.attr('id') == 'event_new') {
      $event.attr('id', 'event_' + id);
    }
    if(!event.start_at && !$event && !calendar.showingUndatedEvents) {
      calendar.hiddenUndatedEvents = calendar.hiddenUndatedEvents || [];
      calendar.hiddenUndatedEvents.push(data);
      $undated_count.text(calendar.hiddenUndatedEvents.length)
      return;
    }
    if(!$event || ($event.attr('id') != 'event_new' && $event.attr('id') != 'event_' + id)) {
      $event = $("#event_" + id + ":visible");
      if($event.length > 0 && $event.find(".updated_at").text() == event.updated_at) {
        return;
      }
    }
    $event = $("#event_" + id);
    if(event.all_day) {
      var all_day_date = $.parseFromISO(event.all_day_date);
      if(all_day_date.valid) {
        event.all_day_date = all_day_date.date_formatted;
        event.start_at = all_day_date.date_sortable.substring(0, 10);
      } else {
        event.all_day_date = '';
        event.start_at = '';
      }
      event.start_time_formatted = '';
      event.end_time_formatted = '';
    } else {
      event.all_day_date = '';
    }
    var isManagementContext = ENV.calendarManagementContexts && $.inArray(event.context_code, ENV.calendarManagementContexts) != -1;
    if(event.permissions || isManagementContext) {
      event.can_edit = isManagementContext || (event.permissions && event.permissions.update);
      event.can_delete = isManagementContext || (event.permissions && event.permissions['delete']);
    }
    if(event.workflow_state == 'deleted') {
      $event.remove();
      return id;
    }
    if(!$event || $event.length === 0) {
      $event = $event_blank.clone(true);
      details_url = $.replaceTags(details_url, 'id', event.id);
      $event.find(".title").attr('href', details_url);
      $event.toggleClass('assignment', !!data.assignment);
      if(batch !== true) {
        $event.draggable(eventDraggable);
      }
    } else if($event.find(".title").attr('href') === '#') {
      details_url = $.replaceTags(details_url, 'id', event.id);
      $event.find(".title").attr('href', details_url);
    }
    $event.fillTemplateData({
      data: {
        title: event.title
      },
      hrefValues: ['id'],
      id: "event_" + id
    });
    $event.data('event_data', event);
    $event.toggleClass('draggable', event.can_edit);
    $event.data('description', event.description);
    var classes = $event.attr('class') || "";
    var groupId = 'group_' + event.context_code;
    $event.addClass(groupId);
    // Set the calendar name the event belongs to in the screenreader
    // accessible span with class calendar-name-text.
    $event.find('.calendar-name-text').text($('.' + groupId).find('label').text());
    $event.addClass('event_' + id);
    var $day = $(".calendar_undated");
    if(event.datetime) {
      var dayID = ['#day'];
      dayID.push(event.datetime.getFullYear());
      dayID.push(pad(event.datetime.getMonth() + 1, 2));
      dayID.push(pad(event.datetime.getDate(), 2));
      $day = $(dayID.join('_'));
    }
    if(!$event.hasClass('event_pending')) {
      addEventToDay($event, $day, batch);
    }
    var title_time = event.start_time_formatted || "";
    if(event.start_time_string && event.start_time_string != event.end_time_string) {
      title_time += " to " + (event.end_time_formatted || "");
    }
    event_title = event.title;
    event_title += (title_time ? " - " + title_time : "");
    if(data.assignment && title_time) {
      event_title = "due: " + event_title;
    }
    $event.find(".calendar_event_text").attr('title', event_title).show();
    if($("#" + groupId).length > 0) {
      $event.showIf($("#" + groupId).attr('checked'));
    }

    // After loading the data, if have an event to activate and the event was just updated, show it.
    if (event.id == calendar.activateEventId && calendar.activateEventId) {
      $day = $event.parents(".calendar_day");
      // Remove the ID from being automatically activated on the next data refresh
      calendar.activateEventId = null;
      showEvent($event, $day);
    }

    return id;
  }
  function refreshCalendarData(cache) {
    $(".calendar_month").each(function() {
      refreshMonthData($(this), cache || false, true, null);
    })
  }
  function showEvent($event, $day) {
    var $box = $("#event_details"),
        $editEvent = $('#edit_event');
    var data = $.extend({}, $event.getTemplateData({
      textValues: ['id', 'start_time_string', 'end_time_string', 'start_date_string', 'title', 'event_type', 'can_edit', 'can_delete', 'context_id', 'context_type', 'all_day'],
      htmlValues: ['description']
    }), $event.data('event_data'));
    data.description = $event.data('description');
    data.start_time = data.start_time_string;
    data.end_time = data.end_time_string;

    var date = {};
    var year = "";
    var date_string = "";
    if($day.find(".day_number").length) {
      year = $day.find(".day_number").attr('title').split("/").pop();
      date_string = data.start_date_string;
      if(!date_string.match(new RegExp(year))) {
        date_string = date_string + " " + year;
      }
    }
    if(data.all_day == 'true') {
      date = tz.parse(date_string);
      data.time_string = $.dateString(date);
    } else if(data.start_time_string) {
      date = tz.parse(date_string);
      data.time_string = $.dateString(date);
    } else {
      data.time_string = "No Date Set";
      data.date = "";
    }
    $box.data('current_event', $event).data('current_day', $day);
    var details_url = null;
    $box.find(".title").attr('href', $event.find('.title').attr('href'));
    $box.find(".view_event_link").attr('href', $event.find('.title').attr('href'));
    $box.find(".delete_event_link").attr('href', $event.find('.delete_' + data.event_type + '_link').attr('href'));
    $box.find(".edit_event").showIf(data.can_edit && !data.frozen);
    $box.find(".delete_event").showIf(data.can_delete && !data.frozen);
    var isNew = $event.attr('id') == "event_blank";
    var type_name = "Event";
    var $form = null;
    if(isNew) {
      $("#edit_event").addClass('new_event');
    } else {
      $("#edit_event").removeClass('new_event');
    }
    if(data.event_type == "assignment") {
      type_name = "Assignment";
    }
    if(data.event_type == "assignment" || data.start_time == data.end_time) {
      if(data.all_day == 'true' && data.event_type == 'assignment') {
        data.time_string = data.start_date_string + " at " + data.start_time_string;
      } else if(data.start_time) {
        var date_string = $.dateString(date);
        data.time_string = date_string + " at " + data.start_time_string;
      }
      if(data.event_type == 'assignment' && data.time_string) {
        data.time_string = "due: " + data.time_string;
      }
    }
    data.description = $event.data('description');
    $box.fillTemplateData({data: data, htmlValues: ['description']});
    if (data.lock_info) {
      $box.find(".lock_explanation").html(INST.lockExplanation(data.lock_info, 'assignment'));
    }
    if ($editEvent.data('dialog')) $editEvent.dialog('close');
    $box.find(".description").css("max-height", Math.max($(window).height() - 200, 150));
    var title = type_name == "Event" ? I18n.t('event_details', "Event Details") : I18n.t('assignment_details', "Assignment Details");
    $box.dialog({
      title: title,
      width: (data.description.length > 2000 ? Math.max($(window).width() - 300, 450) : 450),
      resizable: true,

      close: function() {
        $(document).click();
        deselectDateForEvent();
      },
      open: function() {
        $(document).triggerHandler('event_dialog', $(this));
      }
    });
    $event.addClass('selected');
    selectDateForEvent($day.parents(".calendar_day_holder"));
  }
  function selectDateForEvent($day_holder) {
    $(".calendar_container").data('prevent_hover', true);
    $(".calendar_day_holder.selected").removeClass('selected');
    $(".mini_calendar .day.related").removeClass('related');
    $day_holder.addClass('selected');
    var title = $day_holder.find(".day_number").attr('title');
    if(title) {
      var $mini_day = $(".mini_calendar .day.date_" + title.replace(/\//g, "_"));
      $mini_day.addClass('related');
    }
  }
  function deselectDateForEvent() {
    $(".calendar_container").data('prevent_hover', false);
    $(".calendar_day_holder.selected").removeClass('selected');
    $(".mini_calendar .day.related").removeClass('related');
  }
  function setFormURLs($form, context, id) {
    if($form.attr('id') == "edit_assignment_form") {
      if($form.hasClass('new_event')) {
        $form.attr('method', 'POST');
        var url = $("#context_urls ." + context + "_add_assignment_url").attr('href') || "";
        $form.find(".more_options_link").attr('href', $("." + context + "_add_assignment_url").attr('href') + "/new");
        $form.attr('action', url);
      } else {
        $form.attr('method', 'PUT');
        var url = $("#context_urls ." + context + "_assignment_url").attr('href') || "";
        url = $.replaceTags(url, 'id', id);
        $form.find(".more_options_link").attr('href', url + "/edit");
        $form.attr('action', url);
      }
    } else {
      if($form.hasClass('new_event')) {
        $form.attr('method', 'POST');
        var url = $("#context_urls ." + context + "_add_event_url").attr('href') || "";
        $form.find(".more_options_link").attr('href', $("." + context + "_add_event_url").attr('href') + "/new");
        $form.attr('action', url);
      } else {
        $form.attr('method', 'PUT');
        var url = $("#context_urls ." + context + "_event_url").attr('href') || "";
        url = $.replaceTags(url, 'id', id);
        $form.find(".more_options_link").attr('href', url + "/edit");
        $form.attr('action', url);
      }
    }
  }
  function editEvent($event, $day) {
    var $box = $("#edit_event"),
        $eventDetails = $('#event_details');
    var data = $.extend({}, $event.data('event_data'), $event.getTemplateData({ textValues: [ 'title' ] }));
    data.description = $event.data('description');
    data.context_type = data.context_type || "";
    data.id = data.id || "";
    var context = data.context_type.toLowerCase() + "_" + data.context_id;
    if(!data.context_type || $event.attr('id') == 'event_blank') {
      context = $("#edit_event select.context_id").val()
    }
    data.start_time = data.start_time_string || "";
    data.end_time = data.end_time_string || "";
    data.date = $day.find(".day_number").attr('title');
    if(data.all_day == 'true') {
      data.start_time = '';
      data.end_time = '';
      data.date = data.all_day_date;
    }
    data.due_at = "";
    var startDate = Date.parse(data.date + " " + data.start_time) || Date.parse(data.date); 
    var endDate = Date.parse(data.date + " " + data.end_time) || Date.parse(data.date);
    if(startDate) {
      data.date = startDate.toString('MMM d, yyyy');
      data.due_at = $.datetime.clean(startDate);
      if(data.start_time_string) {
        data.start_time = startDate.toString('h:mmtt').toLowerCase();
      }
      if(data.end_time_string) {
        data.end_time = endDate.toString('h:mmtt').toLowerCase();
      }
    } else {
      data.date = "";
    }
    var isNew = $event.attr('id') == "event_blank";
    var type_name = "Event";
    var $form = null;
    $("#edit_event,#edit_assignment_form,#edit_calendar_event_form").toggleClass('new_event', isNew);
    if(isNew) {
      data.event_type == "calendar_event";
    }
    var selectedTabIndex = 0;
    var $assignmentForm = $box.find("#edit_assignment_form");
    $assignmentForm.find("select.context_id").val(context);
    setFormURLs($assignmentForm, context, data.id);
    
    var $eventForm = $box.find("#edit_calendar_event_form");
    $eventForm.find("select.context_id").val(context);
    setFormURLs($eventForm, context, data.id);

    if(data.event_type == "assignment") {
      $form = $assignmentForm;
      type_name = "Assignment";
    } else {
      $form = $eventForm;
    }
    $("#edit_assignment_form,#edit_calendar_event_form").data('event_id', data.id)
      .data('context', context);
    $("#event_details").data('current_event', $event);
    $("#edit_assignment_form").data('current_event', $event);
    $("#edit_calendar_event_form").data('current_event', $event);
    $("#edit_assignment_form").fillFormData(data, {object_name: 'assignment'});
    $("#edit_calendar_event_form").fillFormData(data, {object_name: 'calendar_event'});
    if ($eventDetails.data('dialog')) $eventDetails.dialog('close');
    selectDateForEvent($day.parents(".calendar_day_holder"));
    var title;
    if (isNew) {
      title = type_name == "Event" ? I18n.t('titles.add_new_event', "Add New Event") : I18n.t('titles.add_new_assignment', "Add New Assignment");
    } else {
      title = type_name == "Event" ? I18n.t('titles.edit_event', "Edit Event") : I18n.t('titles.edit_assignment', "Edit Assignment");
    }
    $box.dialog({
      title: title,
      width: 400,
      open: function() {
        $(document).triggerHandler('edit_event_dialog', $box);
        var $tabs = $box.find("#edit_event_tabs");
        var $event = $("#event_details").data('current_event');
        var data = $.extend({}, $event.data('event_data'));
        var isNew = $event.attr('id') == 'event_blank';
        
        var idsToShow = $.map( $(".group_reference_checkbox:checked"), function(e, i){
          return $(e).attr('id').replace('group_', '');
        });

        $("#edit_event .context_select").each(function() {
          var $select  = $(this).find("select.context_id"),
              forceValue = window.thisElementFiredTheEvent && ($(window.thisElementFiredTheEvent).closest('.group_reference').find('.group_reference_checkbox').attr('id') || "").replace('group_', ''),
              $options = $select
                .find('option')
                .attr('disabled', function(){
                  return idsToShow.length && ($.inArray( $(this).val() , idsToShow ) === -1);
                });
          if (idsToShow.length) { $select.val(forceValue || idsToShow[0]) };
          $(this).showIf(isNew);
          
          $select.val(context);
          $select.triggerHandler('change', false);
        });
        
        $tabs.tabs('enable', 0);
        $tabs.tabs('enable', 1);
        var selectedTabIndex = 0;
        if(data.event_type == "assignment") {
          selectedTabIndex = 1;
          $tabs.tabs('select', 1);
          if(isNew) {
            $tabs.find(".ui-tabs-nav").show();
          } else {
            $tabs.find(".ui-tabs-nav").hide();
            $tabs.tabs('disable', 0);
          }
        } else {
          $tabs.tabs('select', 0);
          if(isNew) {
            $tabs.find(".ui-tabs-nav").show();
          } else {
            $tabs.find(".ui-tabs-nav").hide();
            $tabs.tabs('disable', 1);
          }
          if($("#edit_assignment_form select.context_id option").filter(function(){ return !$(this).attr('disabled'); }).length === 0) {
            $tabs.tabs('disable', 1);
            selectedTabIndex = 0;
          } 
        }
        if(isNew) { selectedTabIndex = 0; }
        $tabs.tabs('select', selectedTabIndex);
        if(selectedTabIndex == 0) {
          $("#edit_calendar_event_form :text:first").focus().select();
        } else {
          $("#edit_assignment_form :text:first").focus().select();
        }
        $tabs.find(".ui-tabs-panel:eq(" + $tabs.tabs('option', 'selected')  + ") select.context_id").triggerHandler('change');
        $("#edit_assignment_form").find(".assignment_group_id").val(data.assignment_group_id);
      },
      drag: function() {
        $form.hideErrors();
      },
      autoSize: true,
      close: function() {
        deselectDateForEvent();
        var $select = $("#edit_event .assignment_group_id");
        if($select.length > 0) {
          var $originalSelect = $("#" + $select.attr('id').substring(5));
          $originalSelect.empty().append($select.children().clone());
        }
        var idx = $("#edit_event_tabs").data('selected.tabs');
        if($("#edit_event").hasClass('new_event')) {
          var data = {};
          if(idx == 1) {
            data = $("#edit_assignment_form").getFormData({
              object_name: 'assignment'
            });
            data.event_type = "assignment";
            data.start_time_string = data.start_time;
            data.end_time_string = data.start_time;
          } else {
            data = $("#edit_calendar_event_form").getFormData({
              object_name: 'calendar_event'
            });
            data.event_type = "calendar_event";
            data.start_time_string = data.start_time;
            data.end_time_string = data.end_time;
          }
          $("#event_blank").fillTemplateData({data: data});
        }
        $form.find("input[name='date']").datepicker('hide');
      },
      resizable: false,
      modal: true
    });
    
    // if we know the context that the event is being edited for, color the box that contex's color
    if (data.context_id && data.context_type) {
        var $elementToAddBackgroundTo =$box.find("#edit_event_tabs"),
            contextString = ("" + data.context_type + "_" + data.context_id).toLowerCase();
        if ($elementToAddBackgroundTo.data('group_class')) {
          $elementToAddBackgroundTo.removeClass( $elementToAddBackgroundTo.data('group_class') )
        }
        $elementToAddBackgroundTo.addClass('group_' + contextString).data( "group_class", 'group_' + contextString );
    }
  }
  function calendarEventMove(direction) {
    var $day = $(".calendar_container .calendar_day_holder.selected:first");
    if(!$day || $day.length === 0) { calendarMove(direction); return; }
    var $events = $day.find(".calendar_event");
    var $current = $events.filter(".selected:first");
    if($events.length === 0) {
      if(direction == "down") { direction = "right"; }
      else if(direction == "up") { direction = "left"; }
      calendarMove(direction);
      return;
    } else if(!$current || $current.length === 0) {
      $(".calendar_event.selected").removeClass('selected');
      if(direction == "up") {
        $current = $day.find(".calendar_event:last");
      } else {
        $current = $day.find(".calendar_event:first");
      }
      $current.find("a.title").focus();
      $current.addClass('selected');
      $("html,body").scrollTo($current);
      return;
    }
    if(direction == "up") {
      var $new = $current.prev(".calendar_event");
    } else {
      var $new = $current.next(".calendar_event");
    }
    if($new && $new.length > 0) {
      $(".calendar_event.selected").removeClass('selected');
      $new.find("a.title").focus();
      $new.addClass('selected');
      $("html,body").scrollTo($new);
    } else {
      if(direction == "down") { direction = "right"; }
      else if(direction == "up") { direction = "left"; }
      calendarMove(direction);
    }
  }
  function calendarMove(direction) {
    var $current = $(".calendar_container .calendar_day_holder.selected:first");
    if(!$current || $current.length === 0) {
      $(".calendar_container .calendar_day_holder.selected").removeClass('selected');
      $(".calendar_container .calendar_event.selected").removeClass('selected');
      $current = $(".calendar_container .calendar_day_holder .current_month").eq(0).parent();
      $current.addClass('selected');
      $("html,body").scrollTo($current);
      return;
    }
    var $month = $current.parents(".calendar_month");
    var $new = null;
    var dateNumbers = $current.attr('id').split('_');
    var date = new Date(dateNumbers[1], dateNumbers[2] - 1, dateNumbers[3]);
    if(direction == "right") {
      $new = $current.next().find(".current_month").parent();
      if($new.length === 0) {
        $new = $current.parent().next(".visible").find(".calendar_day_holder .current_month").eq(0).parent();
      }
      if($new.length === 0) {
        date.setDate(date.getDate() + 1);
        changeCalendarMonth($month, 1);
        $new = $("#day_" + $.datepicker.formatDate('yy_mm_dd', date));
      }
    } else if(direction == "left") {
      $new = $current.prev().find(".current_month").parent();
      if($new.length === 0) {
        $new = $current.parent().prev(".visible").find(".calendar_day_holder .current_month").filter(":last").parent();
      }
      if($new.length === 0) {
        date.setDate(date.getDate() - 1);
        changeCalendarMonth($month, -1);
        $new = $("#day_" + $.datepicker.formatDate('yy_mm_dd', date));
      }
    } else if(direction == "up") {
      var idx = $current.parent().children(".calendar_day_holder").index($current);
      $new = $current.parent().prev(".visible").children(".calendar_day_holder").eq(idx).find(".current_month").parent();
      if($new.length === 0) {
        date.setDate(date.getDate() - 7);
        changeCalendarMonth($month, -1);
        $new = $("#day_" + $.datepicker.formatDate('yy_mm_dd', date));
      }
    } else if(direction == "down") {
      var idx = $current.parent().children(".calendar_day_holder").index($current);
      $new = $current.parent().next(".visible").children(".calendar_day_holder").eq(idx).find(".current_month").parent();
      if($new.length === 0) {
        date.setDate(date.getDate() + 7);
        changeCalendarMonth($month, 1);
        $new = $("#day_" + $.datepicker.formatDate('yy_mm_dd', date));
      }
    }
    if($new && $new.length > 0) {
      $new.focus();
      $(".calendar_container .calendar_day_holder.selected").removeClass('selected');
      $(".calendar_container .calendar_day.hover").removeClass('hover');
      $(".calendar_container .calendar_event.selected").removeClass('selected');
      $new.addClass('selected');
      $new.find(".calendar_day").addClass('hover');
      $("html,body").scrollTo($new);
    }
  }
  $(document).ready(function() {
    $(".calendar_day.today").removeClass('today');
    $("#day_" + (new Date()).toString("yyyy_MM_dd")).children(".calendar_day").addClass('today');
    $(".show_undated_link").click(function(event) {
      event.preventDefault();
      calendar.showingUndatedEvents = true;
      $(".undated_link").hide();
      events = (calendar.hiddenUndatedEvents || []).sort(function(a, b) {
        var a_title = (a.calendar_event || a.assignment || {}).title || "";
        var b_title = (b.calendar_event || b.assignment || {}).title || "";
        if(a_title < b_title) {
          return 0;
        } else if(b_title > a_title) {
          return 1;
        } else {
          return 0;
        }
      });
      updateEvents(events || [], true);
      $(".undated_content").show();
    });
    $("#edit_calendar_event_form .more_options_link").click(function(event) {
      event.preventDefault();
      var pieces = $(this).attr('href').split("#");
      var data = $("#edit_calendar_event_form").getFormData({object_name: 'calendar_event'});
      var params = {};
      if(data.title) { params['title'] = data.title; }
      if(data.date) { 
        params['start_at'] = data.date + " " + (data.start_time || ""); 
        params['end_at'] = data.date + " " + (data.end_time || "");
      }
      params['return_to'] = location.href;
      pieces[0] += "?" + $.param(params);
      location.href = pieces.join("#");
    });
    $(".calendar_event").live('mouseover', function() {
      if(!$(this).hasClass('ui-draggable') && $(this).hasClass('draggable')) {
        $(this).draggable(eventDraggable);
      }
    });
    $("#edit_assignment_form .more_options_link").click(function(event) {
      event.preventDefault();
      var pieces = $(this).attr('href').split("#");
      var data = $("#edit_assignment_form").getFormData({object_name: 'assignment'});
      var params = {};
      if(data.title) { params['title'] = data.title; }
      if(data.due_at) { params['due_at'] = data.due_at; }
      if(data.assignment_group_id) { params['assignment_group_id'] = data.assignment_group_id; }
      params['return_to'] = location.href;
      pieces[0] += "?" + $.param(params);
      location.href = pieces.join("#");
    });
    $(".calendar_feed_link").click(function(event) {
      event.preventDefault();
      $("#calendar_feed_box").find(".calendar_feed_url").val($(this).attr('href')).end()
        .find(".show_calendar_feed_link").attr('href', $(this).attr('href'));
      $("#calendar_feed_box").dialog({
        title: I18n.t('feed_dialog_title', "Calendar Feed"),
        width: 375
      });
    });
    $("#calendar_feed_box .calendar_feed_url").focus(function() {
      $(this).select();
    });
    $(".calendar_day_holder").focus(function(event) {
      $(".calendar_container .calendar_day.hover").removeClass('hover');
      $(".calendar_container .calendar_event.selected").removeClass('selected');
      $(this).find(".calendar_day").addClass('hover');
    });
    $(".calendar_event a").focus(function(event) {
      $(".calendar_container .calendar_day.hover").removeClass('hover');
      $(".calendar_container .calendar_event.selected").removeClass('selected');
      $(this).parents(".calendar_event").addClass('selected');
      $(this).parents(".calendar_day").addClass('hover');
    });

    $("#edit_event select.context_id").change(function(event, propagate) {
      var context = $(this).val();
      var $select = $("#" + context + "_assignment_groups").clone(true).attr('id', 'temp_' + context + '_assignment_groups');
      attachAddAssignmentGroup($select, $("#context_urls ." + context + "_add_assignment_group_url").attr('href'));
      $(this).parents("form").find(".assignment_group_select").empty().append($select);
      var $form = $(this).parents("form");
      var id = $form.data('event_id');
      var url = "";
      setFormURLs($form, context, id);
      if(propagate !== false) {
        $(this).parents("#edit_event").find("select.context_id").not($(this)).val($(this).val()).triggerHandler('change', false);
      }

      var $elementToAddBackgroundTo =$(this).closest("#edit_event");
      if ($elementToAddBackgroundTo.data('group_class')) {
        $elementToAddBackgroundTo.removeClass( $elementToAddBackgroundTo.data('group_class') )
      }
      $elementToAddBackgroundTo.addClass('group_' + context).data( "group_class", 'group_' + context );
        
    });
    $("#edit_assignment_form .datetime_field, #edit_calendar_event_form .datetime_field").datetime_field();
    $("#edit_calendar_event_form .time_field").time_field()
    .blur(function(event) {
      var start_time = $("#edit_calendar_event_form .time_field.start_time").next(".datetime_suggest").text()
      if($("#edit_calendar_event_form .time_field.start_time").next(".datetime_suggest").hasClass('invalid_datetime')) { start_time = null; } 
      start_time = start_time || $("#edit_calendar_event_form .time_field.start_time").val();
      var end_time = $("#edit_calendar_event_form .time_field.end_time").next(".datetime_suggest").text();
      if($("#edit_calendar_event_form .time_field.end_time").next(".datetime_suggest").hasClass('invalid_datetime')) { end_time = null; } 
      end_time = end_time || $("#edit_calendar_event_form .time_field.end_time").val();
      var startDate = Date.parse(start_time);
      var endDate = Date.parse(end_time);
      startDate = startDate || endDate;
      endDate = endDate || startDate;
      if($(this).hasClass('end_time')) {
        if(startDate > endDate) { startDate = endDate; }
      } else {
        if(endDate < startDate) { endDate = startDate; }
      }
      if(startDate) {
        $("#edit_calendar_event_form .time_field.start_time").val(startDate.toString('h:mmtt').toLowerCase());
      }
      if(endDate) {
        $("#edit_calendar_event_form .time_field.end_time").val(endDate.toString('h:mmtt').toLowerCase());
      }
    });
    $("#edit_calendar_event_form .date_field").date_field();
    $("#edit_event_form input[name='date']").datepicker();
    $(".calendar_month").delegate('.next_month_link', 'click', function(event) {
      event.preventDefault();
      var text = $(".calendar_month .month_name").text() + " " + $(".calendar_month .year_number").text();
      var date = Date.parse(text) || new Date();
      date.setMonth(date.getMonth() + 1);
      var data = {};
      try {
        data = $.parseJSON($.decodeFromHex(location.hash.substring(1))) || {};
      } catch(e) { data = {}; }
      data.month = date.getMonth() + 1;
      data.year = date.getFullYear();
      location.replace("#" + $.encodeToHex(JSON.stringify(data)));
    }).delegate('.prev_month_link', 'click', function(event) {
      event.preventDefault();
      var text = $(".calendar_month .month_name").text() + " " + $(".calendar_month .year_number").text();
      var date = Date.parse(text) || new Date();
      date.setMonth(date.getMonth() - 1);
      var data = {};
      try {
        data = $.parseJSON($.decodeFromHex(location.hash.substring(1))) || {};
      } catch(e) { data = {}; }
      data.month = date.getMonth() + 1;
      data.year = date.getFullYear();
      location.replace("#" + $.encodeToHex(JSON.stringify(data)));
    });
    var max_visible_calendars = parseInt($("#max_calendar_count").text(), 10) || 10;
    var logCheckedContexts = function() {
      logCheckedContexts.log = true;
    };
    setInterval(function() {
      if(logCheckedContexts.log) {
        logCheckedContexts.log = false;
        var only_contexts = [];
        $(".calendar_links .group_reference_checkbox:checked").each(function() {
          var code = $(this).attr('id').substring(6);
          only_contexts.push(code);
        });
        userSettings.set('checked_calendar_codes', only_contexts);
      }
    }, 1000);
    $(".group_reference_checkbox").bind('change click', function() {
      var item = this;
      setTimeout(function() {
        $("." + $(item).attr('id') + ":not(.group_reference)").showIf($(item).attr('checked'));
        if($(".calendar_links .group_reference_checkbox:checked").length > max_visible_calendars) {
          $(".calendar_links .group_reference_checkbox:checked").not(item).filter(":first").attr('checked', false).change();
        }
        if($(item).attr('checked')) {
          refreshCalendarData(true);
        } 
        logCheckedContexts();
        $(".calendars_open_count").text($(".calendar_links .group_reference_checkbox:checked").length);
      }, 10);
    }).filter(":last").change();
    $(".calendar_container").delegate('.calendar_day', 'mouseover', function(event) {
      var $container = $(event.liveFired || $(this).parents(".calendar_container"));
      if($container.data('prevent_hover')) { return; }
      $(".calendar_day.hover").removeClass('hover');
      $(this).addClass('hover');
      var date = $(this).find(".day_number").attr('title');
      if(date && !$(document).data('dragging')) {
        var $mini = $(".mini_calendar .day.date_" + date.replace(/\//g, "_"));
        $mini.addClass('related');
      }
    }).delegate('.calendar_day', 'mouseout', function(event) {
      var $container = $(event.liveFired || $(this).parents(".calendar_container"));
      if($container.data('prevent_hover')) { return; }
      $(this).removeClass('hover');
      var date = $(this).find(".day_number").attr('title');
      if(date) {
        var $mini = $(".mini_calendar .day.date_" + date.replace(/\//g, "_"));
        $mini.removeClass('related');
      }
    });
    $(".mini_month").delegate('.next_month_link', 'mousedown', function(event) {
      event.preventDefault();
      changeCalendarMonth($(event.liveFired || $(this).parents(".mini_month")), 1);
    }).delegate('.prev_month_link', 'mousedown', function(event) {
      event.preventDefault();
      changeCalendarMonth($(event.liveFired || $(this).parents(".mini_month")), -1);
    }).delegate('.next_month_link,.prev_month_link', 'click', function(event) {
      event.preventDefault();
    }).delegate('.day_number', 'click', function(event) {
      event.preventDefault();
      var date_string = $(this).attr('title');
      changeCalendarMonth($(event.liveFired || $(this).parents(".mini_month")), date_string);
      changeCalendarMonth($(".calendar_container .calendar_month"), date_string);
    });
    $(document).click(function(event) {
      var $day = $(this);
      $(".calendar_container .calendar_event.selected").each(function(event) {
        if($(this).parent()[0] != $day[0]) {
          $(this).removeClass('selected');
        }
      });
      $(".calendar_container .calendar_day_holder.selected").each(function(event) {
        if($(this)[0] != $day.parent()[0]) {
          $(this).removeClass('selected');
        }
      });
    });
    $(".calendar_event").live('click', function(event) {
      event.preventDefault();
      event.stopPropagation();
      $(".calendar_day_holder.selected,.calendar_event.selected").removeClass('selected');
      showEvent($(this), $(this).parents(".calendar_day"));
    });
    $(".calendar_container").delegate('.calendar_day', 'click', function(event) {
      if($(event.target).closest(".calendar_event").length > 0) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      if(ENV.canCreateEvent) {
        editEvent($("#event_blank"), $(this));
        var context_code = ($(".group_reference_checkbox:checked:first").attr('id') || "").replace(/^group_/, '');
        if(!context_code) {
          context_code = ($(".group_reference.default_context").find('.group_reference_checkbox').attr('id') || "").replace(/^group_/, '');
        }
        if(context_code) {
          $("#edit_event .context_select select.context_id").each(function() {
            $(this).val(context_code)
            if(this.selectedIndex < 0) { this.selectedIndex = 0; }
            $(this).triggerHandler('change', false);
          });
        }
      }
    });
    $(document).delegate('.add_event_link', 'click', function(event) {
      // this is an ugly way to remember which "add event" link was clicked.
      // because of some weird scope issue, over in editEvent -> dialog -> open() $day would be a cached 
      // value of the first "add event" link they clicked on so we cant use it, to figure out which context
      // to select in the dropdown of contexts on the create event dialog.
      window.thisElementFiredTheEvent = this;
      event.preventDefault();
      editEvent($("#event_blank"), $(this));
      var context_code = ($(this).closest('.group_reference').find('.group_reference_checkbox').attr('id') || "").replace('group_', '');
      $("#edit_event .context_select select.context_id").val(context_code).triggerHandler('change', false);
      window.thisElementFiredTheEvent = undefined;
    });
    $(document).keycodes(
            [I18n.t('keycodes.next_day', 'ctrl+right'),
             I18n.t('keycodes.previous_day', 'ctrl+left'),
             I18n.t('keycodes.next_week', 'ctrl+down'),
             I18n.t('keycodes.previous_week', 'ctrl+up')].join(' '),
            function(event) {
      event.preventDefault();
      event.stopPropagation();
      var direction;
      switch(event.keyString) {
        case I18n.t('keycodes.next_day', 'ctrl+right'):
          direction = 'right';
          break;
        case I18n.t('keycodes.previous_day', 'ctrl+left'):
          direction = 'left';
          break;
        case I18n.t('keycodes.next_week', 'ctrl+down'):
          direction = 'down';
          break;
        case I18n.t('keycodes.previous_week', 'ctrl+up'):
          direction = 'up';
          break;
      }
      calendarMove(direction);
    });
    $(document).keycodes(
            [I18n.t('keycodes.next_event', 'j'),
             I18n.t('keycodes.previous_event', 'k'),
             I18n.t('keycodes.open', 'o'),
             I18n.t('keycodes.edit', 'e'),
             I18n.t('keycodes.delete', 'd'),
             I18n.t('keycodes.new', 'n'),
             I18n.t('keycodes.refresh', 'r')].join(' '),
            function(event) {
      event.preventDefault();
      event.stopPropagation();
      var $selectedEvent = $(".calendar_event.selected:first");
      var $selectedDay = $(".calendar_day_holder.selected:first");
      if(event.keyString == I18n.t('keycodes.next_event', 'j')) {
        calendarEventMove('down');
      } else if(event.keyString == I18n.t('keycodes.previous_event', 'k')) {
        calendarEventMove('up');
      } else if(event.keyString == I18n.t('keycodes.open', 'o')) {
        $selectedEvent.click();
      } else if(event.keyString == I18n.t('keycodes.delete', 'd')) {
        if($selectedEvent.length > 0 && $selectedEvent.find(".can_delete").text() == "true") {
          deleteEvent($selectedEvent);
        }
      } else if(event.keyString == I18n.t('keycodes.edit', 'e')) {
        if($selectedEvent.length > 0 && $selectedEvent.find(".can_edit").text() == "true") {
          editEvent($selectedEvent, $selectedDay.children(".calendar_day"));
        }
      } else if(event.keyString == I18n.t('keycodes.new', 'n')) {
        editEvent($("#event_blank"), $selectedDay.children(".calendar_day"));
      } else if(event.keyString == I18n.t('keycodes.refresh', 'r')) {
        refreshCalendarData();
      }
    });
    $("#edit_calendar_event_form").formSubmit({
      object_name: 'calendar_event',
      required: ['title'],
      processData: function(data) {
        if(data.start_time) {
          if(!data.end_time) {
            data.end_time = data.start_time;
          }
        }
        var start_date = Date.parse(data.date + " " + data.start_time);
        data.start_at = "";
        data.end_at = "";
        if(start_date) {
          data.time_sortable = start_date.toString('HH:mm');
          data.event_date_string = start_date.toString('yyyy_MM_dd');
          data.start_at = $.datetime.process(start_date);
          data.start_time = start_date.toString('hh:mmtt').toLowerCase();
        } else {
          data.time_sortable = "0";
          data.event_date_string = null;
        }
        if(data.start_time && !data.end_time) {
          data.end_time = data.start_time;
        }
        var end_date = Date.parse(data.date + " " + data.end_time);
        if(end_date) {
          data.end_at = $.datetime.process(end_date);
          data.end_time = end_date.toString('hh:mmtt').toLowerCase();
        }
        data['calendar_event[start_at]'] = data.start_at;
        data['calendar_event[end_at]'] = data.end_at;
        return data;
      },
      beforeSubmit: function(data) {
        var $event = $(this).data('current_event');
        if(!$event) { return false; }
        if($event.attr('id') == 'event_blank') {
          $event = $event.clone(true).attr('id', 'event_new');
          $event.draggable(eventDraggable);
        }
        data = $.extend(data, $(this).getFormData({object_name: 'calendar_event'}));
        data.start_time_string = data.start_time;
        data.end_time_string = data.end_time;
        data.event_type = "calendar_event";
        $event.fillTemplateData({
          data: data
        })
        var context = $(this).find("select.context_id").val();;
        $event.addClass('group_' + context);
        $("#group_" + context).attr('checked', true).change();
        $event.find(".calendar_event_text").attr('title', data.title);
        $event.addClass('event_pending');
        var $day = $(".calendar_undated");
        if(data.event_date_string) {
          $day = $("#day_" + data.event_date_string);
        }
        addEventToDay($event, $day);
        $("#edit_event").dialog('close');
        return $event;
      },
      success: function(data, $event) {
        $event.removeClass('event_pending');
        $(document).triggerHandler('add_event', $event);
        updateEvent(data, $event);
        updateEventInCache(data);
      }
    });
    $("#edit_calendar_event_form input[name='date'],#edit_assignment_form input[name='date']").change(function() {
      $(".calendar_day.hover").removeClass('hover');
      $(".calendar_day_holder.selected").removeClass('selected');
      var vals = $(this).val().split("/");
      var val = null;
      if(vals.length == 3) {
        val = vals[2] + "_" + vals[0] + "_" + vals[1];
      }
      if(val) {
        selectDateForEvent($("#day_" + val));
      }
    });
    $("#edit_assignment_form").formSubmit({
      object_name: 'assignment',
      required: ['title'],
      processData: function(data) {
        var start_date = Date.parse(data.due_at);
        data.time_sortable = "0";
        data.event_date_string = "";
        data.start_time = "";
        if(start_date) {
          data['assignment[due_at]'] = $.datetime.process(start_date);
          data.time_sortable = start_date.toString('HH:mm');
          data.event_date_string = start_date.toString('yyyy_MM_dd');
          data.start_time = start_date.toString('hh:mmtt').toLowerCase();
        }
        data.start_time_string = data.start_time;
        data.end_time_string = data.start_time;
        data.event_type = "assignment";
        return data;
      },
      beforeSubmit: function(data) {
        var $event = $(this).data('current_event');
        if(!$event) { 
          return false; 
        }
        // setting the new event to be draggable
        if($event.attr('id') == 'event_blank') {
          $event = $event.clone(true).attr('id', 'event_new');
          $event.draggable(eventDraggable);
        }
        // populating the event template
        var context = $(this).find("select.context_id").val();
        $event.addClass('group_' + context);
        $("#group_" + context).attr('checked', true).change();
        $event.find(".calendar_event_text").attr('title', data.title);
        $event.fillTemplateData({
          data: data
        })
        $event.find(".calendar_event_text").attr('title', data.title);
        $event.addClass('event_pending');
        addEventToDay($event, $("#day_" + data.event_date_string));
        $("#edit_event").dialog('close');
        return $event;
      },
      success: function(data, $event) {
        $event.removeClass('event_pending');
        $(document).triggerHandler('add_event', $event);
        updateEvent(data, $event);
        updateEventInCache(data);
      }
    });
    $(".refresh_calendar_link").click(function(event) {
      event.preventDefault();
      var $month = $(this).parents(".calendar_month");
      if($month.length > 0) {
        refreshMonthData($month);    
      } else {
        refreshCalendarData();
      }
    });
    $("#event_details").delegate('.edit_event_link', 'click', function(event) {
      event.preventDefault();
      var $box = $("#event_details");
      var $event = $box.data('current_event');
      var $day = $box.data('current_day');
      if($event && $day) {
        editEvent($event, $day);
      }
    }).delegate('.delete_event_link', 'click', function(event) {
      event.preventDefault();
      var $box = $("#event_details");
      var $event = $box.data('current_event');
      deleteEvent($event);
    });
    $(document).fragmentChange(function(event, hash) {
      if(hash.indexOf("#calendar_event_") == 0 || hash.indexOf("#assignment_") == 0) {
        var id = "event_" + hash.substring(1);
        var $event = $("#" + id);
        if($event.length > 0) {
          $event.addClass('selected');
          $("html,body").scrollTo($event.parents(".calendar_day"));
          $event.click();
        }
      }
    });
    $("#edit_event_tabs")
      .tabs()
      .bind('tabsselect', function(event, ui) {
        $(document).triggerHandler('event_tab_select', ui.index);
        $(ui.panel).find("select.context_id").triggerHandler('change');
      });
    var storedCodes = userSettings.get('checked_calendar_codes');
    if (storedCodes) {
      var found = 0;
      for (var idx in storedCodes) {
        var $item = $("#group_" + storedCodes[idx]);
        $item.attr('checked', true);
        if($item.length > 0) { found++; }
      }
      if (found == 0) {
        $(".group_reference .group_reference_checkbox:lt(10)").each(function() {
          $(this).attr('checked', true);
        });
      }
    } else {
      $(".group_reference .group_reference_checkbox:lt(10)").each(function() {
        $(this).attr('checked', true);
      });
    }
    setTimeout(refreshCalendarData, 3000);
    setInterval(refreshCalendarData, 600000);
    setTimeout(secondaryInit, 1000);
  })
  function secondaryInit() {
    $(".calendar_month").each(function() {
      $(this).data("days", $(this).find(".calendar_day_holder"));
    });
  }
  function deleteEvent($event) {
    var $box = $("#event_details");
    var data = $.extend({}, $event.data('event_data'));
    var context = data.context_type.toLowerCase() + "_" + data.context_id;
    var message = I18n.t('prompts.delete_event', "Are you sure you want to delete this event?");
    if(data.event_type == 'assignment') {
      message = I18n.t('prompts.delete_assignment', "Are you sure you want to delete this assignment?");
    }
    var url = $("." + context + "_event_url").attr('href');
    if(data.event_type == "assignment") {
      url = $("." + context + "_assignment_url").attr('href');
    }
    url = $.replaceTags(url, 'id', data.id);
    $event.confirmDelete({
      url: url,
      message: message,
      confirmed: function() {
        $box.dialog('close');
        $(this).dim();
      },
      success: function() {
        $(document).triggerHandler('delete_event');
        $(this).fadeOut(function() {
          $(this).remove();
          deleteEventInCache($event);
        });
      }
    });
  }
  $(function(){
    // this will show the .add_event_link when they mouse over a context that is checked, and hide it when you mouse out.
    $("#right-side").delegate('.group_reference', 'mouseenter mouseleave', function(event){
      $(this).find('.add_event_link').showIf(event.type === 'mouseenter' && $(this).find(".group_reference_checkbox").attr('checked'));
    });  
  });
  // the following chunk of code will handle if they pass urls like "/calendar#show=group_user_23,group_course_5" 
  // to show only events from those contexts.  and it will also listen to to the change event on those checkboxes
  // to update the hash when something gets changed.
  $(function(){
    $(document).fragmentChange(function(){
      var data = null;
      try {
        data = $.parseJSON($.decodeFromHex(document.location.hash.substring(1)));
      } catch(e) { }
      if(data && data.month && parseInt(data.month, 10) && data.year && parseInt(data.year, 10)) {
        var text = $(".calendar_month .month_name").text() + " " + $(".calendar_month .year_number").text();
        var currentDate = Date.parse(text) || new Date();
        var date = Date.parse(data.month + " " + data.year) || new Date();
        if(date.getMonth() == currentDate.getMonth() && date.getFullYear() == currentDate.getFullYear()) {
        } else {
          var date_string = $.datepicker.formatDate('mm/dd/yy', date);
          changeCalendarMonth($(".calendar_month"), date_string);
          changeCalendarMonth($(".calendar_container").find(".mini_month"), date_string);
        }
      }
      if(data && data.show) {
        var ids = data.show.split(','),
            forceChecked = !ids && !ids.length,
            checkedOne = false,
            elementsToFireChangeForWhenImDone = [];
        $(".group_reference_checkbox").each(function(){
          var whatItWasBefore = this.checked;
          checkedOne = ( this.checked = ($.inArray($(this).attr('id'), ids) > -1) || forceChecked ) || checkedOne
          if (this.checked != whatItWasBefore ) {
            elementsToFireChangeForWhenImDone.push(this);
          }
        });
        // if none of the checkboxes got checked, but they didnt specifically say #show=nothing then the hash got 
        // screwed up so show everything.
        if (!checkedOne && ids != 'nothing') {
          $(".group_reference_checkbox").each(function(){
            var whatItWasBefore = this.checked;
            this.checked = true;
            if (this.checked != whatItWasBefore ) {
              elementsToFireChangeForWhenImDone.push(this);
            }
          });
        }
        $.each(elementsToFireChangeForWhenImDone, function(){
          $(this).triggerHandler('change', 'dontUpdateFragment');
        });
      }
    });
    
    $(".group_reference_checkbox").bind('change click', function(event, data){
      setTimeout(function() {
        if (data === 'dontUpdateFragment') { return true; }
        var data = null;
        try {
          data = $.parseJSON($.decodeFromHex(document.location.hash.substring(1)));
        } catch(e) { }
        
        var ids = []
        $(".group_reference_checkbox:checked").each(function(){
          ids.push( $(this).attr('id') )  
        });
        var hash_data = {}
        hash_data.show = ids.join(',') || 'nothing';
        var month = $(".calendar_month:first .month_number").text();
        var year = $(".calendar_month:first .year_number").text();
        hash_data.month = (data && data.month) || month;
        hash_data.year = (data && data.year) || year;
        location.replace("#" + $.encodeToHex(JSON.stringify(hash_data)));
      }, 10);
    });
  });
});
