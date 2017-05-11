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

# Custom jQuery element event 'outerclick'
#
# Usage:
#   $el = $ '#el'
#   $el.on 'outerclick', (event) ->
#     doStuff()
#
#   class SomeView extends Backbone.View
#     events:
#       'outerclick': 'handler'
#     handler: (event) ->
#       @hide()
define ['jquery'], ($) ->

  $els = $()
  $doc = $ document
  outerClick = 'outerclick'
  eventName = "click.#{outerClick}-special"

  $.event.special[outerClick] =
    setup: ->
      $els = $els.add this
      if $els.length is 1
        $doc.on eventName, handleEvent

    teardown: ->
      $els = $els.not this
      $doc.off eventName if $els.length is 0

    add: (handleObj) ->
      oldHandler = handleObj.handler
      handleObj.handler = (event, el) ->
        event.target = el
        oldHandler.apply this, arguments

  handleEvent = (event) ->
    $els.each ->
      $el = $ this
      if this isnt event.target and $el.has(event.target).length is 0
        $el.triggerHandler outerClick, [event.target]

