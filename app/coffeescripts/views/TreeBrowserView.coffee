define [
  'Backbone'
  'underscore'
  'jst/TreeBrowser'
  'compiled/views/TreeView'
], (Backbone, _, template, TreeView) ->

  class TreeBrowserView extends Backbone.View

    template: template
    @optionProperty 'rootModelsFinder'
    @optionProperty 'onlyShowFolders'
    @optionProperty 'onClick'
    @optionProperty 'dndOptions'
    @optionProperty 'href'
    @optionProperty 'focusStyleClass'
    @optionProperty 'selectedStyleClass'

    # Handle keyboard events for accessibility.
    events:
      'keydown .folderTree[role=tree]': (event) ->
        switch event.which
          when 35 then key = 'end'
          when 36 then key = 'home'
          when 37 then key = 'left'
          when 38 then key = 'up'
          when 39 then key = 'right'
          when 40 then key = 'down'
          when 13, 32 then key = 'enter'
          else return true
        event.preventDefault()
        event.stopPropagation()
        # Handle the first arrow keypress, when nothing is focused.
        # Focus the first item.
        focusedId = @$folderTree.attr('aria-activedescendant')
        if not focusedId
          @focusFirst()
        else
          $focused = @$folderTree.find "##{focusedId}"
          switch key
            when 'up' then @focusPrev $focused
            when 'down' then @focusNext $focused
            when 'left' then @collapseCurrent $focused
            when 'right' then @expandCurrent $focused
            when 'home' then @focusFirst()
            when 'end' then @focusLast $focused
            when 'enter' then @activateCurrent $focused

    afterRender: ->
      @$folderTree = @$el.children('.folderTree')
      for rootModel in @rootModelsFinder.find()
        new TreeView({
          model: rootModel,
          onlyShowFolders: @onlyShowFolders
          onClick: @onClick
          dndOptions: @dndOptions
          href: @href
          selectedStyleClass: @selectedStyleClass
        }).$el.appendTo(@$folderTree)
      super

    # Set the focus from one tree item to another.
    setFocus: ($to, $from) ->
      if not $to?.length or $from?.is? $to
        return
      @$folderTree.find('[role=treeitem]').not($to).attr('aria-selected', false).removeClass(@focusStyleClass)
      $to.attr 'aria-selected', true
      $to.addClass(@focusStyleClass)
      toId = $to.attr 'id'
      if not toId
        toId = _.uniqueId 'treenode-'
        $to.attr 'id', toId
      @$folderTree.attr 'aria-activedescendant', toId


    # focus the first item in the tree.
    focusFirst: -> @setFocus @$folderTree.find '[role=treeitem]:first'

    # focus the last item in the tree.
    focusLast: ($from) ->
      $to = $folderTree.find '[role=treeitem][aria-level=1]'
      level = 1
      # if the last item is expanded, focus the last node from the last expanded item.
      while @ariaPropIsTrue($to, 'aria-expanded') and $to.find('[role=treeitem]:first').length
        level++
        $to = $to.find "[role=treeitem][aria-level=#{level}]:last"
      @setFocus $to, $from

      @setFocus @$folderTree.find '[role=treeitem]:first'

    # Focus the next item in the tree.
    # if the current element is expanded, focus it's first child.
    # Otherwise, focus its next sibling.
    # If the current element is the last child, focus the closest ancester's sibling possible, most deeply nested first.
    # if there are no more siblings after the current element or it's parents, do nothing.
    focusNext: ($from) ->
      if @ariaPropIsTrue $from, 'aria-expanded'
        $to = $from.find '[role=treeitem]:first'
        return @setFocus $to, $from if $to.length
      $to = null
      $cur = $from
      level = parseInt $from.attr('aria-level'), 10
      while level > 0
        nodeSelector = "[role=treeitem][aria-level=#{level}]"
        $to = $cur.parentsUntil('[role=treeitem],[role=tree]') # All nodes between current and parent tree node, exclusive
          .andSelf() # include the current item
          .nextAll() # get all the elements following.
          .find(nodeSelector) # Search there children for tree nodes
          .andSelf() # Add back the previous set so we can see if they are treenodes themselves
          .filter(nodeSelector) # Will be better when we can use .addBack
          .first() # Find the closest next item.
        return @setFocus $to, $from if $to?.length
        level--
        $cur = $cur.parent().closest "[role=treeitem][aria-level=#{level}]"
      return

    # Focus the previous item in the tree.
    # If the current element is the first child, focus the parent.
    # if the current element is the first item in the tree, do nothing.
    # if the previous item is expanded, focus the last subsubitem of the last expanded subitem, or the last subitem.
    focusPrev: ($from) ->
      level = parseInt $from.attr('aria-level'), 10
      nodeSelector = "[role=treeitem][aria-level=#{level}]"
      # Find the closest preceding sibling.
      $to = $from.parentsUntil('[role=treeitem],[role=tree]') # All nodes between current and parent tree node, exclusive
        .andSelf() # include $from
        .prevAll() # get all the elements preceding.
        .find(nodeSelector) # Search there children for tree nodes
        .andSelf() # Add back the previous set so we can see if they are treenodes themselves
        .filter(nodeSelector) # Will be better when we can use .addBack, and combine this and the previous line.
        .last() # Find the closest previous item.
      if not $to.length # no preceding siblings, go up to the parent.
        $to = $from.parent().closest '[role=treeitem]'
        return @setFocus $to, $from
      # if the closest preceding sibling is expanded, focus the last node from the last expanded item.
      while @ariaPropIsTrue($to, 'aria-expanded') and $to.find('[role=treeitem]:first').length
        level++
        $to = $to.find "[role=treeitem][aria-level=#{level}]:last"
      return @setFocus $to, $from

    expandCurrent: ($current) ->
      if @ariaPropIsTrue $current, 'aria-expanded'
        @setFocus $current.find('[role=treeitem]:first'), $current
      else
        $current.find('.folderLabel:first').click()
        @$folderTree.focus()

    collapseCurrent: ($current) ->
      if @ariaPropIsTrue $current, 'aria-expanded'
        $current.find('.folderLabel:first').click()
        @$folderTree.focus()
      else
        @setFocus $current.parent().closest('[role=treeitem]'), $current

    activateCurrent: ($current) ->
      $current.find('a:first').trigger('selectItem')

    ariaPropIsTrue: ($e, attrib) -> $e.attr(attrib)?.toLowerCase?() is 'true'
