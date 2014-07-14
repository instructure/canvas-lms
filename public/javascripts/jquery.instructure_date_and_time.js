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
  'timezone',
  'str/htmlEscape',
  'jquery.keycodes' /* keycodes */,
  'vendor/date' /* Date.parse, Date.UTC, Date.today */,
  'jqueryui/datepicker' /* /\.datepicker/ */,
  'jqueryui/sortable' /* /\.sortable/ */,
  'jqueryui/widget' /* /\.widget/ */
], function(I18n, $, tz, htmlEscape) {
  // Create a function to pass to setTimeout
var speakMessage = function ($this, message) {
  if ($this.data('accessible-message-timeout')) {
    // Clear any previously scheduled message from this field.
    clearTimeout($this.data('accessible-message-timeout'));
    $this.removeData('accessible-message-timeout');
  }
  if (!message) {
    // No message? Do nothing when the timeout expires.
    return function () {};
  }
  return function () {
    $('#aria_alerts').text(message);
    $this.removeData('accessible-message-timeout');
  };
};

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

  // fudgeDateForProfileTimezone is used to apply an offset to the date which represents the
  // difference between the user's configured timezone in their profile, and the timezone
  // of the browser. We want to display times in the timezone of their profile. Use
  // unfudgeDateForProfileTimezone to remove the correction before sending dates back to the server.
  $.fudgeDateForProfileTimezone = function(date) {
    date = tz.parse(date);
    if (!date) return null;
    // format true date into profile timezone without tz-info, then parse in
    // browser timezone. then, as desired:
    // output.toString('yyyy-MM-dd hh:mm:ss') == tz.format(input, '%Y-%m-%d %H:%M:%S')
    return Date.parse(tz.format(date, '%F %T'));
  }

  $.unfudgeDateForProfileTimezone = function(date) {
    date = tz.parse(date);
    if (!date) return null;
    // format fudged date into browser timezone without tz-info, then parse in
    // profile timezone. then, as desired:
    // tz.format(output, '%Y-%m-%d %H:%M:%S') == input.toString('yyyy-MM-dd hh:mm:ss')
    return tz.parse(date.toString('yyyy-MM-dd HH:mm:ss'));
  }

  // this batch of methods assumes *real* dates passed in (or, really, anything
  // tz.parse() can recognize. so timestamps are cool, too. but not fudged dates).
  // use accordingly
  $.sameYear = function(d1, d2) {
    return tz.format(d1, '%Y') == tz.format(d2, '%Y');
  };
  $.sameDate = function(d1, d2) {
    return tz.format(d1, '%F') == tz.format(d2, '%F');
  };
  $.midnight = function(date) {
    return date != null && tz.format(date, '%R') == '00:00';
  };
  $.dateString = function(date, otherZone) {
    if (date == null) return "";
    var format = $.sameYear(date, new Date()) ? '%b %-d' : '%b %-d, %Y';
    if(arguments.length > 1) return tz.format(date, format, otherZone) || '';
    return tz.format(date, format) || '';
  };
  $.timeString = function(date, otherZone) {
    if (date == null) return "";
    if(arguments.length > 1) return tz.format(date, '%l:%M%P', otherZone) || '';
    return tz.format(date, '%l:%M%P') || '';
  };
  $.datetimeString = function(datetime, options) {
    var localized = options && options.localized;
    var timezone = options && options.timezone;
    datetime = tz.parse(datetime);
    if (datetime == null) return "";
    if (localized == false) {
      // temporary unlocalized (which means avoiding tz.format)
      // expansion of the other branch. intent of being able to call
      // this with localized false, triggering this code, is if it's
      // called to fill the value attribute of a datetime picker field,
      // since the field will complain about localized dates. the real
      // solution is to teach the datetime picker about parsing
      // localized date strings (by using tz.parse).
      //
      // TODO: implement that real solution and remove this
      var fudged = $.fudgeDateForProfileTimezone(datetime);
      datePart = $.sameYear(datetime, new Date()) ? fudged.toString("MMM d") : fudged.toString("MMM d, yyyy");
      timePart = fudged.toString("h:mmtt").toLowerCase();
      return datePart + " at " + timePart;
    }
    else {
      var dateValue = null;
      var timeValue = null;
      if(typeof timezone == 'string' || timezone instanceof String){
        dateValue = $.dateString(datetime, timezone);
        timeValue = $.timeString(datetime, timezone);
      }else{
        dateValue = $.dateString(datetime);
        timeValue = $.timeString(datetime);
      }
      return I18n.t('#time.event', '%{date} at %{time}', { date: dateValue, time: timeValue });
    }
  };
  // end batch

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

  $.datetime = {};
  $.datetime.shortFormat = "MMM d, yyyy";
  $.datetime.defaultFormat = "MMM d, yyyy h:mmtt";
  $.datetime.sortableFormat = "yyyy-MM-ddTHH:mm:ss";
  $.datetime.parse = function(text, /* optional */ intermediate_format) {
    return Date.parse((text || "").toString(intermediate_format).replace(/ (at|by)/, ""))
  }
  $.datetime.clean = function(text) {
    var date = $.datetime.parse(text, $.datetime.sortableFormat) || text;
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
      date = $.datetime.parse(text);
    }
    var result = "";
    if(date) {
      result = date.toString($.datetime.sortableFormat);
    }
    return result;
  };

  $.datepicker.oldParseDate = $.datepicker.parseDate;
  $.datepicker.parseDate = function(format, value, settings) {
    return $.datetime.parse(value) || $.datepicker.oldParseDate(format, value, settings);
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

        var datepickerOptions = {
          timePicker: (!options.dateOnly),
          constrainInput: false,
          dateFormat: 'M d, yy',
          showOn: 'button',
          buttonText: '<i class="icon-calendar-month"></i>',
          buttonImageOnly: false
        };
        $field.datepicker($.extend(datepickerOptions, options.datepicker));
      }

      var $suggest = $('<div class="datetime_suggest" />').insertAfter($thingToPutSuggestAfter);
      if (ENV && ENV.CONTEXT_TIMEZONE && (ENV.TIMEZONE != ENV.CONTEXT_TIMEZONE)){
        var $suggest2 = $('<div class="datetime_suggest" />').insertAfter($suggest);
      }

      if (options.addHiddenInput) {
        var $hiddenInput = $('<input type="hidden">').insertAfter($field);
        $hiddenInput.attr('name', $field.attr('name'));
        $hiddenInput.val($field.val());
        $field.removeAttr('name');
        $field.data('hiddenInput', $hiddenInput);
      }

      $field.bind("change focus blur keyup", function() {
        var $this = $(this),
            val = $this.val();
        if (options.timeOnly && val && parseInt(val, 10) == val) {
          val += (val < 8) ? "pm" : "am";
        }
        var fudged_d = $.datetime.parse(val);
        var d = $.unfudgeDateForProfileTimezone(fudged_d);
        var parse_error_message = I18n.t('errors.not_a_date', "That's not a date!");
        var text = parse_error_message;
        var text2 = ""
        if (!$this.val()) { text = ""; }
        if (fudged_d) {
          $this.data('date', fudged_d);
          if ($this.data('hiddenInput')) {
            $this.data('hiddenInput').val(fudged_d);
          }
          if(!options.timeOnly && !options.dateOnly && (!$.midnight(d) || options.alwaysShowTime)) {
            text = fudged_d.toString('ddd MMM d, yyyy h:mmtt');
            if($suggest2)
              text2 = tz.format(d,"%a %b %m, %Y %l:%M%p", ENV.CONTEXT_TIMEZONE);
            $this
              .data('time-hour', fudged_d.toString('h'))
              .data('time-minute', fudged_d.toString('mm'))
              .data('time-ampm', fudged_d.toString('tt').toLowerCase());
          } else if(!options.timeOnly) {
            text = fudged_d.toString('ddd MMM d, yyyy');
          } else {
            text = fudged_d.toString('h:mmtt').toLowerCase();
            if($suggest2)
              text2 = tz.format(d,"%l:%M%p", ENV.CONTEXT_TIMEZONE);
          }

          if($suggest2) {
            if(text2.length > 0){
              $suggest2.text(I18n.t('course_time',"COURSE: ")+text2);
            } else {
              $suggest2.text("");
            }
          }
        }

        if(text.length > 0 && $suggest2)
          text = I18n.t('local_time',"LOCAL: ") + text;

        $suggest
          .toggleClass('invalid_datetime', text == parse_error_message)
          .text(text);

        if (text == parse_error_message ) {
          $this.data(
            'accessible-message-timeout',
            setTimeout(speakMessage($this, text), 2000)
          );
        } else if ($this.data('accessible-message-timeout')) {
          // Error resolved, cancel the alert.
          clearTimeout($this.data('accessible-message-timeout'));
          $this.removeData('accessible-message-timeout');
        }
      }).triggerHandler('change');
      // TEMPORARY FIX: Hide from aria screenreader until the jQuery UI datepicker is updated for accessibility.
      $field.next().attr('aria-hidden', 'true');
      $field.next().attr('tabindex', '-1');
    });
    return this;
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
