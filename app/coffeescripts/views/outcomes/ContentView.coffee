#
# Copyright (C) 2012 Instructure, Inc.
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

define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/Outcome'
  'compiled/models/OutcomeGroup'
  'compiled/views/outcomes/OutcomeView'
  'compiled/views/outcomes/OutcomeGroupView'
], ($, _, Backbone, Outcome, OutcomeGroup, OutcomeView, OutcomeGroupView) ->

  # This view is a wrapper for showing details for outcomes and groups.
  # It uses OutcomeView and OutcomeGroupView to render
  class ContentView extends Backbone.View

    initialize: ({@readOnly, @setQuizMastery, @useForScoring, @instructionsTemplate, @renderInstructions}) ->
      super
      @render()

    # accepts: Outcome and OutcomeGroup
    show: (model) =>
      return if model?.isNew()
      @_show model: model

    # accepts: Outcome and OutcomeGroup
    add: (model) =>
      @_show model: model, state: 'add'
      @trigger 'adding'
      @innerView.on 'addSuccess', (m) => @trigger 'addSuccess', m

    # private
    _show: (viewOpts) ->
      viewOpts = _.extend {}, viewOpts, {@readOnly, @setQuizMastery, @useForScoring}
      @innerView?.remove()
      @innerView =
        if viewOpts.model instanceof Outcome
          new OutcomeView viewOpts
        else if viewOpts.model instanceof OutcomeGroup
          new OutcomeGroupView viewOpts
      @render()

    render: ->
      @attachEvents()
      html = if @innerView
          @innerView.render().el
        else if @renderInstructions
          @instructionsTemplate()
      @$el.html html
      this

    attachEvents: ->
      return unless @innerView?
      @innerView.on 'deleteSuccess', => @trigger('deleteSuccess')

    remove: ->
      @innerView?.off 'addSuccess'
