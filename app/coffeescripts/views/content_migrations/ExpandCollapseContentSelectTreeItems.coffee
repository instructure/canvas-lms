define [
  'underscore'
  'jquery'
], (_, $) ->
  class ExpandCollapseContentSelectTreeItems

    # Public Functions

    linkedResourceTypes = ['assignments', 'quizzes', 'discussion_topics', 'wiki_pages']

    # Take in an tree that should have treeitems and 
    # a .checkbox-caret associated with it

    constructor: (@$tree, bindEvents=true) ->
      @bindEvents() if bindEvents

    # Events this class will be calling on the tree. Once again
    # expecting there to be treeitems

    bindEvents: ->
      @$tree.on "click", ".checkbox-caret", @caretEvent
      @$tree.on 'expand', '[role=treeitem]', @expand
      @$tree.on 'collapse', '[role=treeitem]', @collapse

    # Stop propagation from bubbling and call the expand function.

    expand: (event) =>
      event.stopPropagation()
      @expandTreeItem $(event.currentTarget)

    # Stop propagation from bubbling and call the collapse/expand functions. If you don't stop propagation
    # it will try to collapse/expand child tree items and parent tree items.

    collapse: (event) =>
      event.stopPropagation()
      @collapseTreeItem $(event.currentTarget)

    caretEvent: (event) =>
      event.preventDefault()
      event.stopPropagation()

      $treeitem = $(event.currentTarget).closest('[role=treeitem]')
      if $treeitem.attr('aria-expanded') == "true"
        @collapseTreeItem($treeitem) 
      else 
        @expandTreeItem($treeitem)

    # Expanding the tree item will display all sublevel items, change the caret class 
    # to better visualize whats happening and add the appropriate aria attributes.

    expandTreeItem: ($treeitem) ->
      $treeitem.attr('aria-expanded', true)
      @triggerTreeItemFetches($treeitem)

    # Collapsing the tree item will display all sublevel items, change the caret class 
    # to better visualize whats happening and add the appropriate aria attributes.

    collapseTreeItem: ($treeitem) ->
      $treeitem.attr('aria-expanded', false)

    # Triggering a checkbox fetch will trigger an event that pulls down via ajax
    # the checkboxes for any given view and caret in that view. There is an edge case
    # with linked_resources where we need to also load the quizzes and discusssions 
    # checkboxes when the assignments checkboxes are selected so in order to accomplish
    # this we use the checkboxFetches object to facilitate that.

    triggerTreeItemFetches: ($treeitem) ->
      $treeitem.trigger('fetchCheckboxes')

      type = $treeitem.data('type')
      if type in linkedResourceTypes
        @triggerLinkedResourcesCheckboxes(type)

    # Trigger linked resources for checkboxes. 
    # Exclude the checkbox that you all ready clicked on

    triggerLinkedResourcesCheckboxes: (excludedType) ->
      types = _.without linkedResourceTypes, excludedType

      _.each types, (type) => 
        @$tree.find("[data-type=#{type}]").trigger('fetchCheckboxes', {silent: true})
