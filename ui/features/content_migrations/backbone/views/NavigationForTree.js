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

const keyPressOptions = {
  38: 'up',
  75: 'up',
  40: 'down',
  74: 'down',
  37: 'left',
  72: 'left',
  39: 'right',
  76: 'right',
  32: 'spacebar',
  35: 'end',
  36: 'home',
}

function NavigationForTree($tree) {
  this.$tree = $tree
  this.clickHeaderEvent = this.clickHeaderEvent.bind(this)
  this.setInitialSelectedState()
  this.bindKeyboardEvents()
}

NavigationForTree.prototype.up = function () {
  const $upNode = this.findTreeItem(this.$currentSelected, 'up')
  return this.selectTreeItem($upNode)
}

NavigationForTree.prototype.down = function () {
  const $downNode = this.findTreeItem(this.$currentSelected, 'down')
  return this.selectTreeItem($downNode)
}

NavigationForTree.prototype.left = function () {
  if (this.$currentSelected.attr('aria-expanded') === 'true') {
    return this.$currentSelected.trigger('collapse')
  } else {
    const $backNode = this.$currentSelected.closest('[aria-expanded=true]')
    return this.selectTreeItem($backNode)
  }
}

NavigationForTree.prototype.right = function () {
  if (this.$currentSelected.attr('aria-expanded') === 'true') {
    const $downNode = this.findTreeItem(this.$currentSelected, 'down')
    return this.selectTreeItem($downNode)
  } else if (this.$currentSelected.attr('aria-expanded') === 'false') {
    return this.$currentSelected.trigger('expand')
  }
}

NavigationForTree.prototype.spacebar = function () {
  return this.$currentSelected.find('input[type=checkbox]').first().click()
}

NavigationForTree.prototype.home = function () {
  const $treeItems = this.$tree.find('[role="treeitem"]:visible')
  const $firstItem = $treeItems.first()
  return this.selectTreeItem($firstItem)
}

NavigationForTree.prototype.end = function () {
  const $treeItems = this.$tree.find('[role="treeitem"]:visible')
  const $lastItem = $treeItems.last()
  return this.selectTreeItem($lastItem)
}

// Clicking a tree item will select that tree item including the
// appropriate aria attribute for that tree item. Only clicking
// the tree items heading should work.
NavigationForTree.prototype.clickHeaderEvent = function (event) {
  event.stopPropagation()
  const treeitemHeading = $(event.currentTarget)
  return this.selectTreeItem(treeitemHeading.closest('[role=treeitem]'))
}

NavigationForTree.prototype.setInitialSelectedState = function () {
  const $treeItems = this.$tree.find('[role=treeitem]')
  $treeItems.each(function () {
    return $(this).attr('aria-selected', false)
  })
  return this.$tree.on('click', 'li .treeitem-heading', this.clickHeaderEvent)
}

NavigationForTree.prototype.bindKeyboardEvents = function () {
  return this.$tree.on(
    'keyup',
    (function (_this) {
      return function (event) {
        let name
        _this.$currentSelected = _this.$tree.find('[aria-selected="true"]')
        return typeof _this[(name = keyPressOptions[event.which])] === 'function'
          ? _this[name]()
          : void 0
      }
    })(this)
  )
}

// Selects the current tree item by setting its aria-selected attribute to
// true and turning all other aria-selected attributes to false. Sets the
// active decendant based on the tree items id. All treeitems are expected
// to have an id.
NavigationForTree.prototype.selectTreeItem = function ($treeItem) {
  if ($treeItem.length) {
    this.$tree.attr('aria-activedescendant', $treeItem.attr('id'))
    this.$tree.find('[aria-selected="true"]').attr('aria-selected', 'false')
    return $treeItem.attr('aria-selected', 'true')
  }
}

// Given a current treeitem, find the the next or previous treeitem from its current
// position. This will only find 'visible' tree items because even though items might
// be in the dom, you shouldn't be able to navigate them unless you can visually see
// them, ie they aren't collapsed or expanded.
NavigationForTree.prototype.findTreeItem = function ($currentSelected, direction) {
  const $treeItems = this.$tree.find('[role="treeitem"]:visible')
  const currentIndex = $treeItems.index($currentSelected)
  let newIndex = currentIndex
  if (direction === 'up') {
    newIndex--
  } else {
    newIndex++
  }
  const node = newIndex >= 0 ? $treeItems.get(newIndex) : $treeItems.get(currentIndex)
  return $(node)
}

export default NavigationForTree
