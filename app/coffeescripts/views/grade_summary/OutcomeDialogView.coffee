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
  'jquery'
  'underscore'
  '../DialogBaseView'
  './OutcomeLineGraphView'
  'jst/outcomes/outcomePopover'
], ($, _, DialogBaseView, OutcomeLineGraphView, template) ->
  class OutcomeResultsDialogView extends DialogBaseView
    @optionProperty 'model'
    $target: null
    template: template

    initialize: ->
      super
      @outcomeLineGraphView = new OutcomeLineGraphView({
        model: @model
      })

    afterRender: ->
      @outcomeLineGraphView.setElement(@$("div.line-graph"))
      @outcomeLineGraphView.render()

    dialogOptions: ->
      containerId: "outcome_results_dialog"
      close: @onClose
      buttons: []
      width: 460

    show: (e) ->
      return unless (e.type == "click" || @_getKey(e.keyCode))
      @$target = $(e.target)
      e.preventDefault()
      @$el.dialog('option', 'title', @model.get('title'))
      super
      @render()

    onClose: =>
      @$target.focus()
      delete @$target

    toJSON: ->
      json = super
      _.extend json,
        dialog: true

    # Private
    _getKey: (keycode) =>
      keys = {
        13 : "enter"
        32 : "spacebar"
      }
      keys[keycode]
