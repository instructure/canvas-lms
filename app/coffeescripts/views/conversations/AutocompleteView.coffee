define [
  'i18n!conversations'
  'Backbone'
  'underscore'
  'jst/conversations/autocompleteToken'
  'jst/conversations/autocompleteResult'
], (I18n, {View}, _, tokenTemplate, resultTemplate) ->

  # Public: Helper method for capitalizing a string
  #
  # string - The string to capitalize.
  #
  # Returns a capitalized string.
  capitalize = (string) -> string.charAt(0).toUpperCase() + string.slice(1)

  class AutocompleteView extends View

    # Public: Limit selection to one result.
    @optionProperty('single')

    # Internal: Current result set from the server.
    collection: null

    # Internal: Current XMLHttpRequest (if any).
    currentRequest: null

    # Internal: Currently selected model.
    selectedModel: null

    course: null

    # Internal: Currently selected results.
    tokens: []

    # Internal: Construct the search URL for the given term.
    url: (term) ->
      url = "/api/v1/search/recipients/?search=#{term}&per_page=5"
      url += "&context=course_#{@course}" if @course
      url

    messages:
      noResults: I18n.t('no_results_found', 'No results found')

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
      '.ac-placeholder' : '$placeholder'
      '.ac-clear'       : '$clearBtn'

    # Internal: Event map.
    events:
      'blur      .ac-input'            : '_onInputBlur'
      'click     .ac-input-box'        : '_onWidgetClick'
      'click     .ac-clear'            : '_onClearTokens'
      'click     .ac-token-remove-btn' : '_onRemoveToken'
      'focus     .ac-input'            : '_onInputFocus'
      'input     .ac-input'            : '_onSearchTermChange'
      'keydown   .ac-input'            : '_onInputAction'
      'mousedown .ac-result'           : '_onResultClick'
      'mouseenter .ac-result-list'     : '_clearSelectedStyles'

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
      @$resultList.empty() if !isVisible
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
      #id = parseInt(id) if (id).match and !id.match(/_/)
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
      @$placeholder.css(opacity: 1) unless @tokens.length or @$input.val()
      @toggleResultList(false)

    # Internal: Set proper styles on widget when input is focused.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onInputFocus: (e) ->
      @$inputBox.addClass('focused')
      @$placeholder.css(opacity: 0)
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
      if searchResults.length
        @$resultList.html(resultElements.join(''))
        $el = @$resultList.find('li:first').addClass('selected')
        @selectedModel = @_getModel($el.data('id'))
        @$input.attr('aria-activedescendant', $el.attr('id'))
      else
        @$resultList.html( $('<li />', class: 'ac-result text-center').text(@messages.noResults) )

    # Internal: Fetch and display autocomplete results from the server.
    #
    # fetchIfEmpty - Fetch a result set, even if no query exists (default: false)
    #
    # Returns nothing.
    __fetchResults: (fetchIfEmpty = false) ->
      return unless @$input.val() or fetchIfEmpty
      @currentRequest?.abort()
      @currentRequest = $.getJSON(@url(@$input.val()), @_onSearchResultLoad)
      @toggleResultList(true, @currentRequest)

    # Internal: Delete the last token.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onBackspaceKey: (e) ->
      @_removeToken(_.last(@tokens)) if !@$input.val()

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
      @toggleResultList(false)
      setTimeout((=> @$input.focus()), 0)

    # Internal: Add the current @selectedModel to the list of tokens.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onEnterKey: (e) ->
      e.preventDefault() && e.stopPropagation()
      @_addToken(@selectedModel) if @selectedModel

    # Internal: Add the clicked model to the list of tokens.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onResultClick: (e) ->
      e.preventDefault() && e.stopPropagation()
      @_addToken(@_getModel($(e.currentTarget).data('id')))

    # Internal: Clear the current token.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onClearTokens: (e) ->
      e.preventDefault()
      @_removeToken(@tokens[0], false) while @tokens.length
      @$clearBtn.hide()
      @$input.prop('disabled', false).focus()
      # fire a single token change event
      @trigger('enabled')
      @trigger('changeToken', @tokenParams())

    # Internal: Handle clicks on token remove buttons.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onRemoveToken: (e) ->
      e.preventDefault()
      @_removeToken($(e.currentTarget).siblings('input').val())

    # Internal: Add the given model to the token list.
    #
    # model - Result model (user or course)
    #
    # Returns nothing.
    _addToken: (model) ->
      @tokens.push(model.id)
      @$tokenList.append(tokenTemplate(model))
      @toggleResultList(false)
      @selectedModel = null
      @$input.val('')
      if @options.single
        @$clearBtn.show().focus()
        @$input.prop('disabled', true)
        @trigger('disabled')
      @trigger('changeToken', @tokenParams())

    # Internal: Remove the given model from the token list.
    #
    # id - The ID of the result to remove from the token list.
    # silent - If true, don't fire a changeToken event (default: false).
    #
    # Returns nothing.
    _removeToken: (id, silent = false) ->
      @$tokenList.find("input[value=#{id}]").parent().remove()
      @tokens.splice(_.indexOf(id), 1)
      @$clearBtn.hide() unless @tokens.length
      if @options.single and !@tokens.length
        @$input.prop('disabled', false)
        @trigger('enabled')
      @trigger('changeToken', @tokenParams()) unless silent

    # Public: Return the current tokens as an array of params.
    #
    # Returns an array of context_id strings.
    tokenParams: ->
      _.map(@tokens, (t) -> if (t).match then t else "user_#{t}")

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

    setCourse: (course) ->
      return if course == @course
      @course = course
      @$input.attr('disabled', !course)
      @$inputBox.toggleClass('disabled', !course)
      @$tokenList.find('li.ac-token').remove()
