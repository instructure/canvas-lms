define [
  'i18n!conversations'
  'Backbone'
  'jquery'
  'underscore'
  'compiled/collections/PaginatedCollection'
  'compiled/models/ConversationSearchResult'
  'compiled/views/PaginatedCollectionView'
  'jst/conversations/autocompleteToken'
  'jst/conversations/autocompleteResult'
], (I18n, Backbone, $, _, PaginatedCollection, ConversationSearchResult, PaginatedCollectionView, tokenTemplate, resultTemplate) ->

  # Public: Helper method for capitalizing a string
  #
  # string - The string to capitalize.
  #
  # Returns a capitalized string.
  capitalize = (string) -> string.charAt(0).toUpperCase() + string.slice(1)

  class AutocompleteView extends Backbone.View

    # Public: Limit selection to one result.
    @optionProperty('single')

    # Public: If true, don't display "All in ..." results.
    @optionProperty('excludeAll')

    # Internal: Current result set from the server.
    collection: null

    # Internal: Current XMLHttpRequest (if any).
    currentRequest: null

    # Internal: Current context to filter searches by.
    currentContext: null

    # Internal: Parent of the current context.
    parentContexts: []

    # Internal: Currently selected model.
    selectedModel: null

    # Internal: Currently selected results.
    tokens: []

    # Internal: A cache of per-context permissions.
    permissions: {}

    # Internal: A cache of URL results.
    cache: {}

    # Internal: Construct the search URL for the given term.
    url: (term) ->
      baseURL = '/api/v1/search/recipients?'
      params = { search: term, per_page: 20, 'permissions[]': 'send_messages_all', synthetic_contexts: true }
      params.context = @currentContext.id if @currentContext

      baseURL + _.reduce(params, (queryString, v, k) ->
        queryString.push("#{k}=#{v}")
        queryString
      , []).join('&')

    messages:
      noResults: I18n.t('no_results_found', 'No results found')
      back: I18n.t('back', 'Back')
      everyone: (context) ->
        I18n.t('all_in_context', 'All in %{context}', context: context)
      private:
        I18n.t('cannot_add_to_private', 'You cannot add participants to a private conversation.')

    # Internal: Map of key names to codes.
    keys:
      8   : 'backspace'
      13  : 'enter'
      27  : 'escape'
      38  : 'up'
      40  : 'down'

    # Internal: Cached DOM element references.
    els:
      '.ac-input-box'       : '$inputBox'
      '.ac-input'           : '$input'
      '.ac-token-list'      : '$tokenList'
      '.ac-result-wrapper'  : '$resultWrapper'
      '.ac-result-container': '$resultContainer'
      '.ac-result-contents' : '$resultContents'
      '.ac-result-list'     : '$resultList'
      '.ac-placeholder'     : '$placeholder'
      '.ac-clear'           : '$clearBtn'
      '.ac-search-btn'      : '$searchBtn'

    # Internal: Event map.
    events:
      'blur      .ac-input'            : '_onInputBlur'
      'click     .ac-input-box'        : '_onWidgetClick'
      'click     .ac-clear'            : '_onClearTokens'
      'click     .ac-token-remove-btn' : '_onRemoveToken'
      'click     .ac-search-btn'       : '_onSearch'
      'keyclick  .ac-search-btn'       : '_onSearch'
      'focus     .ac-input'            : '_onInputFocus'
      'input     .ac-input'            : '_onSearchTermChange'
      'keydown   .ac-input'            : '_onInputAction'
      'mousedown .ac-result'           : '_onResultClick'
      'mouseenter .ac-result-list'     : '_clearSelectedStyles'

    # Public: Create and configure a new instance.
    #
    # Returns an AutocompleteView instance.
    initialize: () ->
      super
      @render() # to initialize els
      @$span = @_initializeWidthSpan()
      setTimeout((=> @_disable() if @options.disabled), 0)
      @_fetchResults = _.debounce(@__fetchResults, 250)
      @resultCollection = new PaginatedCollection([], model: ConversationSearchResult)
      @resultView = new PaginatedCollectionView
        el: @$resultContents
        scrollContainer: @$resultContainer
        buffer: 50
        collection: @resultCollection
        template: null
        itemView: Backbone.View.extend
          template: resultTemplate
        itemViewOptions:
          tagName: 'li'
          attributes: ->
            classes = ['ac-result']
            classes.push('context') if @model.get('isContext')
            classes.push('back') if @model.get('back')
            classes.push('everyone') if @model.get('everyone')
            attributes =
              class: classes.join(' ')
              'data-id': @model.id
              'data-people-count': @model.get('user_count')
              id: "result-#{$.guid++}" # for aria-activedescendant
            attributes['aria-haspopup'] = @model.get('isContext')
            attributes
      @_attachCollection()

    # Internal: Manage events on the results collection.
    #
    # Returns nothing.
    _attachCollection: ->
      @resultCollection.off('reset',  @resultView.renderOnReset)
      @resultCollection.off('remove', @resultView.removeItem)

    # Public: Toggle visibility of result list.
    #
    # isVisible - A boolean to determine if the list should be shown.
    #
    # Returns the result list jQuery object.
    toggleResultList: (isVisible) ->
      @$resultWrapper.attr('aria-hidden', !isVisible)
      @$resultWrapper.toggle(isVisible)
      @$input.attr('aria-expanded', isVisible)
      @$resultList.empty() if !isVisible

    # Internal: Disable the autocomplete input.
    #
    # Returns nothing.
    _disable: ->
      @disable()
      @$inputBox.attr('title', @messages.private)
      @$inputBox.attr('data-tooltip', '{"position":"bottom"}')
      @disabled = true

    # Internal: Empty the current and parent contexts.
    #
    # Returns nothing.
    _resetContext: ->
      if @hasExternalContext
        @currentContext = if _.isEmpty(@parentContexts)
          @currentContext
        else
          _.head(@parentContexts)
      else
        @currentContext = null
      @parentContexts = []

    # Internal: Create a <span /> to track search term width.
    #
    # Returns a jQuery-wrapped <span />.
    _initializeWidthSpan: ->
      $('<span />').css(
        fontSize: '14px'
        position: 'absolute'
        top: '-9999px'
      ).appendTo('body')

    modelCache: new Backbone.Collection()

    # Internal: Add the given model to the cache.
    #
    # This is necessary because previously selected
    # tokens may not be present in the collection.
    _addToModelCache: (model) =>
      @modelCache.add(model)

    # Internal: Get the given model from the collection.
    #
    # id - The ID of the model to return.
    #
    # Returns a model object.
    _getModel: (id) =>
      id = id && String(id)
      result = @modelCache.get(id)

    # Internal: Remove the "selected" class from result list items.
    #
    # e - Event object.
    #
    # Returns nothing.
    _clearSelectedStyles: (e) ->
      @$resultList.find('.selected').removeClass('selected')
      @selectedModel = null

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
      @_resetContext()
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
      @resultView.collection.each((m) => @resultView.removeItem(m))

    # Internal: Display search results returned from the server.
    #
    # searchResults - An array of results from the server.
    #
    # Returns nothing.
    _onSearchResultLoad: =>
      @cache[@currentUrl] = @resultCollection.toJSON()
      _.extend(@permissions, @_getPermissions())
      @_addEveryoneResult(@resultCollection) unless @excludeAll or !@_canSendToAll()
      @resultCollection.each @_addToModelCache
      shouldDrawResults = @resultCollection.length
      isFinished        = !@nextRequest
      @_addBackResult(@resultCollection)
      @currentRequest = null
      if shouldDrawResults and isFinished
        @_drawResults()
      else if isFinished
        @resultCollection.push(new ConversationSearchResult({id: 'no_results', name: '', noResults: true}))
      @_fetchResults(true) if @nextRequest

    # Internal: Determine if the current user can send to all users in the course.
    #
    # Returns a boolean.
    _canSendToAll: ->
      return false unless @currentContext
      key = @currentContext.id.replace(/_(students|teachers)$/, '')
      @permissions[key]

    # Internal: Return permissions hashes from the current results.
    #
    # Returns a hash.
    _getPermissions: ->
      permissions = @resultCollection.filter((r) -> r.attributes.hasOwnProperty('permissions'))
      _.reduce permissions, (map, result) ->
        key = result.id.replace(/_(students|teachers)$/, '')
        map[key] = !!result.get('permissions').send_messages_all
        map
      , {}

    # Internal: Add, if appropriate, an "All in %{context}" result to the
    #           search results.
    #
    # results - A search results array to mutate.
    #
    # Returns a new search results array.
    _addEveryoneResult: (results) ->
      return unless @currentContext
      name       = @messages.everyone(@currentContext.name)
      searchTerm = new RegExp(@$input.val().trim(), 'gi')
      return results if (searchTerm and !name.match(searchTerm)) or (!results.length and !@currentContext)

      return if @currentContext.id.match(/course_\d+_(group|section)/)

      tag =
        id:       @currentContext.id
        name:     name
        everyone: true
        people: @currentContext.peopleCount
      results.unshift(new ConversationSearchResult(tag))

    # Internal: Add, if appropriate, an "All in %{context}" result to the
    #           search results.
    #
    # results - A search results array to mutate.
    #
    # Returns a new search results array.
    _addBackResult: (results) ->
      return results unless @parentContexts.length
      tag = { id: 'back', name: @messages.back, back: true, isContext: true }
      back = new ConversationSearchResult(tag)
      results.unshift(back)
      @_addToModelCache(back)

    # Internal: Draw out search results to the DOM.
    #
    # Returns nothing.
    _drawResults: ->
      @resultView.empty = !@resultView.collection.length
      @resultView.$('.collectionViewItems').empty()
      @resultView.render()
      $el = @$resultList.find('li:first').addClass('selected')
      @selectedModel = @_getModel($el.data('id'))
      @$input.attr('aria-activedescendant', $el.attr('id'))

    # Internal: Fetch and display autocomplete results from the server.
    #
    # fetchIfEmpty - Fetch a result set, even if no query exists (default: false)
    #
    # Returns nothing.
    __fetchResults: (fetchIfEmpty = false) ->
      return unless @$input.val() or fetchIfEmpty
      url = @_loadURL()
      return unless url
      @currentUrl = url
      if @cache[url]
        @resultCollection.reset(@cache[url])
        @toggleResultList(true)
        @_onSearchResultLoad()
      else
        @currentRequest = @resultCollection.fetch
          url: @url(@$input.val())
          success: @_onSearchResultLoad
        @toggleResultList(true)

    # Internal: Get URL for the current request, caching it as
    #   @nextRequest if needed.
    #
    # Returns a URL string (will be empty if current request is pending).
    _loadURL: ->
      searchURL = @url(@$input.val())
      if @currentRequest
        @nextRequest = searchURL
        ''
      else
        previousNextRequest = @nextRequest
        delete @nextRequest
        previousNextRequest or searchURL

    # Internal: Delete the last token.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onBackspaceKey: (e) ->
      @_removeToken(_.last(@tokens)) if !@$input.val()

    # Internal: Close the result list without choosing an option.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onEscapeKey: (e) ->
      e.preventDefault() && e.stopPropagation()
      @toggleResultList(false)
      @_resetContext()
      setTimeout((=> @$input.focus()), 0)

    # Internal: Add the current @selectedModel to the list of tokens.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onEnterKey: (e) ->
      e.preventDefault() && e.stopPropagation()
      @_activateSelected(e.metaKey or e.ctrlKey)

    _activateSelected: (keepOpen = false) ->
      return if !@selectedModel || @selectedModel.get('noResults')
      if @selectedModel.get('back')
        @currentContext = @parentContexts.pop()
        @_fetchResults(true)
      else if @selectedModel.get('isContext')
        @parentContexts.push(@currentContext)
        @$input.val('')
        @currentContext =
          id: @selectedModel.id
          name: @selectedModel.get('name')
          peopleCount: @selectedModel.get('user_count')
        @_fetchResults(true)
      else
        @_addToken(@selectedModel.attributes, keepOpen)

    # Internal: Handle down-arrow events.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onDownKey: (e) ->
      @_onArrowKey(e, 1)

    # Internal: Handle up-arrow events.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onUpKey: (e) ->
      @_onArrowKey(e, -1)

    # Internal: Move the current selection based on arrow key
    #
    # e - Event object
    # inc - The increment to the current selection index. -1 = up, +1 = down
    #
    # Returns nothing.
    _onArrowKey: (e, inc) ->
      e.preventDefault() && e.stopPropagation()
      @$resultList.find('li.selected:first').removeClass('selected')

      currentIndex = if @selectedModel then @resultCollection.indexOf(@selectedModel) else -1
      newIndex = currentIndex + inc
      newIndex = 0 if newIndex < 0
      newIndex = @resultCollection.length - 1 if newIndex >= @resultCollection.length

      @selectedModel = @resultCollection.at(newIndex)
      $el = @$resultList.find("[data-id=#{@selectedModel.id}]")
      $el.scrollIntoView()
      @$input.attr('aria-activedescendant', $el.addClass('selected').attr('id'))

    # Internal: Add the clicked model to the list of tokens.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onResultClick: (e) ->
      return unless e.button == 0
      e.preventDefault() && e.stopPropagation()
      $target = $(e.currentTarget)
      @selectedModel = @resultCollection.get($target.data('id'))
      @_activateSelected(e.metaKey or e.ctrlKey)

    # Internal: Clear the current token.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onClearTokens: (e) ->
      e.preventDefault()
      @_removeToken(@tokens[0], false) while @tokens.length
      @$clearBtn.hide()
      @$input.prop('disabled', false).focus() unless @disabled
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

    # Internal: Handle clicks to the search button.
    #
    # e - Event object.
    #
    # Returns nothing.
    _onSearch: (e) ->
      return if @$searchBtn.attr('disabled')
      @_fetchResults(true)
      @$input.focus()

    # Internal: Add the given model to the token list.
    #
    # model - Result model (user or course)
    #
    # Returns nothing.
    _addToken: (model, keepOpen = false) =>
      return if @disabled
      model.name = @_formatTokenName(model)
      @tokens.push(model.id)
      @$tokenList.append(tokenTemplate(model))
      unless keepOpen
        @toggleResultList(false)
        @selectedModel = null
        @_resetContext()
      @$input.val('')
      if @options.single
        @$clearBtn.show().focus()
        @$input.prop('disabled', true)
        @$searchBtn.prop('disabled', true)
        @trigger('disabled')
      @trigger('changeToken', @tokenParams())

    # Internal: Prepares a given model's name for display.
    #
    # model - A ConversationSearchResult model's attributes.
    #
    # Returns a formatted name.
    _formatTokenName: (model) ->
      return model.name unless model.everyone
      if parent = _.head(@parentContexts)
        "#{parent.name}: #{@currentContext.name}"
      else
        @currentContext.name

    # Internal: Remove the given model from the token list.
    #
    # id - The ID of the result to remove from the token list.
    # silent - If true, don't fire a changeToken event (default: false).
    #
    # Returns nothing.
    _removeToken: (id, silent = false) ->
      return if @disabled
      @$tokenList.find("input[value=#{id}]").parent().remove()
      @tokens.splice(_.indexOf(id), 1)
      @$clearBtn.hide() unless @tokens.length
      if @options.single and !@tokens.length
        @$input.prop('disabled', false)
        @$searchBtn.prop('disabled', false)
        @trigger('enabled')
      @trigger('changeToken', @tokenParams()) unless silent

    # Public: Return the current tokens as an array of params.
    #
    # Returns an array of context_id strings.
    tokenParams: ->
      _.map(@tokens, (t) -> if (t).match then t else "user_#{t}")

    # Public: Get the currently selected models.
    #
    # Returns an array of models.
    tokenModels: ->
      _.map(@tokens, @_getModel)

    # Public: Set the current course context.
    #
    # context - A context string, e.g. "course_123"
    # disable - Disable the input if no context is given (default: false).
    #
    # Returns nothing.
    setContext: (context, disable = false) ->
      context = null unless context.id
      if disable and !_.include(ENV.current_user_roles, 'admin') and !@disabled
        @disable(!context)
      return if context?.id == @currentContext?.id
      @currentContext     = context
      @hasExternalContext = !!context
      @tokens             = []
      @$tokenList.find('li.ac-token').remove()

    disable: (value = true) ->
      @$input.prop('disabled', value)
      @$searchBtn.prop('disabled', value)
      @$inputBox.toggleClass('disabled', value)

    # Public: Put the given tokens in the token list.
    #
    # tokens - Array of Result model object (course or user)
    #
    # Returns nothing.
    setTokens: (tokens) ->
      _.each tokens, (token) =>
        @_addToModelCache(token)
        @_addToken(token)
