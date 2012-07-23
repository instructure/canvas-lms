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
  'i18n!dashboard',
  'jquery' /* $ */,
  //'compiled/dashboardToggle',
  'jquery.instructure_misc_plugins' /* showIf */
], function(I18n, $, dashboardToggle) {

  var $toggle = $(dashboardToggle('enable'));
  $toggle.css({'float': 'right'})
  $('#not_right_side').prepend($toggle);

  $(function initDashbardJs(){

  var afterTopicListTop = null,
      lastElementRetrievalCount = null,
      retrievingMoreElements = false,
      windowHeight = null,
      $after_topic_list = $("#after_topic_list"),
      $topic_list = $('#topic_list'),
      $show_all_messages_link = $("#show_all_messages_link");
  
  function measureForTopicList() {
    windowHeight = $(window).height();
    if($after_topic_list.length > 0) {
      afterTopicListTop = $after_topic_list.offset().top;
    } else {
      afterTopicListTop = windowHeight;
    }
  }
  measureForTopicList();
  setInterval(measureForTopicList, 2000);
  
  $(".group_reference_checkbox").change(function(event, expand) {
    var $box = $(this);
    if(expand !== false) {
      $show_all_messages_link.click();
    }
    var context = $box.attr('id').substring(6);
    $(".message_" + context).showIf($box.attr('checked'));
  }).each(function() { 
    $(this).triggerHandler('change', false); 
  });
  
  function showDashboardTopicsThatThatWereScrolledIntoView(){
    var scrollTop = $.windowScrollTop();
    if(afterTopicListTop && windowHeight) {
      if(scrollTop + windowHeight >= afterTopicListTop) {
        var $elementsToShow = $topic_list.find(".topic_message.hidden_until_scroll").not('.part_of_clump').slice(0, 10);
        if($elementsToShow.length < 10 && lastElementRetrievalCount !== 0 && !retrievingMoreElements) {
          retrievingMoreElements = true;
          // - retrieve and insert the next list of entries
          //   with the class hidden_until_scroll applied
          // - also add a loading... message to the end of #topic_list
          //   to be shown if it gets that far
          //   remove it as soon as the data gets in
          // - trigger measureForTopicList again
        }
        $elementsToShow.removeClass('hidden_until_scroll');
        measureForTopicList();
      }
    }
  }
  $(window).bind('scroll', showDashboardTopicsThatThatWereScrolledIntoView);
  setTimeout(showDashboardTopicsThatThatWereScrolledIntoView, 0);
  
  (function consolidateDuplicateDasboardNotifications() {

    // TODO: i18n
    var notifications = {
      "New Assignments and Events": [],
      "Grading Notifications": [],
      "Group Membership Notifications": [],
      "Date Changes": [],
      "Scheduling Notifications": []
    };

    $(".dashboard_notification").each(function() {
      var notificationNameElement = $(this).find(".notification_name").get(0);
          notificationName = notificationNameElement && notificationNameElement.innerHTML;
      if (notificationName ) {
        switch(notificationName) {
        case "New Event Created":
        case "Assignment Created":
        case "Appointment Reserved For User":
          notifications["New Assignments and Events"].push(this);
          break;
        case "Assignment Grading Reminder":
        case "Assignment Graded":
        case "Grade Weight Changed":
        case "Assignment Submitted Late":
        case "Group Assignment Submitted Late":
          notifications["Grading Notifications"].push(this);
          break;
        case "New Context Group Membership":
        case "New Context Group Membership Invitation":
        case "Group Membership Accepted":
        case "Group Membership Rejected":
        case "New Student Organized Group":
          notifications["Group Membership Notifications"].push(this);
          break;
        case "Assignment Due Date Changed":
        case "Event Date Changed":
          notifications["Date Changes"].push(this);
          break;
        case "Appointment Group Published":
        case "Appointment Group Updated":
          notifications["Scheduling Notifications"].push(this);
        }
      }
    });
    for(var idx in notifications) {
      if(notifications[idx].length > 3) {
        var $template = $(notifications[idx][0]).clone();
        $template.find(".content,.under_links,.disable_item_link").remove();
        $template.find(".context_code").text(I18n.t('links.show_notifications', "click to show these notifications in the stream"));
        $template.find(".subject").attr('href', '#').text(notifications[idx].length + " " + idx);
        $template.data('items', notifications[idx]);
        $template.click(function(event) {
          event.preventDefault();
          var items = $(this).data('items');
          $(items).removeClass('part_of_clump');
          $(this).remove();
        });
        $(notifications[idx]).addClass('part_of_clump').eq(0).before($template);
      }
    }
  })();
  
});
});
