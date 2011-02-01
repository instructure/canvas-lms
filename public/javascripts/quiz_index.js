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
  $(".delete_quiz_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".quiz").confirmDelete({
      url: $(this).attr('href'),
      message: "Are you sure you want to delete this quiz?",
      error: function(data) {
        $(this).formErrors(data);
      }
    });
  });
  if($("#quiz_locks_url").length > 0) {
    var data = {};
    var assets = [];
    $("li.quiz").each(function() {
      assets.push("quiz_" + $(this).attr('id').substring(13));
    });
    data.assets = assets.join(",");
    $.ajaxJSON($("#quiz_locks_url").attr('href'), 'GET', data, function(data) {
      for(var idx in data) {
        var code = idx;
        var locked = !!data[idx];
        if(locked) {
          var $icon = $("#quiz_lock_icon").clone().removeAttr('id');
          data[idx].type = "quiz";
          $icon.data('lock_reason', data[idx]);
          $("#summary_" + code).find(".quiz_title").prepend($icon);
        }
      }
    }, function() {});
  }
});