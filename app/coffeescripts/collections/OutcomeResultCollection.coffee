define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/grade_summary/Outcome'
  'compiled/collections/WrappedCollection'
], ($, _, Backbone, Outcome, WrappedCollection) ->
  class OutcomeResultCollection extends WrappedCollection
    comparator: 'submitted_or_assessed_at'
    key: 'outcome_results'
    model: Outcome
    @optionProperty 'outcome'
    url: -> "/api/v1/courses/#{@course_id}/outcome_results?user_ids[]=#{@user_id}&outcome_ids[]=#{@outcome.id}&include[]=alignments"
    loadAll: true

    initialize: ->
      super
      @course_id = ENV.context_asset_string?.replace('course_', '')
      @user_id = ENV.student_id
      @on('reset', @handleReset)
      @on('add', @handleAdd)

    handleReset: =>
      @each @handleAdd

    handleAdd: (model) =>
      alignment_id = model.get('links').alignment
      model.set('alignment_name', @alignments.get(alignment_id)?.get('name'))
      model.set('mastery_points', @outcome.get('mastery_points'))
      model.set('points_possible', @outcome.get('points_possible'))

    parse: (response) ->
      @alignments ?= new Backbone.Collection([])
      @alignments.add(response?.linked?.alignments || [])
      response[@key]
