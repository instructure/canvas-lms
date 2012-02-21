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
require(['jquery'], function($) {

if(!$("#tool_form").hasClass('new_tab')) {
  $("#content").addClass('padless');
} else {
  var $button = $("#tool_form button");
  // Firefox remembers disabled state after page reloads
  $button.attr('disabled', false);
  setTimeout(function() {
    // LTI links have a time component in the signature and will
    // expire after a few minutes. 
    $button.attr('disabled', true).text($button.data('expired_message'));
  }, 60 * 2.5 * 1000)
  $("#tool_form").submit(function() {
    $(this).find(".load_tab,.tab_loaded").toggle();
  });
}
$("#tool_form:not(.new_tab)").submit().hide();
$(document).ready(function() {
  if($("#tool_content").length) {
    $(window).resize(function() {
      var top = $("#tool_content").offset().top;
      var height = $(window).height();
      $("#tool_content").height(height - top);
    }).triggerHandler('resize');
  }
});

});
