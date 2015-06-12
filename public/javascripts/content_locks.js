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
  'i18n!content_locks',
  'jquery' /* $ */,
  'str/htmlEscape',
  'jquery.instructure_date_and_time' /* datetimeString */,
  'jqueryui/dialog'
], function(INST, I18n, $, htmlEscape) {

  INST.lockExplanation = function(data, type) {
    // Any additions to this function should also be added to similar logic in ApplicationController.rb
    if(data.lock_at) {
      var lock_at = $.datetimeString(data.lock_at)
      switch (type) {
        case "quiz":
          return I18n.t('messages.quiz_locked_at', "This quiz was locked %{at}.", {at: lock_at});
        case "assignment":
          return I18n.t('messages.assignment_locked_at', "This assignment was locked %{at}.", {at: lock_at});
        case "topic":
          return I18n.t('messages.topic_locked_at', "This topic was locked %{at}.", {at: lock_at});
        case "file":
          return I18n.t('messages.file_locked_at', "This file was locked %{at}.", {at: lock_at});
        case "page":
          return I18n.t('messages.page_locked_at', "This page was locked %{at}.", {at: lock_at});
        default:
          return I18n.t('messages.content_locked_at', "This content was locked %{at}.", {at: lock_at});
      }
    } else if(data.unlock_at) {
      var unlock_at = $.datetimeString(data.unlock_at)
      switch (type) {
        case "quiz":
          return I18n.t('messages.quiz_locked_until', "This quiz is locked until %{date}.", {date: unlock_at});
        case "assignment":
          return I18n.t('messages.assignment_locked_until', "This assignment is locked until %{date}.", {date: unlock_at});
        case "topic":
          return I18n.t('messages.topic_locked_until', "This topic is locked until %{date}.", {date: unlock_at});
        case "file":
          return I18n.t('messages.file_locked_until', "This file is locked until %{date}.", {date: unlock_at});
        case "page":
          return I18n.t('messages.page_locked_until', "This page is locked until %{date}.", {date: unlock_at});
        default:
          return I18n.t('messages.content_locked_until', "This content is locked until %{date}.", {date: unlock_at});
      }
    } else if(data.context_module) {
      var html = '';
      switch (type) {
        case "quiz":
          html += I18n.t('messages.quiz_locked_module', "This quiz is part of the module *%{module}* and hasn't been unlocked yet.", {module: htmlEscape(data.context_module.name), wrapper: '<b>$1</b>'});
          break;
        case "assignment":
          html += I18n.t('messages.assignment_locked_module', "This assignment is part of the module *%{module}* and hasn't been unlocked yet.", {module: htmlEscape(data.context_module.name), wrapper: '<b>$1</b>'});
          break;
        case "topic":
          html += I18n.t('messages.topic_locked_module', "This topic is part of the module *%{module}* and hasn't been unlocked yet.", {module: htmlEscape(data.context_module.name), wrapper: '<b>$1</b>'});
          break;
        case "file":
          html += I18n.t('messages.file_locked_module', "This file is part of the module *%{module}* and hasn't been unlocked yet.", {module: htmlEscape(data.context_module.name), wrapper: '<b>$1</b>'});
          break;
        case "page":
          html += I18n.t('messages.page_locked_module', "This page is part of the module *%{module}* and hasn't been unlocked yet.", {module: htmlEscape(data.context_module.name), wrapper: '<b>$1</b>'});
          break;
        default:
          html += I18n.t('messages.content_locked_module', "This content is part of the module *%{module}* and hasn't been unlocked yet.", {module: htmlEscape(data.context_module.name), wrapper: '<b>$1</b>'});
          break;
      }
      if ($("#context_modules_url").length > 0) {
        html += "<br/>";
        html += "<a href='" + htmlEscape($("#context_modules_url").attr('href')) + "'>";
        html += htmlEscape(I18n.t('messages.visit_modules_page_for_details', "Visit the modules page for information on how to unlock this content."));
        html += "</a>";
      }
      return $.raw(html);
    }
    else {
      switch(type) {
        case "quiz":
          return I18n.t('messages.quiz_locked_no_reason', "This quiz is locked.  No other reason has been provided.");
        case "assignment":
          return I18n.t('messages.assignment_locked_no_reason', "This assignment is locked.  No other reason has been provided.");
        case "topic":
          return I18n.t('messages.topic_locked_no_reason', "This topic is locked.  No other reason has been provided.");
        case "file":
          return I18n.t('messages.file_locked_no_reason', "This file is locked.  No other reason has been provided.");
        case "page":
          return I18n.t('messages.page_locked_no_reason', "This page is locked.  No other reason has been provided.");
        default:
          return I18n.t('messages.content_locked_no_reason', "This content is locked.  No other reason has been provided.");
      }
    }
  }

  $(document).ready(function() {
    $(".content_lock_icon").live('click', function(event) {
      if($(this).data('lock_reason')) {
        event.preventDefault();
        var data = $(this).data('lock_reason');
        var type = data.type;
        var $reason = $("<div/>");
        $reason.html(htmlEscape(INST.lockExplanation(data, type)));
        var $dialog = $("#lock_reason_dialog");
        if($dialog.length === 0) {
          $dialog = $("<div/>").attr('id', 'lock_reason_dialog');
          $("body").append($dialog.hide());
          var $div = ("<div class='lock_reason_content'></div><div class='button-container'><button type='button' class='btn' >" +
                  htmlEscape(I18n.t('buttons.ok_thanks', "Ok, Thanks")) + "</button></div>");
          $dialog.append($div);
          $dialog.find(".button-container .btn").click(function() {
            $dialog.dialog('close');
          });
        }
        $dialog.find(".lock_reason_content").empty().append($reason);
        $dialog.dialog({
          title: I18n.t('titles.content_is_locked', "Content Is Locked")
        });
      }
    });
  });
});
