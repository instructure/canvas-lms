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
  'i18n!instructure',
  'jquery' /* jQuery, $ */,
  'str/htmlEscape',
  'jquery.keycodes' /* keycodes */,
  'vendor/date' /* Date.parse, Date.UTC, Date.today */,
  'jqueryui/datepicker' /* /\.datepicker/ */,
  'jqueryui/sortable' /* /\.sortable/ */,
  'jqueryui/widget' /* /\.widget/ */
], function(I18n, $, htmlEscape) {

  $.parseDateTime = function(date, time) {
    var date = $.datepicker.parseDate('mm/dd/yy', date);
    if(time) {
      var times = time.split(":");
      var hr = parseInt(times[0], 10);
      if(hr == 12) { hr = 0; }
      if(time.match(/pm/i)) {
        hr += 12;
      }
      var min = 0;
      if(times[1]) {
        min = times[1].replace(/(am|pm)/gi, "");
      }
      date.setHours(hr);
      date.setMinutes(min);
    } else {
      date.setHours(0);
      date.setMinutes(0);
    }
    date.date = date;
    return date;
  };
  
  $.formatDateTime = function(date, options) {
    var head = "", tail = "";
    if(date) {
      date.date = date.date || date;
    }
    if(options.object_name) {
      head += options.object_name + "[";
      tail = "]" + tail;
    }
    if(options.property_name) {
      head += options.property_name;
    }
    var result = {};
    if(date && !isNaN(date.date.getFullYear())) {
      result[head + "(1i)" + tail] = date.getFullYear();
      result[head + "(2i)" + tail] = (date.getMonth() + 1);
      result[head + "(3i)" + tail] = date.getDate();
      result[head + "(4i)" + tail] = date.getHours();
      result[head + "(5i)" + tail] = date.getMinutes();
    } else {
      result[head + "(1i)" + tail] = "";
      result[head + "(2i)" + tail] = "";
      result[head + "(3i)" + tail] = "";
      result[head + "(4i)" + tail] = "";
      result[head + "(5i)" + tail] = "";
    }
    return result;
  };  
  
  $.parseFromISO = function(iso, datetime_type) {
    var user_offset = parseInt($("#time_zone_offset").text(), 10) / -60;
    var today = new Date();
    datetime_type = datetime_type || 'event';
    try {
      var result = {};
      if(!iso) {
        return $.parseFromISO.defaults;
      }
      var year = iso.substring(0, 4);
      var month = iso.substring(5, 7);
      var day = iso.substring(8, 10);
      var date_offset = parseInt(iso.substring(19), 10) || 0;
      result.date = new Date(year, month - 1, day);
      if(result.date.getTimezoneOffset() != today.getTimezoneOffset()) {
        user_offset = user_offset - ((result.date.getTimezoneOffset() - today.getTimezoneOffset()) / 60);
      }
      var hour_shift = user_offset - date_offset;
      // NOTE: This value is a literal parsing of the date
      // passed in and may technically be incorrect if there
      // is shifting due to time zones.
      // result.date = $.datepicker.parseDate("yy-mm-dd", iso.substring(0, 10));
      result.date_sortable = iso.substring(0, 10);
      result.date_string = month + "/" + day + "/" + year;
      result.date_formatted = $.dateString(result.date);
      var hour_string = iso.substring(11, 13);
      var minute_string = iso.substring(14, 16);
      var second_string = iso.substring(17, 19);
      var hours = (parseInt(hour_string, 10)) * 1000.0 * 3600;
      if(hour_shift && !isNaN(hour_shift)) {
        hours = hours + (hour_shift * 1000.0 * 3600);
      }
      var minutes = parseInt(minute_string, 10) * 1000.0 * 60;
      var seconds = parseInt(second_string, 10) * 1000.0;
      var time_timestamp = (hours + minutes + seconds) || 0;
      var date_timestamp = (Date.UTC(year, month - 1, day)) || 0;
      result.time_timestamp = time_timestamp / 1000;
      result.date_timestamp = date_timestamp / 1000;
      var tz_offset = result.date.getTimezoneOffset() * 60000;
      var time = new Date(date_timestamp + time_timestamp + tz_offset);
      var ampm = "am";
      hours = time.getHours();
      if(hours > 12) {
        hours -= 12;
        ampm = "pm";
      } else if(hours == 12) {
        ampm = "pm";
      } else if(hours === 0) {
        hours = 12;
      }
      var time_formatted = hours;
      var time_tail = ":";
      if(time.getMinutes() < 10) {
        time_tail += "0";
      }
      time_tail += time.getMinutes();
      if(time.getMinutes() !== 0) {
        time_formatted += time_tail;
      }
      var by_at = datetime_type == 'due_date' ? 'by' : 'at';
      var time_for_date_formatted = ' ' + by_at + ' ' + time_formatted + ampm;
      result.show_time = true;
      var sortable_hour = time.getHours();
      if(sortable_hour < 10) {
        sortable_hour = "0" + sortable_hour;
      }
      result.time_sortable = sortable_hour + time_tail;
      time_formatted += ampm;
      result.time_formatted = time_formatted;
      result.time_string = hours + time_tail + ampm;
      result.time = time;
      result.datetime = time;
      result.date_formatted = $.dateString(result.datetime);
      result.datetime_formatted = result.date_formatted + time_for_date_formatted;
      result.timestamp = (time_timestamp + date_timestamp) / 1000;
      result.minute_timestamp = result.timestamp - (result.timestamp % 60);
      return result;
    } catch(e) {
      return $.parseFromISO.defaults;
    }
  };

  // getUserOffset is used to query the user's timezone offset setting, which is usually
  // communicated from the server through the #time_zone_offset element
  $.getUserOffset = function() {
    return user_offset = parseInt($("#time_zone_offset").text(), 10) * -1; // in minutes
  }

  // fudgeDateForProfileTimezone is used to apply an offset to the date which represents the
  // difference between the user's configured timezone in their profile, and the timezone
  // of the browser. We want to display times in the timezone of their profile. Use
  // unfudgeDateForProfileTimezone to remove the correction before sending dates back to the server.
  $.fudgeDateForProfileTimezone = function(date, unfudge) {
    var today, user_offset, minutes_shift, time, newDate;

    if (!date) return null;
    today = new Date();
    user_offset = $.getUserOffset();
    if (date.getTimezoneOffset() != today.getTimezoneOffset()) {
      user_offset = user_offset - (date.getTimezoneOffset() - today.getTimezoneOffset());
    }
    minutes_shift = user_offset + date.getTimezoneOffset();

    if (minutes_shift == 0) {
      return date;
    }

    time = date.getTime(); // in ms
    time += minutes_shift * 60 * 1000 * (unfudge === true ? -1 : 1);
    newDate = new Date();
    newDate.setTime(time);
    return newDate;
  }

  $.unfudgeDateForProfileTimezone = function(date) {
    return $.fudgeDateForProfileTimezone(date, true);
  }

  // The following method is simply a helper to use the logic from $.parseFromISO on
  // an existing Date() object. This is not the right solution and should be replaced.
  $.parseFromDateUTC = function(date, datetime_type) {
    return $.parseFromISO($.dateToISO8601UTC(date), datetime_type)
  };
  $.parseFromISO.ref_date = new Date();
  $.parseFromISO.offset = $.parseFromISO.ref_date.getTimezoneOffset() * 60000;
  $.parseFromISO.defaults = {
      date: new Date($.parseFromISO.offset),
      date_sortable: "0000-00-00",
      date_string: "",
      date_formatted: "",
      time_timestamp: 0,
      date_timestamp: 0,
      timestamp: 0,
      time: new Date($.parseFromISO.offset),
      time_formatted: "",
      time_string: ""
  };
  $.dateToISO8601UTC = function(date) {
    var padZero = function(n) { return n < 10 ? '0' + n : n; }
    return date.getUTCFullYear() + '-' +
      padZero(date.getUTCMonth() + 1) + '-' +
      padZero(date.getUTCDate()) + 'T' +
      padZero(date.getUTCHours()) + ':' +
      padZero(date.getUTCMinutes()) + ':' +
      padZero(date.getUTCSeconds()) + 'Z'
  }
  $.dateToISO8601 = function(date) {
    var padZero = function(n) { n < 10 ? '0' + n : n }
    return date.getFullYear() + '-' +
      padZero(date.getMonth() + 1) + '-' +
      padZero(date.getDate()) + 'T' +
      padZero(date.getHours()) + ':' +
      padZero(date.getMinutes()) + ':' +
      padZero(date.getSeconds()) + 'Z'
  }
  
  var today = new Date();
  $.thisYear = function(date) {
    return date && (date.getFullYear() == today.getFullYear());
  };
  $.dateString = function(date) {
    return (date && (date.toString($.thisYear(date) ? 'MMM d' : 'MMM d, yyyy'))) || "";
  };
  $.timeString = function(date) {
    return (date && date.toString('h:mmtt').toLowerCase()) || "";
  };
  $.friendlyDatetime = function(datetime, perspective) {
    var today = Date.today();
    if (Date.equals(datetime.clone().clearTime(), today)) {
      return I18n.l('#time.formats.tiny', datetime);
    } else {
      return $.friendlyDate(datetime, perspective);
    }
  };
  $.friendlyDate = function(datetime, perspective) {
    if (perspective == null) {
      perspective = 'past';
    }
    var today = Date.today();
    var date = datetime.clone().clearTime();
    if (Date.equals(date, today)) {
      return I18n.t('#date.days.today', 'Today');
    } else if (Date.equals(date, today.add(-1).days())) {
      return I18n.t('#date.days.yesterday', 'Yesterday');
    } else if (Date.equals(date, today.add(1).days())) {
      return I18n.t('#date.days.tomorrow', 'Tomorrow');
    } else if (perspective == 'past' && date < today && date >= today.add(-6).days()) {
      return I18n.l('#date.formats.weekday', date);
    } else if (perspective == 'future' && date < today.add(7).days() && date >= today) {
      return I18n.l('#date.formats.weekday', date);
    }
    return I18n.l('#date.formats.medium', date);
  };
  $.fn.parseFromISO = $.parseFromISO;
  
  
  $.datepicker.oldParseDate = $.datepicker.parseDate;
  $.datepicker.parseDate = function(format, value, settings) {
    return Date.parse((value || "").toString().replace(/ (at|by)/, "")) || $.datepicker.oldParseDate(format, value, settings);
  };
  $.datepicker._generateDatepickerHTML = $.datepicker._generateHTML;
  $.datepicker._generateHTML = function(inst) {
    var html = $.datepicker._generateDatepickerHTML(inst);
    if(inst.settings.timePicker) {
      var hr = inst.input.data('time-hour') || "";
      hr = hr.replace(/'/g, "");
      var min = inst.input.data('time-minute') || "";
      min = min.replace(/'/g, "");
      var ampm = inst.input.data('time-ampm') || "";
      var selectedAM = (ampm == "am") ? "selected" : "";
      var selectedPM = (ampm == "pm") ? "selected" : "";
      html += "<div class='ui-datepicker-time ui-corner-bottom'><label for='ui-datepicker-time-hour'>" + htmlEscape(I18n.beforeLabel('datepicker.time', "Time")) + "</label> <input id='ui-datepicker-time-hour' type='text' value='" + hr + "' title='hr' class='ui-datepicker-time-hour' style='width: 20px;'/>:<input type='text' value='" + min + "' title='min' class='ui-datepicker-time-minute' style='width: 20px;'/> <select class='ui-datepicker-time-ampm un-bootrstrapify' title='" + htmlEscape(I18n.t('datepicker.titles.am_pm', "am/pm")) + "'><option value=''>&nbsp;</option><option value='am' " + selectedAM + ">" + htmlEscape(I18n.t('#time.am', "am")) + "</option><option value='pm' " + selectedPM + ">" + htmlEscape(I18n.t('#time.pm', "pm")) + "</option></select>&nbsp;&nbsp;&nbsp;<button type='button' class='btn btn-mini ui-datepicker-ok'>" + htmlEscape(I18n.t('#buttons.done', "Done")) + "</button></div>";
    }
    return html;
  };
  $.fn.realDatepicker = $.fn.datepicker;
  var _originalSelectDay = $.datepicker._selectDay;
  $.datepicker._selectDay = function(id, month, year, td) {
    var target = $(id);
    if ($(td).hasClass(this._unselectableClass) || this._isDisabledDatepicker(target[0])) {
      return;
    }
    var inst = this._getInst(target[0]);
    if(inst.settings.timePicker && !$.datepicker.okClicked && !inst._keyEvent) {
      var origVal = inst.inline;
      inst.inline = true;
      $.data(target, 'datepicker', inst);
      _originalSelectDay.call(this, id, month, year, td);
      inst.inline = origVal;
      $.data(target, 'datepicker', inst);
    } else {
      _originalSelectDay.call(this, id, month, year, td);
    }
  };
  $.fn.datepicker = function(options) {
    options = $.extend({}, options);
    options.prevOnSelect = options.onSelect;
    options.onSelect = function(text, picker) {
      if(options.prevOnSelect) {
        options.prevOnSelect.call(this, text, picker);
      }
      var $div = picker.dpDiv;
      var hr = $div.find(".ui-datepicker-time-hour").val() || $(this).data('time-hour');
      var min = $div.find(".ui-datepicker-time-minute").val() || $(this).data('time-minute');
      var ampm = $div.find(".ui-datepicker-time-ampm").val() || $(this).data('time-ampm');
      if(hr) {
        min = min || "00";
        ampm = ampm || "pm";
        var time = hr + ":" + min + " " + ampm;
        text += " " + time;
      }
      picker.input.val(text).change();
    };
    if(!$.fn.datepicker.timepicker_initialized) {
      $(document).delegate('.ui-datepicker-ok', 'click', function(event) {
        var cur = $.datepicker._curInst;
        var inst = cur;
        var sel = $('td.' + $.datepicker._dayOverClass +
          ', td.' + $.datepicker._currentClass, inst.dpDiv);
        if (sel[0]) {
          $.datepicker.okClicked = true;
          $.datepicker._selectDay(cur.input[0], inst.selectedMonth, inst.selectedYear, sel[0]);
          $.datepicker.okClicked = false;
        } else {
          $.datepicker._hideDatepicker(null, $.datepicker._get(inst, 'duration'));
        }
      });
      $(document).delegate(".ui-datepicker-time-hour", 'change keypress focus blur', function(event) {
        var cur = $.datepicker._curInst;
        if(cur) {
          var val = $(this).val();
          cur.input.data('time-hour', val);
        }
      }).delegate(".ui-datepicker-time-minute", 'change keypress focus blur', function(event) {
        var cur = $.datepicker._curInst;
        if(cur) {
          var val = $(this).val();
          cur.input.data('time-minute', val);
        }
      }).delegate(".ui-datepicker-time-ampm", 'change keypress focus blur', function(event) {
        var cur = $.datepicker._curInst;
        if(cur) {
          var val = $(this).val();
          cur.input.data('time-ampm', val);
        }
      });
      $(document).delegate(".ui-datepicker-time-hour,.ui-datepicker-time-minute,.ui-datepicker-time-ampm", 'mousedown', function(event) {
        $(this).focus();
      });
      $(document).delegate(".ui-datepicker-time-hour,.ui-datepicker-time-minute,.ui-datepicker-time-ampm", 'change keypress focus blur', function(event) {
        if(event.keyCode && event.keyCode == 13) {
          var cur = $.datepicker._curInst;
          var inst = cur;
          var sel = $('td.' + $.datepicker._dayOverClass +
            ', td.' + $.datepicker._currentClass, inst.dpDiv);
          if (sel[0]) {
            $.datepicker.okClicked = true;
            $.datepicker._selectDay(cur.input[0], inst.selectedMonth, inst.selectedYear, sel[0]);
            $.datepicker.okClicked = false;
          } else {
            $.datepicker._hideDatepicker(null, $.datepicker._get(inst, 'duration'));
          }
        } else if(event.keyCode && event.keyCode == 27) {
          $.datepicker._hideDatepicker(null, '');
        }
      });
      $.fn.datepicker.timepicker_initialized = true;
    }
    this.realDatepicker(options);
    $(document).data('last_datepicker', this);
    return this;
  };
  $.fn.date_field = function(options) {
    options = $.extend({}, options);
    options.dateOnly = true;
    this.datetime_field(options);
    return this;
  };
  $.fn.time_field = function(options) {
    options = $.extend({}, options);
    options.timeOnly = true;
    this.datetime_field(options);
    return this;
  };

  // add bootstrap's .btn class to the button that opens a datepicker
  $.datepicker._triggerClass = $.datepicker._triggerClass + ' btn';

  $.fn.datetime_field = function(options) {
    options = $.extend({}, options);
    this.each(function() {
      var $field = $(this),
          $thingToPutSuggestAfter = $field;
      if ($field.hasClass('datetime_field_enabled')) return;

      $field.addClass('datetime_field_enabled');
      if (!options.timeOnly) {
        $field.wrap('<div class="input-append" />');
        $thingToPutSuggestAfter = $field.parent('.input-append');

        $field.datepicker({
          timePicker: (!options.dateOnly),
          constrainInput: false,
          dateFormat: 'M d, yy',
          showOn: 'button',
          buttonText: '<i class="icon-calendar-month"></i>',
          buttonImageOnly: false
        });
      }

      var $suggest = $('<div class="datetime_suggest" />').insertAfter($thingToPutSuggestAfter);

      $field.bind("change focus blur keyup", function() {
        var $this = $(this),
            val = $this.val();
        if (options.timeOnly && val && parseInt(val, 10) == val) {
          val += (val < 8) ? "pm" : "am";
        }
        var d = Date.parse((val || "").toString().replace(/ (at|by)/, ""));
        var parse_error_message = I18n.t('errors.not_a_date', "That's not a date!");
        var text = parse_error_message;
        if (!$this.val()) { text = ""; }
        if (d) {
          $this.data('date', d);
          if(!options.timeOnly && !options.dateOnly && (d.getHours() || d.getMinutes() || options.alwaysShowTime)) {
            text = d.toString('ddd MMM d, yyyy h:mmtt');
            $this
              .data('time-hour', d.toString('h'))
              .data('time-minute', d.toString('mm'))
              .data('time-ampm', d.toString('tt').toLowerCase());
          } else if(!options.timeOnly) {
            text = d.toString('ddd MMM d, yyyy');
          } else {
            text = d.toString('h:mmtt').toLowerCase();
          }
        }

        $suggest
          .toggleClass('invalid_datetime', text == parse_error_message)
          .text(text);

      }).triggerHandler('change');
      // TEMPORARY FIX: Hide from aria screenreader until the jQuery UI datepicker is updated for accessibility.
      $field.next().attr('aria-hidden', 'true');
      $field.next().attr('tabindex', '-1');
    });
    return this;
  };


  $.datetime = {};
  $.datetime.shortFormat = "MMM d, yyyy";
  $.datetime.defaultFormat = "MMM d, yyyy h:mmtt";
  $.datetime.sortableFormat = "yyyy-MM-ddTHH:mm:ss";
  $.datetime.clean = function(text) {
    var date = Date.parse((text || "").toString("yyyy-MM-ddTHH:mm:ss").replace(/ (at|by)/, "")) || text;
    var result = "";
    if(date) {
      if(date.getHours() || date.getMinutes()) {
        result = date.toString($.datetime.defaultFormat);
      } else {
        result = date.toString($.datetime.shortFormat);
      }
    }
    return result;
  };
  $.datetime.process = function(text) {
    var date = text;
    if(typeof(text) == "string") {
      date = Date.parse((text || "").toString().replace(/ (at|by)/, ""));
    }
    var result = "";
    if(date) {
      result = date.toString($.datetime.sortableFormat);
    }
    return result;
  };
    /* Based loosely on:
    jQuery ui.timepickr - 0.6.5
    http://code.google.com/p/jquery-utils/

    (c) Maxime Haineault <haineault@gmail.com>
    http://haineault.com

    MIT License (http://www.opensource.org/licenses/mit-license.php */
  $.fn.timepicker = function() {
    var $picker = $("#time_picker");
    if($picker.length === 0) {
      $picker = $._initializeTimepicker();
    }
    this.each(function() {
      $(this).focus(function() {
        var offset = $(this).offset();
        var height = $(this).outerHeight();
        var width = $(this).outerWidth();
        var $picker = $("#time_picker");
        $picker.css({
          left: -1000,
          height: 'auto',
          width: 'auto'
        }).show();
        var pickerOffset = $picker.offset();
        var pickerHeight = $picker.outerHeight();
        var pickerWidth = $picker.outerWidth();
        $picker.css({
          top: offset.top + height,
          left: offset.left
        }).end();
        $("#time_picker .time_slot").removeClass('ui-state-highlight').removeClass('ui-state-active');
        $picker.data('attached_to', $(this)[0]);
        var windowHeight = $(window).height();
        var windowWidth = $(window).width();
        var scrollTop = $.windowScrollTop();
        if((offset.top + height - scrollTop + pickerHeight) > windowHeight) {
          $picker.css({
            top: offset.top - pickerHeight
          });
        }
        if(offset.left + pickerWidth > windowWidth) {
          $picker.css({
            left: offset.left + width - pickerWidth
          });
        }
        $("#time_picker").hide().slideDown();
      }).blur(function() {
        if($("#time_picker").data('attached_to') == $(this)[0]) {
          $("#time_picker").data('attached_to', null);
          $("#time_picker").hide()
            .find(".time_slot.ui-state-highlight").removeClass('ui-state-highlight');
        }
      }).keycodes("esc return", function(event) {
        $(this).triggerHandler('blur');
      }).keycodes("ctrl+up ctrl+right ctrl+left ctrl+down", function(event) {
        if($("#time_picker").data('attached_to') != $(this)[0]) {
          return;
        }
        event.preventDefault();
        var $current = $("#time_picker .time_slot.ui-state-highlight:first");
        var time = $($("#time_picker").data('attached_to')).val();
        var hr = 12;
        var min = "00";
        var ampm = "pm";
        var idx;
        if(time && time.length >= 7) {
          hr = time.substring(0, 2);
          min = time.substring(3, 5);
          ampm = time.substring(5, 7);
        }
        if($current.length === 0) {
          idx = parseInt(time, 10) - 1;
          if(isNaN(idx)) { idx = 0; }
          $("#time_picker .time_slot").eq(idx).triggerHandler('mouseover');
          return;
        }
        if(event.keyString == "ctrl+up") {
          var $parent = $current.parent(".widget_group");
          idx = $parent.children(".time_slot").index($current);
          if($parent.hasClass('ampm_group')) {
            idx = min / 15;
          } else if($parent.hasClass('minute_group')) {
            idx = parseInt(hr, 10) - 1;
          }
          $parent.prev(".widget_group").find(".time_slot").eq(idx).triggerHandler('mouseover');
        } else if(event.keyString == "ctrl+right") {
          $current.next(".time_slot").triggerHandler('mouseover');
        } else if(event.keyString == "ctrl+left") {
          $current.prev(".time_slot").triggerHandler('mouseover');
        } else if(event.keyString == "ctrl+down") {
          $parent = $current.parent(".widget_group");
          idx = $parent.children(".time_slot").index($current);
          var $list = $parent.next(".widget_group").find(".time_slot");
          idx = Math.min(idx, $list.length - 1);
          if($parent.hasClass('hour_group')) {
            idx = min / 15;
          } else if($parent.hasClass('minute_group')) {
            idx = (ampm == "am") ? 0 : 1;
          }
          $list.eq(idx).triggerHandler('mouseover');
        }
      });
    });
    return this;
  };
  $._initializeTimepicker = function() {
    var $picker = $(document.createElement('div'));
    $picker.attr('id', 'time_picker').css({
      position: "absolute",
      display: "none"
    });
    var pickerHtml = "<div class='widget_group hour_group'>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>01</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>02</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>03</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>04</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>05</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>06</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>07</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>08</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>09</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>10</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>11</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>12</div>";
    pickerHtml += "<div class='clear'></div>";
    pickerHtml += "</div>";
    pickerHtml += "<div class='widget_group minute_group'>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>00</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>15</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>30</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>45</div>";
    pickerHtml += "<div class='clear'></div>";
    pickerHtml += "</div>";
    pickerHtml += "<div class='widget_group ampm_group'>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>" + htmlEscape(I18n.t('#time.am', "am")) + "</div>";
    pickerHtml += "<div class='ui-widget ui-state-default time_slot'>" + htmlEscape(I18n.t('#time.pm', "pm")) + "</div>";
    pickerHtml += "<div class='clear'></div>";
    pickerHtml += "</div>";
    $picker.html(pickerHtml);
    $("body").append($picker);
    $picker.find(".time_slot").mouseover(function() {
      $picker.find(".time_slot.ui-state-highlight").removeClass('ui-state-highlight');
      $(this).addClass('ui-state-highlight');
      var $field = $($picker.data('attached_to') || "none");
      var time = $field.val();
      var hr = 12;
      var min = "00";
      var ampm = "pm";
      if(time && time.length >= 7) {
        hr = time.substring(0, 2);
        min = time.substring(3, 5);
        ampm = time.substring(5, 7);
      }
      var val = $(this).text();
      if(val > 0 && val <= 12) {
        hr = val;
      } else if(val == "am" || val == "pm") {
        ampm = val;
      } else {
        min = val;
      }
      $field.val(hr + ":" + min + ampm);
    }).mouseout(function() {
      $(this).removeClass('ui-state-highlight');
    }).mousedown(function(event) {
      event.preventDefault();
      $(this).triggerHandler('mouseover');
      $(this).removeClass('ui-state-highlight').addClass('ui-state-active');
    }).mouseup(function() {
      $(this).removeClass('ui-state-active');
    }).click(function(event) {
      event.preventDefault();
      $(this).triggerHandler('mouseover');
      if($picker.data('attached_to')) {
        $($picker.data('attached_to')).focus();
      }
      $picker.stop().hide().data('attached_to', null);
    });
    return $picker;
  };
  
});
