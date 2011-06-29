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

I18n.scoped('content_locks', function(I18n) {
$(document).ready(function() {
  $(".content_lock_icon").live('click', function(event) {
    if($(this).data('lock_reason')) {
      event.preventDefault();
      var data = $(this).data('lock_reason');
      var type = data.type;
      var $reason = $("<div/>");
      // Note: CourseController#locks is capable of returning locks for quiz, assignments, and discussion_topics,
      // this is currently only ever used for quizzes (in quiz_index.js)
      switch(type) {
        case "quiz":
          $reason.text(I18n.t('messages.quiz_locked_no_reason', "This quiz is locked.  No other reason has been provided."));
          break;
        default:
          $reason.text(I18n.t('messages.content_locked_no_reason', "This content is locked.  No other reason has been provided."));
          break;
      }
      if(data.lock_at) {
        switch (type) {
          case "quiz":
            $reason.text(I18n.t('messages.quiz_locked_at', "This quiz was locked %{at}", {at: $.parseFromISO(data.lock_at).datetime_formatted}));
            break;
          default:
            $reason.text(I18n.t('messages.content_locked_at', "This content was locked %{at}", {at: $.parseFromISO(data.lock_at).datetime_formatted}));
        }
      } else if(data.unlock_at) {
        switch (type) {
          case "quiz":
            $reason.text(I18n.t('messages.quiz_locked_until', "This quiz is locked until %{date}", {date: $.parseFromISO(data.unlock_at).datetime_formatted}));
            break;
          default:
            $reason.text(I18n.t('messages.quiz_locked_until', "This quiz is locked until %{date}", {date: $.parseFromISO(data.unlock_at).datetime_formatted}));
            break;
        }
      } else if(data.context_module) {
        switch (type) {
          case "quiz":
            $reason.html(I18n.t('messages.quiz_locked_module', "This quiz is part of the module *%{module}* and hasn't been unlocked yet.", {module: $.htmlEscape(data.context_module.name), wrapper: '<b>$1</b>'}));
            break;
          default:
            $reason.html(I18n.t('messages.content_locked_module', "This content is part of the module *%{module}* and hasn't been unlocked yet.", {module: $.htmlEscape(data.context_module.name), wrapper: '<b>$1</b>'}));
            break;
        }
        if($("#context_modules_url").length > 0) {
          $reason.append("<br/>");
          var $link = $("<a/>");
          $link.attr('href', $("#context_modules_url").attr('href'));
          $link.text(I18n.t('messages.visit_modules_page_for_details', "Visit the modules page for information on how to unlock this content."));
          $reason.append($link);
        }
      }
      var $dialog = $("#lock_reason_dialog");
      if($dialog.length === 0) {
        $dialog = $("<div/>").attr('id', 'lock_reason_dialog');
        $("body").append($dialog.hide());
        var $div = ("<div class='lock_reason_content'></div><div class='button-container'><button type='button' class='button'>" +
                $.h(I18n.t('buttons.ok_thanks', "Ok, Thanks")) + "</button></div>");
        $dialog.append($div);
        $dialog.find(".button-container .button").click(function() {
          $dialog.dialog('close');
        });
      }
      $dialog.find(".lock_reason_content").empty().append($reason);
      $dialog.dialog('close').dialog({
        autoOpen: false,
        title: I18n.t('titles.content_is_locked', "Content Is Locked")
      }).dialog('open');
    }
  });
});
});