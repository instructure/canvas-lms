define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/grade_summary/Outcome'
  'compiled/collections/OutcomeResultCollection'
  'compiled/views/DialogBaseView'
  'compiled/views/CollectionView'
  'compiled/views/grade_summary/AlignmentView'
  'compiled/views/grade_summary/ProgressBarView'
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
        @alignmentsForView.reset(@allAlignments.last(8))

      @allAlignments.fetch()

    show: (model) ->
      @model = model
      @$el.dialog('option', 'title', @model.group.get('title'))
      @progress = new ProgressBarView(model: @model)
      @render()
      super

    toJSON: ->
      json = super
      _.extend json,
        progress: @progress

