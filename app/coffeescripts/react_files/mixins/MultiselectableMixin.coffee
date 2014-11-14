define [
  'underscore'
  'jquery'
], (_, $) ->

  # To use this, your view must implement a `selectables` method that
  # returns an array of the things that are selectable.

  MultiselectableMixin =

    getInitialState: ->
      selectedItems: []

    componentDidMount: ->
      $(window).on('keydown', @handleCtrlPlusA)

    componentWillUnmount: ->
      $(window).off('keydown', @handleCtrlPlusA)

    # overwrite this in your component if you want to suppress the multi-select
    # behavior on different elements. Should be something you can pass to $.fn.is
    multiselectIgnoredElements: ':input:not(.multiselectable-toggler), a'

    handleCtrlPlusA: (e) ->
      return if e.target.nodeName.toLowerCase() in ['input', 'textarea']
      if e.which == 65 && (e.ctrlKey || e.metaKey)
        e.preventDefault()
        @toggleAllSelected(!e.shiftKey) #ctrl-shift-a

    toggleAllSelected: (shouldSelect) ->
      if shouldSelect
        @setState selectedItems: @selectables()
      else
        @setState selectedItems: []

    areAllItemsSelected: ->
      @state.selectedItems.length && (@state.selectedItems.length is @selectables().length)

    selectRange: (item) ->
      selectables = @selectables()
      newPos = selectables.indexOf(item)
      lastPos = selectables.indexOf(_.last(@state.selectedItems))
      range = selectables.slice(Math.min(newPos, lastPos), Math.max(newPos, lastPos)+1)
      # the anchor needs to stay at the end
      range.reverse() if newPos > lastPos
      @setState selectedItems: range

    clearSelectedItems: ->
      @setState selectedItems: []

    toggleItemSelected: (item, event, cb) ->
      return if event and $(event.target).closest(@multiselectIgnoredElements).length
      event?.preventDefault()

      return @selectRange(item) if event?.shiftKey

      itemIsSelected = item in @state.selectedItems
      leaveOthersAlone = (event?.metaKey or event?.ctrlKey) or event?.target.type is 'checkbox'

      if leaveOthersAlone and itemIsSelected
        selectedItems = _.without(@state.selectedItems, item)
      else if leaveOthersAlone
        selectedItems = @state.selectedItems.slice() #.slice() is to not mutate state directly
        selectedItems.push(item)
      else if itemIsSelected
        selectedItems = []
      else
        selectedItems = [item]

      @setState {selectedItems: selectedItems}, ->
        cb?()

