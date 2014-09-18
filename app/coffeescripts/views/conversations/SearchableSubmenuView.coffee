define [
  'i18n!conversations'
  'jquery'
  'underscore'
  'Backbone'
], (I18n, $, _, {View}, CourseSelectionView, SearchView) ->
  class SearchableSubmenuView extends View
    initialize: ->
      super
      @$field = $('<input />')
        .attr(
          'class': 'dropdown-search'
          type: 'search'
          placeholder: I18n.t('course_name', 'Course name')
        )
        .keyup(_.debounce(@search, 100))
        .keydown(@handleDownArrow)
      label = @getMenuRoot().text()
      $labelledField = $('<label>')
        .append(@$field)
      @$submenu = @$el.children('.dropdown-menu')
        .prepend($labelledField)
        .find('.inner').keydown(@handleUpArrow)
      @getMenuRoot().keydown(@handleRightArrow)
      @$contents = @$el.find('li')

    search: =>
      val = @$field.val().toLowerCase()
      if !val
        @$contents.show()
        return
      @$contents.each ->
        $entry = $(this)
        $abbr = $entry.find('abbr')
        text = if $abbr.length then $abbr.attr('title') else $entry.find('span').text()
        isMatch = text.toLowerCase().indexOf(val) != -1
        $entry[if isMatch then 'show' else 'hide']()

    clearSearch: ->
      @$field.val('')
      @search()

    getFirstEntry: ->
      @$submenu.find('li:not(.divider):visible > a').first()

    getMenuRoot: ->
      @$el.children('[role=menuitem]')

    handleDownArrow: (e) =>
      return if e.keyCode != 40
      e.preventDefault()
      @getFirstEntry().focus()

    handleUpArrow: (e) =>
      return if e.keyCode != 38
      return if e.target != @getFirstEntry()[0]
      e.stopPropagation()
      @$field.focus()

    handleRightArrow: (e) =>
      return if e.keyCode != 39
      e.stopPropagation()
      @$field.focus()
