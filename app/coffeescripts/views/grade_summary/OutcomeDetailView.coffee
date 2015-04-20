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

    @optionProperty 'user_id'
    @optionProperty 'course_id'

    dialogOptions: ->
      containerId: "outcome_detail"
      close: @onClose
      buttons: []
      width: 640

    show: (model) ->
      @model = model
      @$el.dialog('option', 'title', @model.group.get('title'))
      @progress = new ProgressBarView(model: @model)
      @render()
      super

    render: ->
      super
      @alignments = new OutcomeResultCollection([], user_id: @user_id, course_id: @course_id, outcome: @model)
      @alignments.fetch()
      @alignmentsView = new CollectionView
        el: @$('.alignments')
        collection: @alignments
        itemView: AlignmentView

    onClose: ->
      window.location.hash = 'tab-outcomes'

    toJSON: ->
      json = super
      _.extend json,
        progress: @progress
