define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/grade_summary/Outcome'
  'compiled/collections/WrappedCollection'
], ($, _, Backbone, Outcome, WrappedCollection) ->
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
      model.set('alignment_name', @alignments.get(alignment_id)?.get('name'))
      model.set('mastery_points', @outcome.get('mastery_points'))
      model.set('points_possible', @outcome.get('points_possible'))
