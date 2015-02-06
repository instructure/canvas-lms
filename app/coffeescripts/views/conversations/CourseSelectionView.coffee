define [
  'i18n!conversations'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/conversations/SearchableSubmenuView'
  'jst/conversations/courseOptions'
  'jquery.instructure_date_and_time'
  'vendor/bootstrap/bootstrap-dropdown'
  'vendor/bootstrap-select/bootstrap-select'
], (I18n, $, _, {View, Collection}, SearchableSubmenuView, template) ->

  class CourseSelectionView extends View
    events:
      'change': 'onChange'

    initialize: () ->
      super
      if !@options.defaultOption then @options.defaultOption = I18n.t('all_courses', 'All Courses')
      @$el.addClass('show-tick')
      @$el.selectpicker(useSubmenus: true).next()
        .on('mouseover', @loadAll)
        .find('.dropdown-toggle').on('focus', @loadAll)
      @options.courses.favorites.on('reset', @render)
      @options.courses.all.on('reset', @render)
      @options.courses.all.on('add', @render)
      @options.courses.groups.on('reset', @render)
      @options.courses.groups.on('add', @render)
      @$picker = @$el.next()
      @render()

    render: () =>
      super()
      more = []
      concluded = []
      now = $.fudgeDateForProfileTimezone(new Date)
      @options.courses.all.each((course) =>
        if @options.courses.favorites.get(course.id) then return
        is_complete = course.get('workflow_state') == 'completed' ||
          (course.get('end_at') && new Date(course.get('end_at')) < now) ||
          (course.get('term').end_at && new Date(course.get('term').end_at) < now)
        collection = if is_complete then concluded else more
        collection.push(course.toJSON())
      )
      data =
        defaultOption: @options.defaultOption,
        favorites: @options.courses.favorites.toJSON(),
        more: more,
        concluded: concluded,
        groups: @options.courses.groups.toJSON()
      @truncate_course_name_data(data)
      @$el.html(template(data))
      @$el.selectpicker('refresh')
      @$picker.find('.paginatedLoadingIndicator').remove()
      @createSearchViews()
      if !@renderValue() then @loadAll()

    createSearchViews: ->
      searchViews = []
      @$picker.find('.dropdown-submenu').each ->
        searchViews.push(new SearchableSubmenuView(el: this))
      @searchViews = searchViews

    loadAll: () =>
      all = @options.courses.all
      if all._loading then return
      all.fetch()
      all._loading = true
      @options.courses.groups.fetch()
      @$picker.find('> .dropdown-menu').append($('<div />').attr('class', 'paginatedLoadingIndicator').css('clear', 'both'))

    _value: ''
    setValue: (value) ->
      @_value = value || ''
      @renderValue()
      @triggerEvent()

    renderValue: () ->
      @silenced = true
      @$el.selectpicker('val', @_value)
      @silenced = false
      return @$el.val() == @_value

    onChange: () ->
      return if @silenced
      @_value = @$el.val()
      @triggerEvent()
      @searchViews.forEach (view) ->
        view.clearSearch()

    getCurrentContext: ->
      matches = @_value.match(/(\w+)_(\d+)/)
      return {} unless matches
      [match, type, id] = matches
      context = if type == 'course'
        course = @options.courses.favorites.get(id) ||
          @options.courses.all.get(id)
      else
        @options.courses.groups.get(id)
      return if context then {name: context.get('name'), id: @_value} else {}

    triggerEvent: ->
      @trigger('course', @getCurrentContext())

    focus: ->
      @$el.next().find('.dropdown-toggle').focus()

    truncate_course_name_data: (course_data) ->
      _.each(['favorites', 'more', 'concluded', 'groups'], (key) =>
        @truncate_course_names(course_data[key])
        )

    truncate_course_names: (courses) ->
      _.each(courses, @truncate_course)

    truncate_course: (course) =>
      name = course['name']
      truncated = @middle_truncate(name)
      unless name == truncated
        course['truncated_name'] = truncated

    middle_truncate: (name) ->
      if name.length > 25
        name.slice(0, 10) + "…" + name.slice(-10)
      else
        name
