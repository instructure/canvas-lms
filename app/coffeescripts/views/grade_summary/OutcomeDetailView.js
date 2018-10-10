#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'Backbone'
  '../../models/grade_summary/Outcome'
  '../../collections/OutcomeResultCollection'
  '../DialogBaseView'
  '../CollectionView'
  './AlignmentView'
  './ProgressBarView'
  'jst/grade_summary/outcome_detail'
], ($, _, Backbone, Outcome, OutcomeResultCollection, DialogBaseView, CollectionView, AlignmentView, ProgressBarView, template) ->
  class OutcomeDetailView extends DialogBaseView

    template: template

    dialogOptions: ->
      containerId: "outcome_detail"
      close: @onClose
      buttons: []
      width: 640

    initialize: ->
      @alignmentsForView = new Backbone.Collection([])
      @alignmentsView = new CollectionView
        collection: @alignmentsForView
        itemView: AlignmentView
      super

    onClose: ->
      window.location.hash = 'tab-outcomes'

    render: ->
      super
      @alignmentsView.setElement @$('.alignments')
      @allAlignments = new OutcomeResultCollection([], {
        outcome: @model
      })

      @allAlignments.on 'fetched:last', =>
        @alignmentsForView.reset(@allAlignments.toArray())

      @allAlignments.fetch()

    show: (model) ->
      @model = model
      @$el.dialog('option', 'title', @model.group.get('title')).css('maxHeight', 340)
      @progress = new ProgressBarView(model: @model)
      @render()
      super

    toJSON: ->
      json = super
      _.extend json,
        progress: @progress

