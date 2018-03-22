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
  '../../util/Popover'
  './OutcomeLineGraphView'
  'jst/outcomes/outcomePopover'
], (_, Backbone, Popover, OutcomeLineGraphView, template) ->
  class OutcomePopoverView extends Backbone.View
    TIMEOUT_LENGTH: 50

    @optionProperty 'el'
    @optionProperty 'model'

    events:
      'click i': 'mouseleave'
      'mouseenter i': 'mouseenter'
      'mouseleave i': 'mouseleave'
    inside: false

    initialize: ->
      super
      @outcomeLineGraphView = new OutcomeLineGraphView({
        model: @model
      })

    # Overrides
    render: ->
      template(@toJSON())

    # Instance methods
    closePopover: (e) ->
      e?.preventDefault()
      return true unless @popover?
      @popover.hide()
      delete @popover

    mouseenter: (e) =>
      @openPopover(e)
      @inside  = true

    mouseleave: (e) =>
      @inside  = false
      setTimeout =>
        return if @inside || !@popover
        @closePopover()
      , @TIMEOUT_LENGTH

    openPopover: (e) ->
      if @closePopover()
        @popover = new Popover(e, @render(), {
          verticalSide: 'bottom'
          manualOffset: 14
        })
      @outcomeLineGraphView.setElement(@popover.el.find("div.line-graph"))
      @outcomeLineGraphView.render()

