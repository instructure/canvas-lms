define [], ->

  FocusStore =

    _itemToFocus: null

    setItemToFocus: (DOMNode) ->
      @_itemToFocus = DOMNode

    getItemToFocus: ->
      @_itemToFocus

    setFocusToItem: ->
      if (@_itemToFocus)
        @_itemToFocus.focus()
      else
        throw new Error('FocusStore has not been set.')