#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require [
  'jquery'
  'jqueryui/dialog'
  'jquery.instructure_misc_plugins'
  'jquery.loadingImg'
], ($) ->
  $(".visibility_help_link").live "click", (event) ->
    event.preventDefault()
    $dialog = $("#visibility_help_dialog")
    if $dialog.length == 0
      $dialog = $("<div/>").attr("id", "visibility_help_dialog").hide().loadingImage().appendTo("body")
      .dialog(
        autoOpen: false
        title: ''
        width: 330
      )
      $.get "/partials/_course_visibility_help.html", (html) ->
        $dialog
          .loadingImage('remove')
          .html(html)
    $dialog.dialog "open"
