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
  'jquery',
  'timezone',
  'str/htmlEscape',
  'compiled/widget/DatetimeField',
  'jsx/shared/render-datepicker-time',
  'jquery.keycodes' /* keycodes */,
  'vendor/date' /* Date.parse, Date.UTC, Date.today */,
  'jqueryui/datepicker' /* /\.datepicker/ */,
  'jqueryui/sortable' /* /\.sortable/ */,
  'jqueryui/widget' /* /\.widget/ */
], function(I18n, $, tz, htmlEscape, DatetimeField, renderDatepickerTime) {
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
    var year = tz.format(date, '%Y');
    while (year.length < 4) year = "0" + year;
    return Date.parse(tz.format(date, year + '-%m-%d %T'));
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
  $.dateString = function(date, options) {
    if (date == null) return '';
    var timezone = options && options.timezone;
    var format = options && options.format;

    if (format === 'full') {
      format = 'date.formats.full'
    } else if (format !== 'medium' && $.sameYear(date, new Date())) {
      format = 'date.formats.short'
    } else {
      format = 'date.formats.medium'
    }

    if (typeof timezone == 'string' || timezone instanceof String) {
      return tz.format(date, format, timezone) || '';
    } else {
      return tz.format(date, format) || '';
    }
  };

  $.timeString = function(date, options) {
    if (date == null) return "";
    var timezone = options && options.timezone;

    // match ruby-side short format on the hour, e.g. `1pm`
    // can't just check getMinutes, cuz not all timezone offsets are on the hour
    var format = tz.format(date, '%M') === '00' ?
      'time.formats.tiny_on_the_hour' :
      'time.formats.tiny';

    if (typeof timezone == 'string' || timezone instanceof String) {
      return tz.format(date, format, timezone) || '';
    } else {
      return tz.format(date, format) || '';
    }
  };
  $.datetimeString = function(datetime, options) {
    datetime = tz.parse(datetime);
    if (datetime == null) return "";
    var dateValue = $.dateString(datetime, options);
    var timeValue = $.timeString(datetime, options);
    return I18n.t('#time.event', '%{date} at %{time}', { date: dateValue, time: timeValue });
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

  $.datepicker.oldParseDate = $.datepicker.parseDate;
  $.datepicker.parseDate = function(format, value, settings) {
    // try parsing with tz.parse first. if it can, its return is an unfudged
    // value, but the datepicker expects a fudged one, so fudge it. if it can't
    // parse it, fallback to the datepicker's original parseDate (which returns
    // already fudged)
    var datetime = tz.parse(value);
    if (datetime) {
      return $.fudgeDateForProfileTimezone(datetime);
    } else {
      return $.datepicker.oldParseDate(format, value, settings);
    }
  };
  $.datepicker._generateDatepickerHTML = $.datepicker._generateHTML;
  $.datepicker._generateHTML = function(inst) {
    var html = $.datepicker._generateDatepickerHTML(inst);
    if(inst.settings.timePicker) {
      html += renderDatepickerTime(inst.input);
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
      if(hr || min) {
        text += " " + hr + ":" + (min || "00");
        if (tz.useMeridian()) {
          text += " " + (ampm || I18n.t('#time.pm'));
        }
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
      var $field = $(this);
      if (!$field.hasClass('datetime_field_enabled')) {
        $field.addClass('datetime_field_enabled');
        new DatetimeField($field, options);
      }
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
