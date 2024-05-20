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

import {each, defer} from 'lodash'
import $ from 'jquery'

function CheckingCheckboxesForTree($tree, bindEvents) {
  this.$tree = $tree
  if (bindEvents == null) {
    bindEvents = true
  }
  this.doneFetchingEvents = this.doneFetchingEvents.bind(this)
  this.moduleOptionsEvents = this.moduleOptionsEvents.bind(this)
  this.checkboxEvents = this.checkboxEvents.bind(this)
  if (bindEvents) {
    this.bindEvents()
  }
}

CheckingCheckboxesForTree.prototype.bindEvents = function () {
  this.$tree.on('change', 'input[type=checkbox]', this.checkboxEvents)
  this.$tree.on('change', '.module_options input[type=radio]', this.moduleOptionsEvents)
  return this.$tree.on('doneFetchingCheckboxes', this.doneFetchingEvents)
}

// Create events for checking and unchecking a checkbox.
// If all checkboxes on a given level under a ul are checked then it's parents all the way up
// the chain are checked. Same for unchecking. If 1 or more but not all checkboxes are checked
// the parents are put into an intermediate state.
CheckingCheckboxesForTree.prototype.checkboxEvents = function (event) {
  event.preventDefault()
  const $checkbox = $(event.currentTarget)
  const state = $checkbox.is(':checked')
  this.updateTreeItemCheckedAttribute($checkbox, state)
  this.checkCheckboxes({
    checkboxes: this.findChildrenCheckboxes($checkbox),
    setTo: state,
    triggerChange: true,
  })
  this.checkSiblingCheckboxes($checkbox)
  this.syncLinkedResource($checkbox)
  if ($checkbox.data('moduleCheckbox')) {
    each(
      this.findChildrenCheckboxes(this.getRootCheckbox($checkbox)),
      (function (_this) {
        return function (cb) {
          return _this.checkModuleOptions($(cb))
        }
      })(this)
    )
  }
  // We don't want to manage the focus unless they have are trying to click and use the keyboard
  // so we foce the focus to stay on the tree if they have previously selected something in the
  // tree
  if (this.$tree.find('[aria-selected=true]').length) {
    return this.$tree.focus() // ensure focus always stay's on the tree
  }
}

CheckingCheckboxesForTree.prototype.moduleOptionsEvents = function (event) {
  const $radio = $(event.currentTarget)
  const $checkbox = $radio.parents('.module_options').data('checkbox')
  each(
    this.findChildrenCheckboxes(this.getRootCheckbox($checkbox)),
    (function (_this) {
      return function (cb) {
        return _this.checkModuleOptions($(cb))
      }
    })(this)
  )
}

// When we are done fetching checkboxes and displaying them, we want to make sure on the initial
// expantion the sublevel checkboxes are checked/unchecked according to the toplevel checkbox.
// The 'checkbox' param that is being passed in should be the top level checkbox that will be
// used to determine the state of the rest of the sub level checkboxes.
CheckingCheckboxesForTree.prototype.doneFetchingEvents = function (event, checkbox) {
  event.stopPropagation()
  const $checkbox = $(checkbox)
  return this.checkCheckboxes({
    checkboxes: this.findChildrenCheckboxes($checkbox),
    setTo: $checkbox.is(':checked'),
    triggerChange: false,
  })
}

// Check children checkboxes. Take into consideration there might be thousands of checkboxes
// so you have to do a defer so things run smoothly. Also, since there is a defer we allow
// the option to run an afterEach since if this function runs, it might be run before
// the function that is called after it.
// returns nil
CheckingCheckboxesForTree.prototype.checkCheckboxes = function (options) {
  if (options == null) {
    options = {}
  }
  const $checkboxes = options.checkboxes
  const state = options.setTo
  const triggerChange = options.triggerChange
  const afterEach = options.afterEach
  return $checkboxes.each(function () {
    const $checkbox = $(this)
    return defer(function () {
      $checkbox.prop({
        indeterminate: false,
        checked: state,
      })
      $checkbox.closest('[role=treeitem]').attr('aria-checked', state)
      if (triggerChange) {
        $checkbox.trigger('change')
      }
      if (afterEach) {
        return afterEach()
      }
    })
  })
}

// Add checked attribute to the aria-tree
// Keeps the checkbox and the treeitem aria-checked attribute in sync.
// state can be "true", "false" or "mixed" Mixed is the indeterminate state.
CheckingCheckboxesForTree.prototype.updateTreeItemCheckedAttribute = function ($checkbox, state) {
  return $checkbox.closest('[role=treeitem]').attr('aria-checked', state)
}

// Finds all children checkboxes given a checkbox
// returns jQuery object
CheckingCheckboxesForTree.prototype.findChildrenCheckboxes = function ($checkbox) {
  return $checkbox
    .parents('.treeitem-heading')
    .siblings('[role=group]')
    .find('[role=treeitem] input[type=checkbox]')
}

// Checks all of the checkboxes next to each other to determine if the parent
// should be in an indeterminate state. Recursively goes up the tree finding
// the next parent. If one checkbox is is indeterminate then all of it's parents
// become indeterminate.
CheckingCheckboxesForTree.prototype.checkSiblingCheckboxes = function ($checkbox, indeterminate) {
  let checked
  if (indeterminate == null) {
    indeterminate = false
  }
  const $parentCheckbox = this.findParentCheckbox($checkbox)
  this.updateTreeItemCheckedAttribute($checkbox, indeterminate ? 'mixed' : $checkbox.is(':checked'))
  if (!$parentCheckbox) {
    return
  }
  if (indeterminate || !this.siblingsAreTheSame($checkbox)) {
    $parentCheckbox.prop({
      indeterminate: true,
      checked: false,
    })
    return this.checkSiblingCheckboxes($parentCheckbox, true)
  } else {
    checked = $checkbox.is(':checked')
    $parentCheckbox.prop({
      indeterminate: false,
      checked,
    })
    return this.checkSiblingCheckboxes($parentCheckbox, false)
  }
}

// Checks to see if the siblings are in the same state as the checkbox being
// passed in. If all are in the same state ie: all are "checked" or "not checked" then
// this will return true, else its false
// returns bool
CheckingCheckboxesForTree.prototype.siblingsAreTheSame = function ($checkbox) {
  let sameAsChecked = true
  $checkbox
    .closest('[role=treeitem]')
    .siblings()
    .find('input[type=checkbox]')
    .each(function () {
      if ($(this).is(':checked') !== $checkbox.is(':checked')) {
        return (sameAsChecked = false)
      }
    })
  return sameAsChecked
}

// Does a jquery transversal to find the next parent checkbox avalible. If there is no
// parent checkbox avalible returns false.
// returns jQuery Object | false
CheckingCheckboxesForTree.prototype.findParentCheckbox = function ($checkbox) {
  const $parentCheckbox = $checkbox
    .parents('[role=treeitem]')
    .eq(1)
    .find('input[type=checkbox]')
    .first()
  if ($parentCheckbox.length === 0) {
    return false
  } else {
    return $parentCheckbox
  }
}

// Items such as Quizzes and Discussions can be duplicated as an item in an Assignment. Since
// it wouldn't make sense to just check one of those items we ensure that they are synced together.
// If there are duplicate items, there will be a 'linked_resource' object that has a migration_id and
// type assoicated with it. We are building our own custom 'property' based on these two attributes
// so we can ensure they are synced. Whenever we change a checkbox we ensure that a change event
// is triggered so indeterminate states of high level checkboxes can be calculated.
// returns nada
CheckingCheckboxesForTree.prototype.syncLinkedResource = function ($checkbox) {
  const linkedProperty = $checkbox.data('linkedResourceProperty')
  if (linkedProperty) {
    const $linkedCheckbox = this.$tree.find("[name='" + linkedProperty + "']")
    return this.checkCheckboxes({
      checkboxes: $linkedCheckbox,
      setTo: $checkbox.is(':checked'),
      triggerChange: false,
      afterEach: (function (_this) {
        return function () {
          return _this.checkSiblingCheckboxes($linkedCheckbox)
        }
      })(this),
    })
  }
}

CheckingCheckboxesForTree.prototype.getRootCheckbox = function ($checkbox) {
  const $parent = this.findParentCheckbox($checkbox)
  if ($parent) {
    return this.getRootCheckbox($parent)
  } else {
    return $checkbox
  }
}

CheckingCheckboxesForTree.prototype.checkModuleOptions = function ($checkbox) {
  const $mo = $checkbox.data('moduleOptions')
  if (!$mo) {
    return
  }
  if (this.showModuleOptions($checkbox)) {
    return $mo.show()
  } else {
    return $mo.hide()
  }
}

CheckingCheckboxesForTree.prototype.showModuleOptions = function ($checkbox) {
  let $parent, $parent_mo
  if ($checkbox.is(':checked')) {
    $parent = this.findParentCheckbox($checkbox)
    $parent_mo = $parent && $parent.data('moduleOptions')
    if ($parent && $parent.is(':checked') && $parent_mo) {
      if ($parent_mo.is(':visible') && $parent_mo.find('input[value="separate"]').is(':checked')) {
        return true
      }
    } else {
      return true
    }
  }
  return false
}

export default CheckingCheckboxesForTree
