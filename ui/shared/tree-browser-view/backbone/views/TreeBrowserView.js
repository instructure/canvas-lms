/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/* eslint-disable no-void */

import $ from 'jquery'
import {uniqueId} from 'lodash'
import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import Backbone from '@canvas/backbone'
import template from '../../jst/TreeBrowser.handlebars'
import TreeView from './TreeView'

const I18n = useI18nScope('treeBrowser')

extend(TreeBrowserView, Backbone.View)

function TreeBrowserView() {
  this.focusOnOpen = this.focusOnOpen.bind(this)
  return TreeBrowserView.__super__.constructor.apply(this, arguments)
}

TreeBrowserView.prototype.template = template

TreeBrowserView.optionProperty('rootModelsFinder')

TreeBrowserView.optionProperty('onlyShowSubtrees')

TreeBrowserView.optionProperty('onClick')

TreeBrowserView.optionProperty('dndOptions')

TreeBrowserView.optionProperty('href')

TreeBrowserView.optionProperty('focusStyleClass')

TreeBrowserView.optionProperty('selectedStyleClass')

TreeBrowserView.optionProperty('autoFetch')

TreeBrowserView.optionProperty('fetchItAll')

// Handle keyboard events for accessibility
TreeBrowserView.prototype.events = {
  'keydown .tree[role=tree]': function (event) {
    let $focused, key
    switch (event.which) {
      case 35:
        key = 'end'
        break
      case 36:
        key = 'home'
        break
      case 37:
        key = 'left'
        break
      case 38:
        key = 'up'
        break
      case 39:
        key = 'right'
        break
      case 40:
        key = 'down'
        break
      case 13:
      case 32:
        key = 'enter'
        break
      default:
        return true
    }
    event.preventDefault()
    event.stopPropagation()
    // # Handle the first arrow keypress, when nothing is focused.
    // # Focus the first item.
    const focusedId = this.$tree.attr('aria-activedescendant')
    if (!focusedId) {
      return this.focusFirst()
    } else {
      $focused = this.$tree.find('#' + focusedId)
      switch (key) {
        case 'up':
          return this.focusPrev($focused)
        case 'down':
          return this.focusNext($focused)
        case 'left':
          return this.collapseCurrent($focused)
        case 'right':
          return this.expandCurrent($focused)
        case 'home':
          return this.focusFirst()
        case 'end':
          return this.focusLast($focused)
        case 'enter':
          return this.activateCurrent($focused)
      }
    }
  },
}

TreeBrowserView.prototype.setActiveTree = function (tree, dialogTree) {
  return (dialogTree.activeTree = tree)
}

TreeBrowserView.prototype.afterRender = function () {
  let i, len, rootModel
  this.$tree = this.$el.children('.tree')
  const ref = this.rootModelsFinder.find()
  for (i = 0, len = ref.length; i < len; i++) {
    rootModel = ref[i]
    if (rootModel) {
      new TreeView({
        model: rootModel,
        onlyShowSubtrees: this.onlyShowSubtrees,
        onClick: this.onClick,
        dndOptions: this.dndOptions,
        href: this.href,
        selectedStyleClass: this.selectedStyleClass,
        autoFetch: this.autoFetch,
        fetchItAll: this.fetchItAll,
      }).$el.appendTo(this.$tree)
    }
  }
  return TreeBrowserView.__super__.afterRender.apply(this, arguments)
}

TreeBrowserView.prototype.destroyView = function () {
  this.undelegateEvents()
  this.$el.removeData().unbind()
  this.remove()
  return Backbone.View.prototype.remove.call(this)
}

// Set the focus from one tree item to another.
TreeBrowserView.prototype.setFocus = function ($to, $from) {
  let label, toId
  if (
    !($to != null ? $to.length : void 0) ||
    ($from != null ? (typeof $from.is === 'function' ? $from.is($to) : void 0) : void 0)
  ) {
    return
  }
  this.$tree
    .find('[role=treeitem]')
    .not($to)
    .attr('aria-selected', false)
    .removeClass(this.focusStyleClass)
  $to.attr('aria-selected', true)
  $to.addClass(this.focusStyleClass)
  if ((label = $to.attr('aria-label'))) {
    $.screenReaderFlashMessageExclusive(label)
  }
  toId = $to.attr('id')
  if (!toId) {
    toId = uniqueId('treenode-')
    $to.attr('id', toId)
  }
  this.$tree.attr('aria-activedescendant', toId)
  if ($to[0].scrollIntoViewIfNeeded) {
    return $to[0].scrollIntoViewIfNeeded()
  } else {
    return $to[0].scrollIntoView()
  }
}

// focus the first item in the tree
TreeBrowserView.prototype.focusFirst = function () {
  return this.setFocus(this.$tree.find('[role=treeitem]:first'))
}

// focus the last item in the tree
TreeBrowserView.prototype.focusLast = function ($from) {
  let $to = this.$tree.find('[role=treeitem][aria-level=1]')
  let level = 1
  // if the last item is expanded, focus the last node from the last expanded item.
  while (this.ariaPropIsTrue($to, 'aria-expanded') && $to.find('[role=treeitem]:first').length) {
    level++
    $to = $to.find('[role=treeitem][aria-level=' + level + ']:last')
  }
  this.setFocus($to, $from)
  return this.setFocus(this.$tree.find('[role=treeitem]:first'))
}

// # Focus the next item in the tree.
// # if the current element is expanded, focus it's first child.
// # Otherwise, focus its next sibling.
// # If the current element is the last child, focus the closest ancester's sibling possible, most deeply nested first.
// # if there are no more siblings after the current element or it's parents, do nothing.
TreeBrowserView.prototype.focusNext = function ($from) {
  let $cur, $to, nodeSelector
  if (this.ariaPropIsTrue($from, 'aria-expanded')) {
    $to = $from.find('[role=treeitem]:first')
    if ($to.length) {
      return this.setFocus($to, $from)
    }
  }
  $to = null
  $cur = $from
  let level = parseInt($from.attr('aria-level'), 10)
  while (level > 0) {
    nodeSelector = '[role=treeitem][aria-level=' + level + ']'
    // All nodes between current and parent tree node, exclusive
    $to = $cur
      .parentsUntil('[role=treeitem],[role=tree]')
      .andSelf() // include the current item
      .nextAll() // get all the elements following
      .find(nodeSelector) // Search there children for tree nodes
      .andSelf() // Add back the previous set so we can see if they are treenodes themselves
      .filter(nodeSelector) // Will be better when we can use .addBack
      .first() // Find the closest next item
    if ($to != null ? $to.length : void 0) {
      return this.setFocus($to, $from)
    }
    level--
    $cur = $cur.parent().closest('[role=treeitem][aria-level=' + level + ']')
  }
}

// # Focus the previous item in the tree.
// # If the current element is the first child, focus the parent.
// # if the current element is the first item in the tree, do nothing.
// # if the previous item is expanded, focus the last subsubitem of the last expanded subitem, or the last subitem.
TreeBrowserView.prototype.focusPrev = function ($from) {
  let $to, level
  level = parseInt($from.attr('aria-level'), 10)
  const nodeSelector = '[role=treeitem][aria-level=' + level + ']'
  // Find the closest preceding sibling
  $to = $from
    .parentsUntil('[role=treeitem],[role=tree]') // All nodes between current and parent tree node, exclusive
    .andSelf() // include $from
    .prevAll() // get all the elements preceding
    .find(nodeSelector) // Search there children for tree nodes
    .andSelf() // Add back the previous set so we can see if they are treenodes themselves
    .filter(nodeSelector) // Will be better when we can use .addBack, and combine this and the previous line.
    .last() // Find the closest previous item
  if (!$to.length) {
    $to = $from.parent().closest('[role=treeitem]')
    return this.setFocus($to, $from)
  }
  // if the closest preceding sibling is expanded, focus the last node from the last expanded item
  while (this.ariaPropIsTrue($to, 'aria-expanded') && $to.find('[role=treeitem]:first').length) {
    level++
    $to = $to.find('[role=treeitem][aria-level=' + level + ']:last')
  }
  return this.setFocus($to, $from)
}

TreeBrowserView.prototype.expandCurrent = function ($current) {
  if (this.ariaPropIsTrue($current, 'aria-expanded')) {
    return this.setFocus($current.find('[role=treeitem]:first'), $current)
  } else {
    $current.find('.treeLabel:first').click()
    return this.$tree.focus()
  }
}

TreeBrowserView.prototype.collapseCurrent = function ($current) {
  if (this.ariaPropIsTrue($current, 'aria-expanded')) {
    $current.find('.treeLabel:first').click()
    return this.$tree.focus()
  } else {
    return this.setFocus($current.parent().closest('[role=treeitem]'), $current)
  }
}

TreeBrowserView.prototype.activateCurrent = function ($current) {
  $current.find('a:first').trigger('selectItem')
  return $.screenReaderFlashMessage(
    I18n.t('Selected %{subtree}', {
      subtree: $current.attr('aria-label'),
    })
  )
}

TreeBrowserView.prototype.ariaPropIsTrue = function ($e, attrib) {
  let ref
  return (
    ((ref = $e.attr(attrib)) != null
      ? typeof ref.toLowerCase === 'function'
        ? ref.toLowerCase()
        : void 0
      : void 0) === 'true'
  )
}

TreeBrowserView.prototype.focusOnOpen = function () {
  return this.$tree.focus()
}

export default TreeBrowserView
