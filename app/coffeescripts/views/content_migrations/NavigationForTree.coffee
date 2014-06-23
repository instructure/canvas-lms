define [
  'underscore'
  'jquery'
], (_, $) ->
  class NavigationForTree
    # Public Functions

    # Expects a tree type structure with "treeitems"
    constructor: (@$tree) ->
      @setInitialSelectedState()
      @bindKeyboardEvents()

    # Key event functions
    up: ->
      $upNode = @findTreeItem(@$currentSelected, "up")
      @selectTreeItem $upNode

    down: ->
      $downNode = @findTreeItem(@$currentSelected, "down")
      @selectTreeItem $downNode

    left: ->
      if @$currentSelected.attr('aria-expanded') == "true" 
        @$currentSelected.trigger('collapse')
      else
        $backNode = @$currentSelected.closest('[aria-expanded=true]')
        @selectTreeItem $backNode

    right: ->
      if @$currentSelected.attr('aria-expanded') == "true" 
        $downNode = @findTreeItem(@$currentSelected, "down")
        @selectTreeItem $downNode
      else if @$currentSelected.attr('aria-expanded') == "false"
        @$currentSelected.trigger('expand')

    spacebar: ->
      @$currentSelected.find('input[type=checkbox]')
                       .first()
                       .click()

    home: ->
      $treeItems = @$tree.find('[role="treeitem"]:visible')
      $firstItem = $treeItems.first()
      @selectTreeItem($firstItem)

    end: ->
      $treeItems = @$tree.find('[role="treeitem"]:visible')
      $lastItem = $treeItems.last()
      @selectTreeItem($lastItem)

    # Clicking a tree item will select that tree item including the
    # appropriate aria attribute for that tree item. Only clicking
    # the tree items heading should work.
    
    clickHeaderEvent: (event) =>
      event.stopPropagation()
      treeitemHeading = $(event.currentTarget)

      @selectTreeItem treeitemHeading.closest('[role=treeitem]')

    # Keys corispond to jQuery which keyCodes and values are methods
    # on this class that get invoked. If you extend this class with other
    # key events, add those events to this keyPressOptions with the method
    # to be called.

    keyPressOptions =
      38: 'up'
      75: 'up'
      40: 'down'
      74: 'down'
      37: 'left'
      72: 'left'
      39: 'right'
      76: 'right'
      32: 'spacebar'
      35: 'end'
      36: 'home'

    # Private Functions
    setInitialSelectedState: ->
      $treeItems = @$tree.find('[role=treeitem]')
      $treeItems.each -> $(this).attr('aria-selected', false)
      @$tree.on 'click', 'li .treeitem-heading', @clickHeaderEvent

    # Whenever you have a keyup event update the currently selected
    # treeitem then call the function corisponding to the key event
    # pressed.

    bindKeyboardEvents: ->
      @$tree.on 'keyup', (event) =>
        @$currentSelected = @$tree.find('[aria-selected="true"]')
        this[keyPressOptions[event.which]]?()

    # Selects the current tree item by setting its aria-selected attribute to 
    # true and turning all other aria-selected attributes to false. Sets the 
    # active decendant based on the tree items id. All treeitems are expected
    # to have an id.

    selectTreeItem: ($treeItem) ->
      if $treeItem.length
        @$tree.attr('aria-activedescendant', $treeItem.attr('id'))
        @$tree.find('[aria-selected="true"]').attr('aria-selected', 'false')
        $treeItem.attr('aria-selected', 'true')

    # Given a current treeitem, find the the next or previous treeitem from its current
    # position. This will only find 'visible' tree items because even though items might
    # be in the dom, you shouldn't be able to navigate them unless you can visually see 
    # them, ie they aren't collapsed or expanded.

    findTreeItem: ($currentSelected, direction) ->
      $treeItems = @$tree.find('[role="treeitem"]:visible')
      currentIndex = $treeItems.index($currentSelected)
      newIndex = currentIndex

      if direction == "up" then newIndex-- else newIndex++ #defaults to ++ or a down direction
      node = if newIndex >=0 then $treeItems.get(newIndex) else $treeItems.get(currentIndex) # ensure you don't return a negitive index

      $( node )
