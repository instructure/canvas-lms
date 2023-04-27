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

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/loading-image'

const I18n = useI18nScope('viewsContextModules')

/* global modules */

/*
xsslint jqueryObject.identifier dragItem dragModule
*/

extend(ContextModules, Backbone.View)

function ContextModules() {
  this.onKeyDown = this.onKeyDown.bind(this)
  this.error = this.error.bind(this)
  this.success = this.success.bind(this)
  this.toggleWorkflowState = this.toggleWorkflowState.bind(this)
  return ContextModules.__super__.constructor.apply(this, arguments)
}

ContextModules.optionProperty('modules')

// events:
//  'click .change-workflow-state-link' : 'toggleWorkflowState'

// Method Summary
//   Toggles a module from "Published" to "Unpublished". This workes by
//   changing a modules workflow_state. A workflow state can be either
//   "unpublished" or "active" (which means published). This uses the
//   div with .context_module class to store the workflow-state and
//   extract the url the request should be set to.
//
// @api private
ContextModules.prototype.toggleWorkflowState = function (event) {
  event.preventDefault()
  this.$context_module = $(event.target).parents('.context_module')
  const module_url = this.$context_module.data('module-url')
  this.workflow_state = this.$context_module.data('workflow-state')
  const request_options = {
    url: module_url,
    type: 'PUT',
    beforeSend: (function (_this) {
      return function () {
        return _this.$context_module.loadingImage()
      }
    })(this),
    success: this.success,
    error: this.error,
  }
  this.setRequestPublishOptions(request_options)
  return $.ajax(request_options)
}

// Method Summary
//   If a successful request has been made, we want to store the workflow state
//   back into the context modules div and add approprate styling for a published
//   or unpublished module.
// @api private
ContextModules.prototype.success = function (response) {
  this.$context_module.data('workflow-state', response.context_module.workflow_state)
  if (response.context_module.workflow_state === 'unpublished') {
    this.addUnpublishAttributes()
  } else {
    this.addPublishAttributes()
  }
  return this.$context_module.loadingImage('remove')
}

// Method Summary
//   We don't need to do anything except remove the loading icon and show an alert
//   if there was an error.
// @api private
ContextModules.prototype.error = function (_response) {
  // eslint-disable-next-line no-alert
  window.alert('This module could not be published')
  return this.$context_module.loadingImage('remove')
}

// Method Summary
//   In order to set the workflow_state of a module, you must send over the params
//   either unpublish=1 or publish=1 You don't want to send both options at the
//   same time. We are always sending inverse of what the current module is ie: if
//   its unpublished we send a request to publish it. Remember, active means published.
// @api private
ContextModules.prototype.setRequestPublishOptions = function (request_options) {
  if (this.workflow_state === 'active') {
    return (request_options.data = 'unpublish=1')
  } else {
    return (request_options.data = 'publish=1')
  }
}

// Method Summary
//   We need to add both icons, text and css classes to elements that are unpublished
// @api private
ContextModules.prototype.addUnpublishAttributes = function () {
  this.$context_module
    .find('.workflow-state-action')
    .text(I18n.t('context_modules.publish', 'Publish'))
  this.$context_module
    .find('.workflow-state-icon')
    .addClass('publish-module-link')
    .removeClass('unpublish-module-link')
  this.$context_module.find('.draft-text').removeClass('hide')
  return this.$context_module.addClass('unpublished_module')
}

ContextModules.prototype.addPublishAttributes = function () {
  this.$context_module
    .find('.workflow-state-action')
    .text(I18n.t('context_module.unpublish', 'Unpublish'))
  this.$context_module
    .find('.workflow-state-icon')
    .addClass('unpublish-module-link')
    .removeClass('publish-module-link')
  this.$context_module.find('.draft-text').addClass('hide')
  return this.$context_module.removeClass('unpublished_module')
}

// Drag-And-Drop Accessibility:
ContextModules.prototype.keyCodes = {
  32: 'Space',
  38: 'UpArrow',
  40: 'DownArrow',
}

ContextModules.prototype.moduleSelector = 'div.context_module'

ContextModules.prototype.itemSelector = 'table.context_module_item'

ContextModules.prototype.initialize = function () {
  ContextModules.__super__.initialize.apply(this, arguments)
  this.$contextModules = $('#context_modules')
  return this.$contextModules.parent().on('keydown', this.onKeyDown)
}

ContextModules.prototype.onKeyDown = function (e) {
  const $target = $(e.target)
  const fn = 'on' + this.keyCodes[e.keyCode] + 'Key'
  if (this[fn]) {
    e.preventDefault()
    return this[fn].call(this, e, $target)
  }
}

ContextModules.prototype.getFocusedElement = function (el) {
  let parent = el.parents(this.itemSelector).first()
  if (!this.empty(parent)) {
    el = parent
  }
  if (!el.is(this.itemSelector)) {
    parent = el.parents(this.moduleSelector).first()
    if (!this.empty(parent)) {
      el = parent
    }
    if (!el.is(this.moduleSelector)) {
      el = this.$contextModules
    }
  }
  return el
}

// Internal: move to the previous element
// returns nothing
ContextModules.prototype.onUpArrowKey = function (e, $target) {
  let prev
  const el = this.getFocusedElement($target)
  if (el.is(this.itemSelector)) {
    prev = el.prev(this.itemSelector)
    if (this.empty(prev) || this.$contextModules.data('dragModule')) {
      prev = el.parents(this.moduleSelector).first()
    }
  } else if (el.is(this.moduleSelector)) {
    if (this.$contextModules.data('dragItem')) {
      prev = this.$contextModules.data('dragItemModule')
    } else {
      prev = el.prev(this.moduleSelector)
      if (this.empty(prev)) {
        prev = this.$contextModules
      } else if (!this.$contextModules.data('dragModule')) {
        const lastChild = prev.find(this.itemSelector).last()
        if (!this.empty(lastChild)) {
          prev = lastChild
        }
      }
    }
  }
  if (prev && !this.empty(prev)) {
    return prev.focus()
  }
}

// Internal: move to the next element
// returns nothing
ContextModules.prototype.onDownArrowKey = function (e, $target) {
  let next, parent
  const el = this.getFocusedElement($target)
  if (el.is(this.itemSelector)) {
    next = el.next(this.itemSelector)
    if (this.empty(next) && !this.$contextModules.data('dragItem')) {
      parent = el.parents(this.moduleSelector).first()
      next = parent.next(this.moduleSelector)
    }
  } else if (el.is(this.moduleSelector)) {
    next = el.find(this.itemSelector).first()
    if (this.empty(next) || this.$contextModules.data('dragModule')) {
      next = el.next(this.moduleSelector)
    }
  } else {
    next = this.$contextModules.find(this.moduleSelector).first()
  }
  if (next && !this.empty(next)) {
    return next.focus()
  }
}

// Internal: mark the current element to begin dragging
// or drop the current element
// returns nothing
ContextModules.prototype.onSpaceKey = function (e, $target) {
  let dragItem, dragModule, el, parentModule
  el = this.getFocusedElement($target)
  if ((dragItem = this.$contextModules.data('dragItem'))) {
    if (!el.is(dragItem)) {
      parentModule = this.$contextModules.data('dragItemModule')
      if (el.is(this.itemSelector) && !this.empty(el.parents(parentModule))) {
        el.after(dragItem)
      } else {
        parentModule.find('.items').prepend(dragItem)
      }
      modules.updateModuleItemPositions(null, {
        item: dragItem.parent(),
      })
    }
    dragItem.attr('aria-grabbed', false)
    this.$contextModules.data('dragItem', null)
    this.$contextModules.data('dragItemModule', null)
    return dragItem.focus()
  } else if ((dragModule = this.$contextModules.data('dragModule'))) {
    if (el.is(this.itemSelector)) {
      el = el.parents(this.moduleSelector).first()
    }
    if (!el.is(dragModule)) {
      if (this.empty(el) || el.is(this.$contextModules)) {
        this.$contextModules.prepend(dragModule)
      } else {
        el.after(dragModule)
      }
      modules.updateModulePositions()
    }
    dragModule.attr('aria-grabbed', false)
    this.$contextModules.data('dragModule', null)
    return dragModule.focus()
  } else if (!el.is(this.$contextModules)) {
    el.attr('aria-grabbed', true)
    if (el.is(this.itemSelector)) {
      this.$contextModules.data('dragItem', el)
      this.$contextModules.data('dragItemModule', el.parents(this.moduleSelector).first())
    } else if (el.is(this.moduleSelector)) {
      this.$contextModules.data('dragModule', el)
    }
    el.blur()
    return el.focus()
  }
}

// Internal: returns whether the selector is empty
ContextModules.prototype.empty = function (selector) {
  return selector.length === 0
}

export default ContextModules
