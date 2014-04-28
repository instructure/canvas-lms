define [
  'i18n!modules'
  'jquery'
  'underscore'
  'Backbone'
], (I18n, $, _, Backbone) ->
  class PostGradesModel extends Backbone.Model

    initialize: ->
      @ignored_assignment_ids = []
      window.model = @

    defaults: ->
      assignments: {}
      course_id: null

    assignment_list: ->
      _.values @get('assignments')

    assignments_to_post: ->
      assignments_to_ignore = (assignment) => _.contains(@ignored_assignment_ids, assignment.id)
      _.reject(@assignment_list(), assignments_to_ignore)


    assignment_count: ->
      _.size @get('assignments')

    update_bound_attributes: ->
      @set(assignments_to_post: @assignments_to_post())
      @set(missing_not_unique: @missing_and_not_unique().length - @ignored_assignment_ids.length)

    ignore_assignment: (id) ->
      @ignored_assignment_ids.push id
      @update_bound_attributes()

    ignore_all: ->
      @ignored_assignment_ids = _.map(@missing_and_not_unique(), (assignment) -> assignment.id)
      @update_bound_attributes()

    reset_ignored_assignments: ->
      @ignored_assignment_ids = []
      @update_bound_attributes()

    course_id: ->
      @get('gradebook').context_id

    section_id: ->
      @get('section_id')

    not_unique_assignments: ->
      duplicates = (assignment) -> assignment.length > 1
      add_not_unique_flag = (assignment) ->
        assignment['not_unique'] = true
        return assignment
      _.chain(@assignment_list()).groupBy("name").filter( duplicates ).flatten().map(add_not_unique_flag).value()

    missing_due_date: ->
      missing_dates = _.chain(@assignment_list()).filter( (assignment) -> return !assignment.due_at ).flatten().value()

    missing_and_not_unique: ->
      _.union(@not_unique_assignments(), @missing_due_date())

    ungraded_submissions: ->
      _.filter(@assignment_list(), (assignment) -> return assignment.needs_grading_count > 0)

    toJSON: ->


