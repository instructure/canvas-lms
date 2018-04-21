#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'underscore'
  'Backbone'
  'jst/outcomes/outcomeCalculationMethodForm'
  'jsx/shared/helpers/numberHelper'
], (_, Backbone, template, numberHelper) ->
  class CalculationMethodFormView extends Backbone.View
    @optionProperty 'el'
    @optionProperty 'model'
    @optionProperty 'state'

    template: template

    els:
      '#calculation_int': '$calculation_int'
    events:
      'blur #calculation_int': 'blur'
      'keyup #calculation_int': 'keyup'

    afterRender: ->
      if @hadFocus
        @$calculation_int.focus().val(@$calculation_int.val())
        @$calculation_int[0].selectionStart = @selectionStart
      @hadFocus = undefined

    attach: ->
      @model.on('change:calculation_method', @render)

    blur: (e) ->
      clearTimeout(@timeout) if @timeout
      @change(e)

    change: (e) ->
      val = parseInt(numberHelper.parse($(e.target).val()))
      return if _.isNaN(val)
      @model.set({
        calculation_int: val
      })
      @render()

    keyup: (e) ->
      clearTimeout(@timeout) if @timeout
      @timeout = setTimeout(=>
        @change(e)
      , 500)

    # Three things we want to accomplish with this override:
    # 1 - capture whether or not the calculation int input field has
    #     focus (this will be true if we're rendering after a keyup
    #     event) so we can go back to it after re-render.
    # 2 - undelegateEvents so the re-render doesn't trigger blur if
    #     the calculation int input has focus.
    # 3 - delegateEvents again after render so that we are hooked up
    #     to handle the next round of events.
    render: ->
      @hadFocus = !_.isEmpty(@$calculation_int) and
        document.activeElement is @$calculation_int[0]
      if @hadFocus
        @selectionStart = document.activeElement.selectionStart
      @undelegateEvents()
      super
      @delegateEvents()

    toJSON: ->
      _.extend super, {
        state: @state
        writeStates: ['add', 'edit']
      }
