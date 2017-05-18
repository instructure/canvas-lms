#
# Copyright (C) 2012 - present Instructure, Inc.
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

define [
  'jquery'
  'compiled/fn/preventDefault'
  'jqueryui/dialog',
], ($, preventDefault) ->

  $.fn.openAsDialog = (options = {}) ->
    @click preventDefault (e) ->
      $link = $(e.target)

      options.width ?= 550
      options.height ?= 500
      options.title ?= $link.attr('title')
      options.resizable ?= false

      $dialog = $("<div>")
      $iframe = $('<iframe>', style: "position:absolute;top:0;left:0;border:none", src: $link.attr('href') + '?embedded=1&no_headers=1')
      $dialog.append $iframe

      $dialog.on "dialogopen", ->
        $container = $dialog.closest('.ui-dialog-content')
        $iframe.height $container.outerHeight()
        $iframe.width $container.outerWidth()
      $dialog.dialog options

  $ ->
    $('a[data-open-as-dialog]').openAsDialog()

  $
