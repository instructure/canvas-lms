#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import I18n from 'i18n!treeBrowser'
import Backbone from '@canvas/backbone'
import _ from 'underscore'
import template from '../../jst/TreeBrowser.handlebars'
import TreeView from './TreeView.coffee'

export default class TreeBrowserView extends Backbone.View

  template: template
  @optionProperty 'rootModelsFinder'
  @optionProperty 'onlyShowSubtrees'
  @optionProperty 'onClick'
  @optionProperty 'dndOptions'
  @optionProperty 'href'
  @optionProperty 'focusStyleClass'
  @optionProperty 'selectedStyleClass'
  @optionProperty 'autoFetch'
  @optionProperty 'fetchItAll'

  # Handle keyboard events for accessibility.
  events:
    'keydown .tree[role=tree]': (event) ->
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
      focusedId = @$tree.attr('aria-activedescendant')
      if not focusedId
        @focusFirst()
      else
        $focused = @$tree.find "##{focusedId}"
        switch key
          when 'up' then @focusPrev $focused
          when 'down' then @focusNext $focused
          when 'left' then @collapseCurrent $focused
          when 'right' then @expandCurrent $focused
          when 'home' then @focusFirst()
          when 'end' then @focusLast $focused
          when 'enter' then @activateCurrent $focused

  setActiveTree: (tree, dialogTree) ->
    dialogTree.activeTree = tree

  afterRender: ->
    @$tree = @$el.children('.tree')
    for rootModel in @rootModelsFinder.find() when rootModel
      new TreeView({
        model: rootModel,
        onlyShowSubtrees: @onlyShowSubtrees
        onClick: @onClick
        dndOptions: @dndOptions
        href: @href
        selectedStyleClass: @selectedStyleClass
        autoFetch: @autoFetch
        fetchItAll: @fetchItAll
      }).$el.appendTo(@$tree)
    super

  destroyView: ->
    @undelegateEvents()
    @$el.removeData().unbind()
    @remove()
    Backbone.View.prototype.remove.call(@)

  # Set the focus from one tree item to another.
  setFocus: ($to, $from) ->
    if not $to?.length or $from?.is? $to
      return
    @$tree.find('[role=treeitem]').not($to).attr('aria-selected', false).removeClass(@focusStyleClass)
    $to.attr 'aria-selected', true
    $to.addClass(@focusStyleClass)
    if (label = $to.attr('aria-label'))
      $.screenReaderFlashMessageExclusive(label)

    toId = $to.attr 'id'
    if not toId
      toId = _.uniqueId 'treenode-'
      $to.attr 'id', toId
    @$tree.attr 'aria-activedescendant', toId

    if $to[0].scrollIntoViewIfNeeded
      $to[0].scrollIntoViewIfNeeded()
    else
      $to[0].scrollIntoView()


  # focus the first item in the tree.
  focusFirst: -> @setFocus @$tree.find '[role=treeitem]:first'

  # focus the last item in the tree.
  focusLast: ($from) ->
    $to = @$tree.find '[role=treeitem][aria-level=1]'
    level = 1
    # if the last item is expanded, focus the last node from the last expanded item.
    while @ariaPropIsTrue($to, 'aria-expanded') and $to.find('[role=treeitem]:first').length
      level++
      $to = $to.find "[role=treeitem][aria-level=#{level}]:last"
    @setFocus $to, $from

    @setFocus @$tree.find '[role=treeitem]:first'

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
      $current.find('.treeLabel:first').click()
      @$tree.focus()

  collapseCurrent: ($current) ->
    if @ariaPropIsTrue $current, 'aria-expanded'
      $current.find('.treeLabel:first').click()
      @$tree.focus()
    else
      @setFocus $current.parent().closest('[role=treeitem]'), $current

  activateCurrent: ($current) ->
    $current.find('a:first').trigger('selectItem')
    $.screenReaderFlashMessage( I18n.t("Selected %{subtree}", {subtree: $current.attr("aria-label")}) )

  ariaPropIsTrue: ($e, attrib) -> $e.attr(attrib)?.toLowerCase?() is 'true'

  focusOnOpen: =>
    @$tree.focus();
