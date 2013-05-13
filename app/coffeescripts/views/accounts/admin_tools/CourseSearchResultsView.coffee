define [
  'underscore'
  'Backbone'
  'jquery'
  'jst/accounts/admin_tools/CourseSearchResults'
], (_, Backbone,$, template, I18n) -> 
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
    # restore a course when a search is happening. 
    enableResults: =>
      if @model.get('workflow_state') == 'deleted'
        @$el.find('button').prop 'disabled', false

    # Bindings are applied here to make testing a little easier. 
    # @api public
    applyBindings: -> 
      @model.on 'doneSearching', @enableResults
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


