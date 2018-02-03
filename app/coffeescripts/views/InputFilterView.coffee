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
  './InputView'
], (InputView) ->

  ##
  # Makes an input field that emits `input` and `select` events, and
  # automatically selects itself if the user presses the enter key (don't have
  # to backspace out the text, or if you do, it deletes all of it).
  #
  # Events:
  #
  #   input: Emits after a short delay so it doesn't fire off the event with
  #   every keyup from the user, sends the value of the input in the event
  #   parameters.
  #
  #   enter: Emits when the user hits enter in the field
  class InputFilterView extends InputView

    events: {'keyup', 'change'}

    defaults:
      onInputDelay: 200
      modelAttribute: 'filter'
      minLength: 3
      allowSmallerNumbers: true

    onInput: =>
      if @el.value isnt @lastValue
        @updateModel()
        @trigger 'input', @el.value
      @lastValue = @el.value

    onEnter: ->
      @el.select()
      @trigger 'enter', @el.value

    keyup: (event) ->
      clearTimeout @onInputTimer
      @onInputTimer = setTimeout @onInput, @options.onInputDelay
      @onEnter() if event.which? and event.which is 13
      null

    change: @::keyup
