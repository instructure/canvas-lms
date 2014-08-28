define [
  'underscore'
  'jquery'
], (_, $) ->
  class CheckingCheckboxesForTree
    # Public Functions
    constructor: (@$tree, bindEvents=true) ->
      @bindEvents() if bindEvents

    # Private Functions

    bindEvents: ->
      @$tree.on "change", "input[type=checkbox]", @checkboxEvents
      @$tree.on "doneFetchingCheckboxes", @doneFetchingEvents

    # Create events for checking and unchecking a checkbox.
    # If all checkboxes on a given level under a ul are checked then it's parents all the way up
    # the chain are checked. Same for unchecking. If 1 or more but not all checkboxes are checked
    # the parents are put into an intermediate state.

    checkboxEvents: (event) =>
      event.preventDefault()
      $checkbox = $(event.currentTarget)
      state = $checkbox.is(':checked')

      @updateTreeItemCheckedAttribute($checkbox, state)
      @checkCheckboxes
        checkboxes: @findChildrenCheckboxes($checkbox)
        setTo: state
        triggerChange: true

      @checkSiblingCheckboxes($checkbox) # start recursion up the tree for 3 state checkboxes
      @syncLinkedResource($checkbox)

      # We don't want to manage the focus unless they have are trying to click and use the keyboard
      # so we foce the focus to stay on the tree if they have previously selected something in the
      # tree
      if @$tree.find("[aria-selected=true]").length
        @$tree.focus() #ensure focus always stay's on the tree

    # When we are done fetching checkboxes and displaying them, we want to make sure on the initial 
    # expantion the sublevel checkboxes are checked/unchecked according to the toplevel checkbox. 
    # The 'checkbox' param that is being passed in should be the top level checkbox that will be
    # used to determine the state of the rest of the sub level checkboxes.

    doneFetchingEvents: (event, checkbox) => 
      event.stopPropagation()
      $checkbox = $(checkbox)

      @checkCheckboxes
        checkboxes: @findChildrenCheckboxes($checkbox)
        setTo: $checkbox.is(':checked')
        triggerChange: false

    # Check children checkboxes. Take into consideration there might be thousands of checkboxes
    # so you have to do a defer so things run smoothly. Also, since there is a defer we allow
    # the option to run an afterEach since if this function runs, it might be run before
    # the function that is called after it.
    # returns nil

    checkCheckboxes: (options={}) ->
      $checkboxes = options.checkboxes
      state = options.setTo
      triggerChange = options.triggerChange
      afterEach = options.afterEach

      $checkboxes.each ->
        $checkbox = $(this)

        _.defer ->
          $checkbox.prop
            indeterminate: false
            checked: state
          $checkbox.closest('[role=treeitem]').attr("aria-checked", state)
          $checkbox.trigger('change') if triggerChange

          afterEach() if afterEach

    # Add checked attribute to the aria-tree
    # Keeps the checkbox and the treeitem aria-checked attribute in sync.
    # state can be "true", "false" or "mixed" Mixed is the indeterminate state.

    updateTreeItemCheckedAttribute: ($checkbox, state) ->
      $checkbox.closest('[role=treeitem]').attr("aria-checked", state)

    # Finds all children checkboxes given a checkbox
    # returns jQuery object
    
    findChildrenCheckboxes: ($checkbox) ->
      $childCheckboxes = $checkbox.parents('.treeitem-heading')
                                 .siblings('[role=group]')
                                 .find('[role=treeitem] input[type=checkbox]')

    # Checks all of the checkboxes next to each other to determine if the parent
    # should be in an indeterminate state. Recursively goes up the tree finding
    # the next parent. If one checkbox is is indeterminate then all of it's parents
    # become indeterminate.

    checkSiblingCheckboxes: ($checkbox, indeterminate=false) ->
      $parentCheckbox = @findParentCheckbox($checkbox)
      @updateTreeItemCheckedAttribute($checkbox, if indeterminate then "mixed" else $checkbox.is(':checked'))
      return unless $parentCheckbox
      
      if indeterminate || !@siblingsAreTheSame($checkbox)
        $parentCheckbox.prop
          indeterminate: true
          checked: false
        @checkSiblingCheckboxes($parentCheckbox, true)
      else
        $parentCheckbox.prop
          indeterminate: false
          checked: $checkbox.is(':checked')
        @checkSiblingCheckboxes($parentCheckbox, false)

    # Checks to see if the siblings are in the same state as the checkbox being
    # passed in. If all are in the same state ie: all are "checked" or "not checked" then
    # this will return true, else its false
    # returns bool

    siblingsAreTheSame: ($checkbox) ->
      sameAsChecked = true
      $checkbox.closest('[role=treeitem]').siblings().find('input[type=checkbox]').each ->
        if $(this).is(':checked') != $checkbox.is(':checked') then sameAsChecked = false

      sameAsChecked

    # Does a jquery transversal to find the next parent checkbox avalible. If there is no
    # parent checkbox avalible returns false.
    # returns jQuery Object | false

    findParentCheckbox: ($checkbox) ->
      $parentCheckbox = $checkbox.parents('[role=treeitem]')
                           .eq(1).find('input[type=checkbox]')
                           .first()

      if $parentCheckbox.length == 0 then false else $parentCheckbox

    # Items such as Quizzes and Discussions can be duplicated as an item in an Assignment. Since
    # it wouldn't make sense to just check one of those items we ensure that they are synced together.
    # If there are duplicate items, there will be a 'linked_resource' object that has a migration_id and
    # type assoicated with it. We are building our own custom 'property' based on these two attributes
    # so we can ensure they are synced. Whenever we change a checkbox we ensure that a change event
    # is triggered so indeterminate states of high level checkboxes can be calculated.
    # returns nada

    syncLinkedResource: ($checkbox) ->
      linkedProperty = $checkbox.data('linkedResourceProperty')

      if linkedProperty
        $linkedCheckbox = @$tree.find("[name='#{linkedProperty}']")
        @checkCheckboxes 
          checkboxes: $linkedCheckbox
          setTo: $checkbox.is(':checked')
          triggerChange: false
          afterEach: => @checkSiblingCheckboxes($linkedCheckbox) # start recursion up the tree for 3 state checkboxes
