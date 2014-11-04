define [
  'i18n!modules'
  'jquery'
  'underscore'
  'Backbone'
], (I18n, $, _, Backbone) ->
  class PostGradesModel extends Backbone.Model

    initialize: ->
      @ignored_assignment_ids = []

    defaults: ->
      assignments: {}
      course_id: null
      integration_course_id: null
      integration_section_id: null

    assignment_list: ->
      _.values @get('assignments')

    assignments_to_post: ->
      assignments_to_ignore = (assignment) => _.contains(@ignored_assignment_ids, assignment.id)
      _.reject(@assignment_list(), assignments_to_ignore)

    assignment_count: ->
      _.size @get('assignments')

    update_assignment: (id, attrs) ->
      assignment = @get('assignments')[id]
      assignment.modified = true
      _.extend(assignment, attrs)
      @update_bound_attributes()

    modified_assignments: ->
      _.filter(@get('assignments'), (assignment) -> assignment.modified? )

    assignments_with_errors_count: ->
      @missing_and_not_unique().length - @ignored_assignment_ids.length

    update_bound_attributes: ->
      @set(assignments_to_post: @assignments_to_post())
      @set(assignments_with_errors: @missing_and_not_unique())
      @set(assignments_with_errors_count: @assignments_with_errors_count())

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
      @get('course_id')

    integration_course_id: ->
      @get('integration_course_id')

    integration_section_id: ->
      @get('integration_section_id')

    not_unique_assignments: ->
      duplicates = (assignment) -> assignment.length > 1
      add_not_unique_flag = (assignment) ->
        return _.extend({}, assignment, {'not_unique': true})
      _.chain(@assignment_list()).groupBy("name").filter( duplicates ).flatten().map(add_not_unique_flag).value()

    missing_due_date: ->
      missing_dates = _.chain(@assignment_list()).filter( (assignment) -> return !assignment.due_at ).flatten().value()

    missing_and_not_unique: ->
      get_id = (assignment) -> assignment.id
      missing_ids = _.map(@missing_due_date(), get_id)
      augmented_assignments = _.union(@not_unique_assignments(), @missing_due_date())
      not_unique_ids = _.map(@not_unique_assignments(), get_id)
      missing_and_not_unique_ids = _.union(missing_ids, not_unique_ids).sort()
      find_assignment_by_id = (id) => _.find(augmented_assignments, (assignment) -> id == assignment.id)
      _.map(missing_and_not_unique_ids, find_assignment_by_id)

    ungraded_submissions: ->
      _.filter(@assignment_list(), (assignment) -> return assignment.needs_grading_count > 0)


