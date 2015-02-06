define [
  'Backbone'
  'jquery'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/accounts/admin_tools/DateRangeSearchView'
  'compiled/views/accounts/admin_tools/AutocompleteView'
  'compiled/views/ValidatedMixin'
  'compiled/views/accounts/admin_tools/GradeChangeLoggingItemView'
  'compiled/collections/GradeChangeLoggingCollection'
  'compiled/collections/CourseCollection'
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
