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

require([
  'jquery' /* jQuery, $ */,
  'calendar_move' /* calendarMonths */,
  'wikiSidebar',
  'jquery.instructure_date_and_time' /* dateString, datepicker */,
  'jquery.instructure_forms' /* formSubmit, formErrors */,
  'jquery.instructure_misc_helpers' /* scrollSidebar */,
  'jquery.instructure_misc_plugins' /* ifExists, showIf */,
  'jquery.loadingImg' /* loadingImage */,
  'tinymce.editor_box' /* editorBox */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/datepicker' /* /\.datepicker/ */
], function(jQuery, calendarMonths, wikiSidebar) {

jQuery(function($){
  var $edit_course_syllabus_form = $("#edit_course_syllabus_form"),
      $course_syllabus_body = $("#course_syllabus_body"),
      $course_syllabus = $("#course_syllabus"),
      $course_syllabus_details = $('#course_syllabus_details'),
      $syllabus = $('#syllabus'),
      $mini_month = $(".mini_month");
      
  function highlightDaysWithEvents() {
    $mini_month.find(".day.has_event").removeClass('has_event');
    $syllabus.find("tr.date").each(function() {
      var splitDate = $(this).find(".day_date").attr('data-date').split('/'),
          monthDayYearDate = splitDate.join('_'),
          yearMonthDayDate = [splitDate[2], splitDate[0], splitDate[1]].join('_');
      // the 2 different selectors here are because when the page loads, it hs .date_21_10_2010 classes,
      // but because of something in the mini_calendar code, when you go forward and back they dont have 
      // the classes but instead have ids of #mini_day_2010_10_21, weird!
      $mini_month.find(".mini_calendar_day.date_" + monthDayYearDate + ', #mini_day_' + yearMonthDayDate).addClass('has_event');
    });
  }

  function toggleHighlighForDate(highlight, date) {
    $("tr.date.related,.day.related").removeClass('related');
    if (highlight) {
      var splitDate = date.split('/'),
          monthDayYearDate = splitDate.join('_'),
          yearMonthDayDate = [splitDate[2], splitDate[0], splitDate[1]].join('_');
          
      // see comment above about why the 2 selectors.
      $mini_month.find(".mini_calendar_day.date_" + monthDayYearDate + ', #mini_day_' + yearMonthDayDate)
        .add($syllabus.find('tr.date.events_' + monthDayYearDate))
        .addClass('related'); 
    }
  }
  
  $mini_month.find('.next_month_link, .prev_month_link').bind('mousedown', function(event) {
    event.preventDefault();
    calendarMonths.changeMonth($mini_month, $(this).hasClass('next_month_link') ? 1 : -1);
    highlightDaysWithEvents();
  }).bind('click', false);
  
  $mini_month.delegate('.mini_calendar_day', 'click', function(event) {
    event.preventDefault();
    var date = $(this).find('.day_number').attr('title');
    calendarMonths.changeMonth($mini_month, date);
    highlightDaysWithEvents();
    $(".events_" + date.replace(/\//g, "_")).ifExists(function($events){
      $("html,body").scrollTo($events);
      toggleHighlighForDate(true, date);
    });
  }).delegate('.mini_calendar_day', 'mouseover mouseout', function(event) {
    toggleHighlighForDate(event.type === 'mouseover', $(this).find(".day_number").attr('title'));
  });
  
  $syllabus.delegate("tr.date", 'mouseenter mouseleave', function(event) {
    toggleHighlighForDate(event.type === 'mouseenter', $(this).find(".day_date").attr('title'));
  });
  
  $(".jump_to_today_link").click(function(event) {
    event.preventDefault();
    var todayString = $.datepicker.formatDate("mm/dd/yy", new Date()),
        $lastBefore;
        
    $("tr.date").each(function() {
      var dateString = $(this).find(".day_date").attr('title');
      if (dateString > todayString) { return false; }      
      $lastBefore = $(this);
    });
    calendarMonths.changeMonth($mini_month, todayString);
    $("html,body").scrollTo($lastBefore || $("tr.date:first"));
    toggleHighlighForDate(true, todayString);
  });
  wikiSidebar && wikiSidebar.init();
  
  $edit_course_syllabus_form.bind('edit', function() {
    $edit_course_syllabus_form.show();
    $course_syllabus.hide();
    $course_syllabus_details.hide();
    $course_syllabus_body.editorBox();
    $course_syllabus_body.editorBox('set_code', $course_syllabus.html());
    if(wikiSidebar) {
      wikiSidebar.attachToEditor($course_syllabus_body);
      wikiSidebar.show();
      $("#sidebar_content").hide();
    }
  });
  $edit_course_syllabus_form.bind('hide_edit', function() {
    $edit_course_syllabus_form.hide();
    $course_syllabus.show();
    var text = $.trim($course_syllabus.html());
    $course_syllabus_details.showIf(!text);
    $course_syllabus_body.editorBox('destroy');
    $("#sidebar_content").show();
    if(wikiSidebar) {
      wikiSidebar.hide();
    }
  });
  $(".edit_syllabus_link").click(function(event) {
    event.preventDefault();
    $("#edit_course_syllabus_form").triggerHandler('edit');
  });
  $edit_course_syllabus_form.find(".toggle_views_link").click(function(event) {
    event.preventDefault();
    $course_syllabus_body.editorBox('toggle');
  });
  $edit_course_syllabus_form.find(".cancel_button").click(function(event) {
    $edit_course_syllabus_form.triggerHandler('hide_edit');
    event.preventDefault();
  });
  $edit_course_syllabus_form.formSubmit({
    object_name: 'course',
    processData: function(data) {
      data['course[syllabus_body]'] = $course_syllabus_body.editorBox('get_code');
      return data;
    },
    beforeSubmit: function(data) {
      $edit_course_syllabus_form.triggerHandler('hide_edit');
      $course_syllabus_details.hide();
      $course_syllabus.loadingImage();
    },
    success: function(data) {
      $course_syllabus.loadingImage('remove').html(data.course.syllabus_body);
      $course_syllabus_details.hide();
    },
    error: function(data) {
      $edit_course_syllabus_form.triggerHandler('edit').formErrors(data);
    }
  });
  $.scrollSidebar();
  highlightDaysWithEvents();

});
});
