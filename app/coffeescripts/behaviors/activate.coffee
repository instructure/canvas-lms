#
# Copyright (C) 2013 - present Instructure, Inc.
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

  fireKeyclick = (e) ->
    kce = $.Event('keyclick')
    $(e.target).trigger(kce)
    e.preventDefault() if kce.isDefaultPrevented()
    e.stopPropagation() if kce.isPropagationStopped()

  keydownHandler = (e) ->
    switch e.which
      when 13
        fireKeyclick(e)
      when 32
        # prevent scrolling when the spacebar is pressed on a "button"
        e.preventDefault()

  keyupHandler = (e) ->
    switch e.which
      when 32
        fireKeyclick(e)

  $.fn.activate_keyclick = (selector=null) ->
    this.on 'keydown', selector, keydownHandler
    this.on 'keyup', selector, keyupHandler

  $(document).activate_keyclick('[role=button], [role=checkbox]')
