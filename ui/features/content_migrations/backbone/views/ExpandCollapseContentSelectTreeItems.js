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

import {each, without} from 'lodash'
import $ from 'jquery'

const linkedResourceTypes = ['assignments', 'quizzes', 'discussion_topics', 'wiki_pages']

// Take in an tree that should have treeitems and
// a .checkbox-caret associated with it
function ExpandCollapseContentSelectTreeItems($tree, bindEvents) {
  this.$tree = $tree
  if (bindEvents == null) {
    bindEvents = true
  }
  this.caretEvent = this.caretEvent.bind(this)
  this.collapse = this.collapse.bind(this)
  this.expand = this.expand.bind(this)
  if (bindEvents) {
    this.bindEvents()
  }
}

// Events this class will be calling on the tree. Once again
// expecting there to be treeitems
ExpandCollapseContentSelectTreeItems.prototype.bindEvents = function () {
  this.$tree.on('click', '.checkbox-caret', this.caretEvent)
  this.$tree.on('expand', '[role=treeitem]', this.expand)
  return this.$tree.on('collapse', '[role=treeitem]', this.collapse)
}

// Stop propagation from bubbling and call the expand function.
ExpandCollapseContentSelectTreeItems.prototype.expand = function (event) {
  event.stopPropagation()
  return this.expandTreeItem($(event.currentTarget))
}

// Stop propagation from bubbling and call the collapse/expand functions. If you don't stop propagation
// it will try to collapse/expand child tree items and parent tree items.
ExpandCollapseContentSelectTreeItems.prototype.collapse = function (event) {
  event.stopPropagation()
  return this.collapseTreeItem($(event.currentTarget))
}

ExpandCollapseContentSelectTreeItems.prototype.caretEvent = function (event) {
  event.preventDefault()
  event.stopPropagation()
  const $treeitem = $(event.currentTarget).closest('[role=treeitem]')
  if ($treeitem.attr('aria-expanded') === 'true') {
    return this.collapseTreeItem($treeitem)
  } else {
    return this.expandTreeItem($treeitem)
  }
}

// Expanding the tree item will display all sublevel items, change the caret class
// to better visualize whats happening and add the appropriate aria attributes.
ExpandCollapseContentSelectTreeItems.prototype.expandTreeItem = function ($treeitem) {
  $treeitem.attr('aria-expanded', true)
  return this.triggerTreeItemFetches($treeitem)
}

// Collapsing the tree item will display all sublevel items, change the caret class
// to better visualize whats happening and add the appropriate aria attributes.
ExpandCollapseContentSelectTreeItems.prototype.collapseTreeItem = function ($treeitem) {
  return $treeitem.attr('aria-expanded', false)
}

// Triggering a checkbox fetch will trigger an event that pulls down via ajax
// the checkboxes for any given view and caret in that view. There is an edge case
// with linked_resources where we need to also load the quizzes and discusssions
// checkboxes when the assignments checkboxes are selected so in order to accomplish
// this we use the checkboxFetches object to facilitate that.
ExpandCollapseContentSelectTreeItems.prototype.triggerTreeItemFetches = function ($treeitem) {
  $treeitem.trigger('fetchCheckboxes')
  const type = $treeitem.data('type')
  const indexOf = [].indexOf
  if (indexOf.call(linkedResourceTypes, type) >= 0) {
    return this.triggerLinkedResourcesCheckboxes(type)
  }
}

// Trigger linked resources for checkboxes.
// Exclude the checkbox that you all ready clicked on
ExpandCollapseContentSelectTreeItems.prototype.triggerLinkedResourcesCheckboxes = function (
  excludedType
) {
  const types = without(linkedResourceTypes, excludedType)
  each(
    types,
    (function (_this) {
      return function (type) {
        return _this.$tree.find('[data-type=' + type + ']').trigger('fetchCheckboxes', {
          silent: true,
        })
      }
    })(this)
  )
}

export default ExpandCollapseContentSelectTreeItems
