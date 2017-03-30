define [
  'underscore'
  'Backbone'
  'jquery'
  'jst/accounts/admin_tools/CourseSearchResults',
  'i18n!course_search_results',
  'compiled/jquery.rails_flash_notifications'
], (_, Backbone, $, template, I18n) ->
  class CourseSearchResultsView extends Backbone.View
    template: template

    events:
      'click #restoreCourseBtn'  : 'restore'

    els:
      '#restoreCourseBtn'  : '$restoreCourseBtn'

    initialize: (options) ->
      super
      @applyBindings()

    # Disable the search results. This means you cannot
    # restore a course when a search is happening.
    disableResults: =>
      @$el.find('button').prop 'disabled', true

    # Enable the search results. This means you can now
    # restore a course when a search has completed.
    enableResults: =>
      if @model.get('workflow_state') == 'deleted'
        @$el.find('button').prop 'disabled', false

    resultsFound: =>
      @enableResults
      if not @model.get('id') and @model.get('status')
        $.screenReaderFlashMessage(I18n.t('Course not found'))
      else if @model.get('workflow_state') == 'deleted'
        $.screenReaderFlashMessage(I18n.t('Course found'))
      else
        $.screenReaderFlashMessage(I18n.t('Course found (not deleted)'))

    # Bindings are applied here to make testing a little easier.
    # @api public
    applyBindings: ->
      @model.on 'doneSearching', @resultsFound
      @model.on 'change', @render
      @model.on 'searching', =>
        @model.set 'restored', false
        @disableResults()

    # Restore just calls @model.restore and waits for the
    # deferred object to finish.
    # @api private
    restore: (event) ->
      event.preventDefault()

      dfd = @model.restore()
      @$el.disableWhileLoading dfd

    # Depending on what we get back when restoring the model
    # we want to display the course or error message correctly.
    toJSON: (json) ->
      json = super
      json.showRestore = @model.get('id') and @model.get('workflow_state') == 'deleted'
      json.showNotFound = not @model.get('id') and @model.get('status')
      json.showSuccessfullRestore = @model.get('id') and @model.get('workflow_state') != 'deleted' and @model.get 'restored'
      json.showNonDeletedCourse = @model.get('id') and @model.get('workflow_state') != 'deleted' and !@model.get 'restored'
      json.enrollmentCount = @model.get('enrollments').length if @model.get('enrollments')
      json


