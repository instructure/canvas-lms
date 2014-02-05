define [
  'underscore'
  'jquery'
], (_, $) ->
  class ScrollPositionForTree
    # Public Functions
    
    # Create the inital object

    constructor: (@$tree, @$container) ->
      @bindEvents()

    # Calculates the offset that should be used to keep the treeitems in sync. 
    # You can overwrite this function to if you need something more custom

    fileScrollOffset: ($treeitem) ->
      return unless $treeitem.length

      topLevelMarginOffset = @findTopTreeItemMargins($treeitem, '.top-level-treeitem', 10)
      treeItemsOffset = @findTreeItemsOffset($treeitem, 32)
      containerOffset = @$container.height()/2

      topLevelMarginOffset + treeItemsOffset - containerOffset

    # Private Function

    bindEvents: ->
      @$tree.on 'keyup', @manageScrollPosition

    # Ensure that when you press a key the currently selected
    # treeitem is always centered.

    manageScrollPosition: =>
      $treeitem = @$tree.find("##{@$tree.attr('aria-activedescendant')}")
      @$container.scrollTop @fileScrollOffset($treeitem)
      
    # Finds the total margins that seperate top level tree items. Expects
    # a tree item to start from, toplevel selector and margins between each

    findTopTreeItemMargins: ($treeitem, selector, margin) ->
      $topLevelItem = $treeitem.closest(selector)
      $topLevelItem = $treeitem unless $topLevelItem.length

      topLevelIndex = $topLevelItem.index("#{selector}:visible")

      (margin * topLevelIndex) + margin

    # Finds the total heights of all tree items up to the passed in tree item. Pass
    # in an optional height. 

    findTreeItemsOffset: ($treeitem, height) ->
      treeItemIndex = $treeitem.index("[role=treeitem]:visible")
      height * (treeItemIndex + 1)

