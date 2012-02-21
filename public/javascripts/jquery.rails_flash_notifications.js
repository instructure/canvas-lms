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

// does Rails-style flash message/error boxes that drop down from the top of the scren
define(['jquery', 'jqueryui/effects/drop'], function($){
  var already_listening_for_close_link_clicks = false;
  $._flashBox = function(type, content, timeout) {
    if(!already_listening_for_close_link_clicks) {
      already_listening_for_close_link_clicks = true;
      $("#flash_message_holder .close-link").live('click', function(event) {
        event.preventDefault();
      });
    }
    $("#flash_" + type + "_message")
      .stop(true, true)
      .empty().append("<a href='' class='close-link'>#</a>")
      .append(content)
      .hide()
      .css('opacity', 1)
      .show('drop', { direction: "up" })
      .slideDown('normal')
      .delay(timeout || 7000)
      .hide('drop', { direction: "up" }, 2000, function() {
        $(this).empty().hide();
      });
  };
  
  // Pops up a small notification box at the top of the screen.
  $.flashMessage = function(content, timeout) {
    $._flashBox("notice", content, timeout);
  };
  // Pops up a small error box at the top of the screen.
  $.flashError = function(content, timeout) {
    $._flashBox("error", content, timeout);
  };
  
});

