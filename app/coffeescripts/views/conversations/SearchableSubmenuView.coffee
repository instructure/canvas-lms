define [
  'str/htmlEscape'
  'i18n!conversations'
  'jquery'
  'underscore'
  'Backbone'
], (htmlEscape, I18n, $, _, {View}, CourseSelectionView, SearchView) ->
  class SearchableSubmenuView extends View
    initialize: ->
      super
      content_type = this.$el.children('[data-content-type]').data('content-type')
      @$field = $('<input />')
        .attr(
          'class': 'dropdown-search'
          type: 'search'
          placeholder: content_type
          'aria-label': I18n.t("Below this search field is a list of %{content_type}. As you type, the list will be filtered to match your query. Conversation messages will be filtered by whichever option you select.", {content_type: content_type})
        )
        .keyup(_.debounce(@search, 100))
        .keydown(@handleDownArrow)
      @$announce = $('<span class="screenreader-only" aria-live="polite"></span>')
      label = @getMenuRoot().text()
      $labelledField = $('<label>')
        .append(@$field)
        .append(@$announce)
      @$submenu = @$el.children('.dropdown-menu')
        .prepend($labelledField)
        .find('.inner').keydown(@handleUpArrow)
      @getMenuRoot().keydown(@handleRightArrow)
      @$contents = @$el.find('li')

    search: =>
      val = @$field.val().toLowerCase()
      if !val
        @$contents.show()
        @$contents.attr('aria-hidden', false)
      else
        @$contents.each ->
          $entry = $(this)
          $abbr = $entry.find('abbr')
          text = if $abbr.length then $abbr.attr('title') else $entry.find('span').text()
          isMatch = text.toLowerCase().indexOf(val) != -1
          if isMatch
            $entry.show()
            $entry.attr('aria-hidden', false)
          else
            $entry.hide()
            $entry.attr('aria-hidden', true)

      shown_count = @$contents.filter("[aria-hidden=false]").length
      result_message = I18n.t({one: "There is 1 result in the list", other: "There are %{count} results in the list"}, count: shown_count)
      @$announce.html(htmlEscape(result_message))

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
