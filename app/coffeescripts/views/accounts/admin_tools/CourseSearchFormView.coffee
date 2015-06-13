define [
  'Backbone'
  'jquery'
  'jst/accounts/admin_tools/CourseSearchForm'
  'i18n!course_search'
  'jquery.instructure_forms'
], (Backbone,$, template, I18n) -> 
  class CourseSearchFormView extends Backbone.View
    tagName: 'form'

    template: template

    events:
      'submit': 'search'
   
    els:
      '#courseSearchField': '$courseSearchField'

    initialize: ->
      super
      @model.on 'restoring', @disableSearchForm
      @model.on 'doneRestoring', @enableSearchForm
   
    # Validates to make sure the query wasn't empty. Shows 
    # an error if its empty. If not, continues with the 
    # search. @model.search returns a deferred object 
    # that is used while loading.
    #
    # @api private
    search: (event) ->
      event.preventDefault()

      query = $.trim(@$courseSearchField.val())
      if query is ''
        @$courseSearchField.errorBox(I18n.t('cant_be_blank', "Can't be blank"))
      else
        dfd = @model.search($.trim(query))
        @$el.disableWhileLoading dfd

    # Re-render the search form in a disabled state.
    # @api private
    disableSearchForm: =>
      @$el.find(':input').prop 'disabled', true

    # Re-render the search form in a enabled state. 
    # @api private
    enableSearchForm: => 
      @$el.find(':input').prop 'disabled', false

    toJSON: (json) -> 
      json = super
      json.formDisabled = @disabled
      json

