define [
  'Backbone'
  'underscore'
  'jst/conversations/autocompleteToken'
  'jst/conversations/autocompleteResult'
], ({View}, _, tokenTemplate, resultTemplate) ->

  # Public: Helper method for capitalizing a string
  #
  # string - The string to capitalize.
  #
  # Returns a capitalized string.
  capitalize = (string) -> string.charAt(0).toUpperCase() + string.slice(1)

  class AutocompleteView extends View

    # Internal: Current result set from the server.
    collection: null

    # Internal: Current XMLHttpRequest (if any).
    currentRequest: null

    # Internal: Currently selected model.
    selectedModel: null

    # Internal: Construct the search URL for the given term.
    url: (term) -> "/api/v1/search/recipients/?search=#{term}&per_page=5"

    # Internal: Map of key names to codes.
    keys:
      8   : 'backspace'
      13  : 'enter'
      27  : 'escape'
      38  : 'up'
      40  : 'down'

    # Internal: Cached DOM element references.
    els:
      '.ac-input-box'   : '$inputBox'
      '.ac-input'       : '$input'
      '.ac-token-list'  : '$tokenList'
      '.ac-result-list' : '$resultList'

    # Internal: Event map.
    events:
      'blur      .ac-input'        : '_onInputBlur'
      'click     .ac-input-box'    : '_onWidgetClick'
      'focus     .ac-input'        : '_onInputFocus'
      'input     .ac-input'        : '_onSearchTermChange'
      'keydown   .ac-input'        : '_onInputAction'
      'mousedown .ac-result'       : '_onResultClick'
      'mouseenter .ac-result-list' : '_clearSelectedStyles'

    # Public: Create and configure a new instance.
    #
    # Returns an AutocompleteView instance.
    initialize: ->
      super
      @$span = @_initializeWidthSpan()
      @_fetchResults = _.debounce(@__fetchResults, 250)

    # Public: Toggle visibility of result list.
    #
    # isVisible - A boolean to determine if the list should be shown.
    # deferred - (optional) A deferred that, if given, will disable the list
    #            until it is resolved.
    #
    # Returns the result list jQuery object.
    toggleResultList: (isVisible, deferred) ->
      @$resultList.attr('aria-hidden', !isVisible)
      @$input.attr('aria-expanded', isVisible)
      @$resultList.toggle(isVisible)
      @$resultList.disableWhileLoading(deferred) if isVisible and deferred

    # Internal: Create a <span /> to track search term width.
    #
    # Returns a jQuery-wrapped <span />.
    _initializeWidthSpan: ->
      $('<span />').css(
        fontSize: '14px'
        position: 'absolute'
        top: '-9999px'
      ).appendTo('body')

    # Internal: Get the given model from the collection.
    #
    # id - The ID of the model to return.
    #
    # Returns a model object.
    _getModel: (id) ->
      _.find(@collection, (model) -> model.id == id)

    # Internal: Remove the "selected" class from result list items.
    #
    # e - Event object.
    #
    # Returns nothing.
    _clearSelectedStyles: (e) ->
      @$resultList.find('.selected').removeClass('selected')

    # Internal: Translate clicks anywhere into clicks on the input.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onWidgetClick: (e) ->
      @$input.focus()

    # Internal: Delegate special key presses to their handler (if any).
    #
    # e - Event object.
    #
    # Returns nothing.
    _onInputAction: (e) ->
      return unless key = @keys[e.keyCode]
      methodName = "_on#{capitalize(key)}Key"
      @[methodName].call(this, e) if typeof @[methodName] == 'function'

    # Internal: Remove focus styles on widget when input is blurred.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onInputBlur: (e) ->
      @$inputBox.removeClass('focused')
      @toggleResultList(false)

    # Internal: Set proper styles on widget when input is focused.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onInputFocus: (e) ->
      @$inputBox.addClass('focused')
      unless $(e.target).hasClass('ac-input')
        @$input[0].selectionStart = @$input.val().length

    # Internal: Fetch from server when the search term changes.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onSearchTermChange: (e) ->
      if !@$input.val() then @toggleResultList(false) else @_fetchResults()
      @$input.width(@$span.text(@$input.val()).width() + 15)

    # Internal: Display search results returned from the server.
    #
    # Returns nothing.
    _onSearchResultLoad: (searchResults) =>
      @collection     = searchResults
      @currentRequest = null
      resultElements  = _.map searchResults, (r) ->
        resultTemplate(_.extend({}, r, guid: $.guid++))
      if searchResults
        @$resultList.html(resultElements.join(''))
        $el = @$resultList.find('li:first').addClass('selected')
        @selectedModel = @_getModel($el.data('id'))
        @$input.attr('aria-activedescendant', $el.attr('id'))
      else
        @$resultList.html( $('<li />').text('There are no results matching your search.') )

    # Internal: Fetch and display autocomplete results from the server.
    #
    # Returns nothing.
    __fetchResults: ->
      return if !@$input.val()
      @currentRequest?.abort()
      @currentRequest = $.getJSON(@url(@$input.val()), @_onSearchResultLoad)
      @toggleResultList(true, @currentRequest)

    # Internal: Delete the last token.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onBackspaceKey: (e) ->
      if !@$input.val()
        @$tokenList.find('li.ac-token:last-child').remove()

    # Internal: Handle down-arrow events.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onDownKey: (e) ->
      e.preventDefault() && e.stopPropagation()
      @$resultList.find('li.selected:first').removeClass('selected')
      @selectedModel = if @selectedModel
        @collection[@collection.indexOf(@selectedModel) + 1] or @collection[0]
      else
        @collection[0]
      $el = @$resultList.find("[data-id=#{@selectedModel.id}]")
      @$input.attr('aria-activedescendant', $el.addClass('selected').attr('id'))

    # Internal: Close the result list without choosing an option.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onEscapeKey: (e) ->
      e.preventDefault() && e.stopPropagation()
      @toggleResultList(false) && @$input.focus()

    # Internal: Add the current @selectedModel to the list of tokens.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onEnterKey: (e) ->
      e.preventDefault() && e.stopPropagation()
      @toggleResultList(false)
      @$tokenList.append(tokenTemplate(@selectedModel))
      @selectedModel = null
      @$input.val('')

    # Internal: Add the clicked model to the list of tokens.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onResultClick: (e) ->
      e.preventDefault() && e.stopPropagation()
      @$tokenList.append(tokenTemplate(@_getModel($(e.currentTarget).data('id'))))
      @selectedModel = null
      @toggleResultList(false)
      @$input.val('')

    # Internal: Handle up-arrow events.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onUpKey: (e) ->
      e.preventDefault() && e.stopPropagation()
      @$resultList.find('li.selected:first').removeClass('selected')
      @selectedModel = if @selectedModel
        @collection[@collection.indexOf(@selectedModel) - 1] or @collection[@collection.length - 1]
      else
        @collection[@collection.length - 1]
      $el = @$resultList.find("[data-id=#{@selectedModel.id}]")
      @$input.attr('aria-activedescendant', $el.addClass('selected').attr('id'))
