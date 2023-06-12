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

function ScrollPositionForTree($tree, $container) {
  this.$tree = $tree
  this.$container = $container
  this.manageScrollPosition = this.manageScrollPosition.bind(this)
  this.bindEvents()
}

// Calculates the offset that should be used to keep the treeitems in sync.
// You can overwrite this function to if you need something more custom
ScrollPositionForTree.prototype.fileScrollOffset = function ($treeitem) {
  if (!$treeitem.length) {
    return
  }
  const topLevelMarginOffset = this.findTopTreeItemMargins($treeitem, '.top-level-treeitem', 10)
  const treeItemsOffset = this.findTreeItemsOffset($treeitem, 32)
  const containerOffset = this.$container.height() / 2
  return topLevelMarginOffset + treeItemsOffset - containerOffset
}

ScrollPositionForTree.prototype.bindEvents = function () {
  return this.$tree.on('keyup', this.manageScrollPosition)
}

// Ensure that when you press a key the currently selected
// treeitem is always centered.

ScrollPositionForTree.prototype.manageScrollPosition = function () {
  const $treeitem = this.$tree.find('#' + this.$tree.attr('aria-activedescendant'))
  return this.$container.scrollTop(this.fileScrollOffset($treeitem))
}

// Finds the total margins that seperate top level tree items. Expects
// a tree item to start from, toplevel selector and margins between each

ScrollPositionForTree.prototype.findTopTreeItemMargins = function ($treeitem, selector, margin) {
  let $topLevelItem = $treeitem.closest(selector)
  if (!$topLevelItem.length) {
    $topLevelItem = $treeitem
  }
  const topLevelIndex = $topLevelItem.index(selector + ':visible')
  return margin * topLevelIndex + margin
}

// Finds the total heights of all tree items up to the passed in tree item. Pass
// in an optional height.

ScrollPositionForTree.prototype.findTreeItemsOffset = function ($treeitem, height) {
  const treeItemIndex = $treeitem.index('[role=treeitem]:visible')
  return height * (treeItemIndex + 1)
}

export default ScrollPositionForTree
