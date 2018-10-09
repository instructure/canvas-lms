#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'Backbone'
  'jquery'
  '../../PaginatedCollectionView'
  './DateRangeSearchView'
  './AutocompleteView'
  '../../ValidatedMixin'
  './GradeChangeLoggingItemView'
  '../../../collections/GradeChangeLoggingCollection'
  '../../../collections/CourseCollection'
  'jst/accounts/admin_tools/gradeChangeLoggingContent'
  'jst/accounts/admin_tools/gradeChangeLoggingResults'
], (
  Backbone,
  $,
  PaginatedCollectionView,
  DateRangeSearchView,
  AutocompleteView,
  ValidatedMixin,
  GradeChangeLoggingItemView,
  GradeChangeLoggingCollection,
  CourseCollection,
  template,
  gradeChangeLoggingResultsTemplate
) ->
  class GradeChangeLoggingContentView extends Backbone.View
    @mixin ValidatedMixin

    @child 'resultsView', '#gradeChangeLoggingSearchResults'
    @child 'dateRangeSearch', '#gradeChangeDateRangeSearch'
    @child 'graderSearch', '#gradeChangeGraderSearch'
    @child 'studentSearch', '#gradeChangeStudentSearch'

    els:
      '#gradeChangeLoggingSearch': '$gradeChangeLogginSearch'
      '#gradeChangeLoggingForm': '$form'

    template: template

    constructor: (@options) ->
      @collection = new GradeChangeLoggingCollection
      super
      @dateRangeSearch = new DateRangeSearchView
        name: "gradeChangeLogging"
      @graderSearch = new AutocompleteView
        collection: @options.users
        fieldName: 'grader_id'
        placeholder: 'Grader'
      @studentSearch = new AutocompleteView
        collection: @options.users
        fieldName: 'student_id'
        placeholder: 'Student'
      @resultsView = new PaginatedCollectionView
        template: gradeChangeLoggingResultsTemplate
        itemView: GradeChangeLoggingItemView
        collection: @collection

    events:
      'submit #gradeChangeLoggingForm': 'onSubmit'

    onSubmit: (event) ->
      event.preventDefault()
      json = @$form.toJSON()
      if @validate(json)
        @updateCollection(json)

    updateCollection: (json) ->
      # Update the params (which fetches the collection)
      json ||= @$form.toJSON()

      params =
        id: null
        type: null
        start_time: ''
        end_time: ''

      params.start_time = json.start_time if json.start_time
      params.end_time = json.end_time if json.end_time

      if json.grader_id
        params.type = 'graders'
        params.id = json.grader_id

      if json.student_id
        params.type = 'students'
        params.id = json.student_id

      if json.course_id
        params.type = 'courses'
        params.id = json.course_id

      if json.assignment_id
        params.type = 'assignments'
        params.id = json.assignment_id

      @collection.setParams params

    validate: (json) ->
      json ||= @$form.toJSON()
      delete json.gradeChange_submit
      errors = @dateRangeSearch.validate(json) || {}
      if !json.course_id && !json.student_id && !json.grader_id && !json.assignment_id
        errors['gradeChange_submit'] = [{
          type: 'required'
          message: 'A valid Grader, Student, Course Id, or Assignment Id is required to search events.'
        }]
      @showErrors errors
      return $.isEmptyObject(errors)

    attach: ->
      @collection.on 'setParams', @fetch

    fetch: =>
      @collection.fetch(error: @onFail)

    onFail: (collection, xhr) =>
      # Received a 404, empty the collection and don't let the paginated
      # view try to fetch more.

      @collection.reset()
      @resultsView.detachScroll()
      @resultsView.$el.find(".paginatedLoadingIndicator").fadeOut()

      if xhr?.status? && xhr.status == 404
        type = @collection.options.params.type
        errors = {}

        if type == 'courses'
          errors['course_id'] = [{
            type: 'required'
            message: 'A course with that ID could not be found for this account.'
          }]

        if type == 'assignments'
          errors['assignment_id'] = [{
            type: 'required'
            message: 'An assignment with that ID could not be found for this account.'
          }]

        @showErrors errors unless $.isEmptyObject(errors)
