define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/grade_summary/Outcome'
  'compiled/collections/WrappedCollection'
  'compiled/views/DialogBaseView'
  'compiled/views/CollectionView'
  'compiled/views/grade_summary/AlignmentView'
  'compiled/views/grade_summary/ProgressBarView'
  'jst/grade_summary/outcome_detail'
], ($, _, Backbone, Outcome, WrappedCollection, DialogBaseView, CollectionView, AlignmentView, ProgressBarView, template) ->
  class OutcomeResultCollection extends WrappedCollection
    key: 'outcome_results'
    model: Outcome
    @optionProperty 'outcome'
    @optionProperty 'user_id'
    @optionProperty 'course_id'
    url: -> "/api/v1/courses/#{@course_id}/outcome_results?user_ids[]=#{@user_id}&outcome_ids[]=#{@outcome.id}&include[]=alignments"
    loadAll: true

    initialize: ->
      super
      @on('reset', @handleReset)
      @on('add', @handleAdd)

    handleReset: =>
      @alignments = new Backbone.Collection(@linked.alignments)
      @each @handleAdd

    handleAdd: (model) =>
      alignment_id = model.get('links').alignment
      model.set('name', @alignments.get(alignment_id).get('name'))
      model.set('mastery_points', @outcome.get('mastery_points'))
      model.set('points_possible', @outcome.get('points_possible'))

  class OutcomeDetailView extends DialogBaseView

    template: template

    @optionProperty 'user_id'
    @optionProperty 'course_id'

    dialogOptions: ->
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
