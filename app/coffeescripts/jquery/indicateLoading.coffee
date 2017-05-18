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
], ($) ->
  
  # possible values for position are 'center' and 'after', see g_util_misc.scss
  # passign a position is optional and if ommited will use 'center'
  $.fn.indicateLoading = (position, deferred) ->
    unless deferred?
      deferred = position
      position = 'center'
    @each ->
      $this = $(this).addClass 'loading ' + position
      $.when(deferred).done ->
        $this.removeClass 'loading ' + position