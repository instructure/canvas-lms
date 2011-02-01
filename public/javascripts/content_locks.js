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

$(document).ready(function() {
  $(".content_lock_icon").live('click', function(event) {
    if($(this).data('lock_reason')) {
      event.preventDefault();
      var data = $(this).data('lock_reason');
      var type = data.type || "content";
      var $reason = $("<div/>");
      $reason.html("This " + type + " is locked.  No other reason has been provided.");
      if(data.lock_at) {
        $reason.html("This " + type + " was locked " + $.parseFromISO(data.lock_at).datetime_formatted);
      } else if(data.unlock_at) {
        $reason.html("This " + type + " is locked until " + $.parseFromISO(data.unlock_at).datetime_formatted);
      } else if(data.context_module) {
        $reason.html("This " + type + " is part of the module <b>" + data.context_module.name + "</b> and hasn't been unlocked yet.");
        if($("#context_modules_url").length > 0) {
          $reason.append("<br/>");
          var $link = $("<a/>");
          $link.attr('href', $("#context_modules_url").attr('href'));
          $link.text("Visit the modules page for information on how to unlock this content.");
          $reason.append($link);
        }
      }
      var $dialog = $("#lock_reason_dialog");
      if($dialog.length === 0) {
        $dialog = $("<div/>").attr('id', 'lock_reason_dialog');
        $("body").append($dialog.hide());
        var $div = ("<div class='lock_reason_content'></div><div class='button-container'><button type='button' class='button'>Ok, Thanks</button></div>");
        $dialog.append($div);
        $dialog.find(".button-container .button").click(function() {
          $dialog.dialog('close');
        });
      }
      $dialog.find(".lock_reason_content").empty().append($reason);
      $dialog.dialog('close').dialog({
        autoOpen: false,
        title: "Content Is Locked"
      }).dialog('open');
    }
  });
});