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
  'i18nObj',
  'jquery' /* $ */,
  'jquery.instructure_date_and_time' /* datepicker */,
  'jquery.templateData' /* fillTemplateData */,
  'jqueryui/datepicker' /* /\.datepicker/ */
], function(I18n, $) {

  var monthNames = I18n.lookup('date.month_names');

  function makeDate(date) {
    return {
      day: date.getDate(),
      month: date.getMonth(),
      year: date.getFullYear()
    }
  }

  return {
    changeMonth: function($month, change) {
      var monthData = $month.data('calendar_objects');
      var data = {};
      var current = null;
      if(typeof(change) == "string") {
        var current = $.datepicker.oldParseDate('mm/dd/yy', change);
        if(current) {
          current.setDate(1);
        }
      }
      if(!current) {
        var month = parseInt($month.find(".month_number").text(), 10);
        var year = parseInt($month.find(".year_number").text(), 10);
        var current = new Date(year, month + change - 1, 1);
      }
      var data = { 
        month_name: monthNames[current.getMonth() + 1],
        month_number: current.getMonth() + 1,
        year_number: current.getFullYear()
      };
      $month.fillTemplateData({data: data});
      var date = new Date();
      var today = makeDate(date);
      var firstDayOfMonth = makeDate(current);
      date = current;
      date.setDate(0);
      date.setDate(date.getDate() - date.getDay());
      var firstDayOfSquare = makeDate(date); 
      var lastDayOfPreviousMonth = null;
      if(firstDayOfMonth.day != firstDayOfSquare.day) {
        date.setDate(1);
        date.setMonth(date.getMonth() + 1);
        date.setDate(0);
        lastDayOfPreviousMonth = {
          day: date.getDate(),
          month: firstDayOfSquare.month,
          year: firstDayOfSquare.year
        }
        date.setDate(1);
        date.setMonth(date.getMonth() + 1);
      }
      date.setMonth(current.getMonth() + 1);
      date.setDate(0);
      var lastDayOfMonth = {
        day: date.getDate(),
        month: firstDayOfMonth.month,
        year: firstDayOfMonth.yearh
      }
      date.setDate(date.getDate() + 1);
      date.setDate(date.getDate() + (6 - date.getDay()));
      date.setDate(date.getDate() + 7);
      var lastDayOfSquare = makeDate(date);
      var $days = $month.data("days");
      if(!$days) {
        $days = $month.find(".calendar_day_holder");
        $month.data("days", $days);
      }
      if($month.hasClass('mini_month')) {
        $days = $month.find(".day");
      }
      $month.find(".calendar_event").remove();
      var idx = 0;
      var day = firstDayOfSquare.day;
      var month = firstDayOfSquare.month;
      var year = firstDayOfSquare.year;
      while(day <= lastDayOfSquare.day || month != lastDayOfSquare.month) {
        var $day = $days.eq(idx);
        if($day.length > 0) {
          var classes = $day.attr('class').split(" ");
          var class_names = [];
          for(var i = 0; i < classes.length; i++) {
            if(classes[i].indexOf('date_') == 0) {
            } else {
              class_names.push(classes[i]);
            }
          }
          $day.attr('class', class_names.join(" "));
        }
        $day.show().addClass('visible').parents("tr").show().addClass('visible');
        var data = {
          day_number: day
        }
        var month_number = month < 9 ? "0" + (month + 1) : (month + 1);
        var day_number = day < 10 ? "0" + day : day;
        id = "day_" + year + "_" + month_number + "_" + day_number
        if($month.hasClass('mini_month')) {
          id = "mini_" + id;
        }
        $day.attr('id', id)
          .addClass("date_" + month_number + "_" + day_number + "_" + year)
          .find(".day_number").text(day).attr('title', month_number + "/" + day_number + "/" + year)
          .addClass("date_" + month_number + "_" + day_number + "_" + year); // left here because I don't know what it'll break...
        var $div = $day.children('div');
        if($month.hasClass('mini_month')) {
          $div = $day;
        }
        $div.removeClass('current_month other_month today');
        if(month == firstDayOfMonth.month) {
          $div.addClass('current_month');
        } else {
          $div.addClass('other_month');
        }
        if(month == today.month && day == today.day && year == today.year) {
          $div.addClass('today');
        }
        day++;
        idx++;
        if((lastDayOfPreviousMonth && day > lastDayOfPreviousMonth.day && month == lastDayOfPreviousMonth.month)
              || (day > lastDayOfMonth.day && month == lastDayOfMonth.month)) {
          month = month + 1;
          if(month >= 12) {
            month -= 12;
            year++;
          }
          day = 1;
        }
      }
      while(idx < $days.length) {
        var $day = $days.eq(idx);
        $day.parents("tr").hide().removeClass('visible');
        $day.hide().removeClass('visible');
        idx++;
      }
      if(!$month.hasClass('mini_month')) {
      }
    }
  };
});
