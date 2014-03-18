define [
  'jquery'
  'Backbone'
  'underscore'
  'jst/content_migrations/subviews/CourseFindSelect'
  'jst/courses/autocomplete_item'
  'jquery.ajaxJSON'
  'jquery.disableWhileLoading'
], ($, Backbone, _, template, autocompleteItemTemplate) ->
  class CourseFindSelectView extends Backbone.View
    @optionProperty 'current_user_id'
    template: template

    els: 
      '#courseSearchField'   : '$courseSearchField'
      '#courseSelect'        : '$courseSelect'

    events: 
      'change #courseSelect' : 'updateSearch'
      'change #include_completed_courses' : 'toggleConcludedCourses'

    render: ->
      super
      dfd = @getManageableCourses()
      @$el.disableWhileLoading dfd
      dfd.done (data) =>
        @courses = data
        @coursesByTerms = _.groupBy data, (course) -> course.term
        super

    afterRender: ->
      @$courseSearchField.autocomplete 
        source: @manageableCourseUrl()
        select: @updateSelect
      @$courseSearchField.data('ui-autocomplete')._renderItem = (ul, item) ->
        $(autocompleteItemTemplate(item)).appendTo(ul)

    toJSON: -> 
      json = super
      json.terms = @coursesByTerms
      json.include_concluded = @includeConcludedCourses
      json

    # Grab a list of courses from the server via the managebleCourseUrl. Disable
    # this view and re-render.
    # @api private

    getManageableCourses: ->
      dfd = $.ajaxJSON @manageableCourseUrl(), 'GET', {}, {}, {}, {}
      @$el.disableWhileLoading dfd
      dfd

    # Turn on a param that lets this view know to filter terms with concluded
    # courses. Also, automatically update the dropdown menu with items 
    # that include concluded courses.

    toggleConcludedCourses: ->
      @includeConcludedCourses = if @includeConcludedCourses then false else true
      @$courseSearchField.autocomplete 'option', 'source', @manageableCourseUrl()
      @render()

    # Generate a url from the current_user_id that is used to find courses
    # that this user can manage. jQuery autocomplete will add the param
    # "term=typed in stuff" automagically so we don't have to worry about
    # refining the search term

    manageableCourseUrl: ->
      params = $.param "include[]": 'concluded' if @includeConcludedCourses
      if params
        "/users/#{@current_user_id}/manageable_courses?#{params}"
      else
        "/users/#{@current_user_id}/manageable_courses"

    # Build a list of courses that our template and autocomplete can use
    # objects look like
    #   {label: 'Plant Science', value: 'Plant Science', id: '42'}
    # @api private

    autocompleteCourses: ->
      _.map @courses, (course) -> 
        {label: course.label, id: course.id, value: course.label}

    # After finding a course by searching via autocomplete, update the 
    # select menu to keep both input fields in sync. Also sets the 
    # source course id
    # @input (jqueryEvent, uiObj)
    # @api private

    updateSelect: (event, ui) => 
      @setSourceCourseId ui.item.id
      @$courseSelect.val ui.item.id

    # After selecting a course via the dropdown menu, update the search
    # field to keep the inputs in sync. Also set the source course id
    # @input jqueryEvent
    # @api private

    updateSearch: (event) => 
      value = event.target.value && String(event.target.value)
      @setSourceCourseId value

      courses = @autocompleteCourses()
      courseObj = _.find courses, (course) => course.id == value
      @$courseSearchField.val courseObj?.value

    # Given an id, set the source_course_id on the backbone model.
    # @input int
    # @api private

    setSourceCourseId: (id) ->
      @model.set('settings', {source_course_id: id})
      if course = _.find(@courses, (c) -> c.id == id)
        @trigger 'course_changed', course

    # Validates this form element. This validates method is a convention used 
    # for all sub views.
    # ie:
    #   error_object = {fieldName:[{type:'required', message: 'This is wrong'}]}
    # -----------------------------------------------------------------------
    # @expects void
    # @returns void | object (error)
    # @api private

    validations: -> 
      errors = {}
      settings = @model.get('settings')

      unless settings?.source_course_id
        errors.courseSearchField = [
          type: "required"
          message: "You must select a course to copy content from"
        ]

      errors
