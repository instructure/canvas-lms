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
  'jquery'
  'Backbone'
  'underscore'
  'i18n!content_migrations'
  '../../../util/natcompare'
  'jst/content_migrations/subviews/CourseFindSelect'
  'jst/courses/autocomplete_item'
  'jquery.ajaxJSON'
  'jquery.disableWhileLoading'
  'jqueryui/autocomplete'
], ($, Backbone, _, I18n, natcompare, template, autocompleteItemTemplate) ->
  class CourseFindSelectView extends Backbone.View
    @optionProperty 'current_user_id', 'show_select'
    template: template

    els:
      '#courseSearchField'   : '$courseSearchField'
      '#courseSelect'        : '$courseSelect'
      '#courseSelectWarning' : '$selectWarning'

    events:
      'change #courseSelect' : 'updateSearch'
      'change #include_completed_courses' : 'toggleConcludedCourses'

    render: ->
      super
      if @options.show_select
        dfd = @getManageableCourses()
        @$el.disableWhileLoading dfd
        dfd.done (data) =>
          @courses = data
          @coursesByTerms = _.chain(@courses)
            .groupBy((course) ->
              course.term
            ).map((value, key) ->
              {term: key, courses: value.sort(natcompare.byKey('label'))}
            ).sort((a, b) ->
              astart = a.courses[0].enrollment_start
              bstart = b.courses[0].enrollment_start
              val = 0
              if astart || bstart
                val = new Date(bstart) - new Date(astart)
              if val == 0
                val = natcompare.strings(a.term, b.term)
              val
            ).value()
          super

    afterRender: ->
      @$courseSearchField.autocomplete
        source: @manageableCourseUrl()
        select: @updateSelect
      @$courseSearchField.data('ui-autocomplete')._renderItem = (ul, item) ->
        $(autocompleteItemTemplate(item)).appendTo(ul)

      # Accessiblity Hack. If you find a better solution please fix this. This makes it so the whole form isn't read
      # by the screen reader every time a user selects an auto completed item.
      $converterDiv = $('#converter')
      @$courseSearchField.on 'focus', -> $converterDiv.attr('aria-atomic', false)
      @$courseSearchField.on 'blur', -> $converterDiv.attr('aria-atomic', true)
      @$courseSelect.on 'focus', -> $converterDiv.attr('aria-atomic', false)
      @$courseSelect.on 'blur', -> $converterDiv.attr('aria-atomic', true)
      ## hack finished ##

    toJSON: ->
      json = super
      json.terms = @coursesByTerms
      json.include_concluded = @includeConcludedCourses
      json.show_select = @options.show_select
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
      @$courseSelect.val ui.item.id if @$courseSelect.length

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
      if id == ENV.COURSE_ID?.toString()
        @$selectWarning.show()
      else
        @$selectWarning.hide()

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
          message: I18n.t("You must select a course to copy content from")
        ]
      errors
