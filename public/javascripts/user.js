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
  'i18n!users',
  'jquery' /* $ */,
  'jquery.instructure_misc_plugins' /* confirmDelete */
], function(I18n, $) {
$(function(){
  $(".courses .course,.groups .group").bind('focus mouseover', function(event) {
    $(this).find(".info").addClass('info_hover');
  });
  $(".courses .course,.groups .group").bind('blur mouseout', function(event) {
    $(this).find(".info").removeClass('info_hover');
  });
  $("#courses .unenroll_link").click(function(event) {
    event.preventDefault();
    $(this).parents("li").confirmDelete({
      url: $(this).attr('rel'),
      message: I18n.t('confirms.unenroll_user', "Are you sure you want to unenroll this user?"),
      success: function() {
        $(this).slideUp(function() {
          $(this).remove();
        });
      }
    });
  });
})
});
