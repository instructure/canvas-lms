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
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import htmlEscape from '@instructure/html-escape'
import '@canvas/jquery/jquery.instructure_forms'

const I18n = useI18nScope('LockButton')

extend(LockButton, Backbone.View)

// # render as a working button when in a master course,
// # and as a plain old span if not
function LockButton() {
  return LockButton.__super__.constructor.apply(this, arguments)
}

LockButton.prototype.lockedClass = 'btn-locked'

LockButton.prototype.unlockedClass = 'btn-unlocked'

LockButton.prototype.disabledClass = 'disabled'

// These values allow the default text to be overridden if necessary
LockButton.optionProperty('lockedText')

LockButton.optionProperty(
  'unlockedText',
  LockButton.optionProperty('course_id', LockButton.optionProperty('content_id'))
)

LockButton.optionProperty('content_type')

LockButton.prototype.tagName = 'button'

LockButton.prototype.className = 'btn'

LockButton.prototype.events = {
  click: 'click',
  hover: 'hover',
  focus: 'focus',
  blur: 'blur',
}

LockButton.prototype.els = {
  i: '$icon',
  '.lock-text': '$text',
}

LockButton.prototype.initialize = function () {
  LockButton.__super__.initialize.apply(this, arguments)
  // button is enabled only for master courses
  this.disabled = !this.isMasterCourseMasterContent()
  this.disabledClass = this.disabled ? 'disabled' : ''
  this.lockedText = this.lockedText || I18n.t('Locked. Click to unlock.')
  return (this.unlockedText = this.unlockedText || I18n.t('Unlocked. Click to lock.'))
}

LockButton.prototype.setElement = function () {
  LockButton.__super__.setElement.apply(this, arguments)
  return this.$el.attr('data-tooltip', '')
}

// events

LockButton.prototype.hover = function (arg) {
  const type = arg.type
  if (this.disabled) {
    return
  }
  if (type === 'mouseenter') {
    if (this.isLocked()) {
      return this.renderWillUnlock()
    } else {
      return this.renderWillLock()
    }
  } else if (type === 'mouseleave') {
    if (this.isLocked()) {
      return this.renderLocked()
    } else {
      return this.renderUnlocked()
    }
  }
}

LockButton.prototype.focus = function () {
  return this.focusblur()
}

LockButton.prototype.blur = function () {
  return this.focusblur()
}

// # this causes the button to re-render as it is which seems dumb,
// # but if you don't, the tooltip gets stuck forever with the hover text
// # after mouseenter/leave. Even now,
// # focus-blur-mouseenter-mouseleave-focus and the tooltip is left from hover
// # follow with blur-focus and it's corrected
// # I believe this is a but in jquery's tooltip.
LockButton.prototype.focusblur = function () {
  if (this.disabled) {
    return
  }
  if (this.isLocked()) {
    return this.renderLocked()
  } else {
    return this.renderUnlocked()
  }
}

LockButton.prototype.click = function (event) {
  event.preventDefault()
  event.stopPropagation()
  if (this.disabled) {
    return
  }
  if (this.isLocked()) {
    return this.unlock()
  } else {
    return this.lock()
  }
}

LockButton.prototype.setFocusToElement = function () {
  return this.$el.focus()
}

LockButton.prototype.lock = function (_event) {
  this.renderLocking()
  return this.setLockState(true)
}

LockButton.prototype.unlock = function (_event) {
  this.renderUnlocking()
  return this.setLockState(false)
}

LockButton.prototype.setLockState = function (locked) {
  return $.ajaxJSON(
    '/api/v1/courses/' + this.course_id + '/blueprint_templates/default/restrict_item',
    'PUT',
    {
      content_type: this.content_type,
      content_id: this.content_id,
      restricted: locked,
    },
    (function (_this) {
      return function (_response) {
        _this.model.set('restricted_by_master_course', locked)
        _this.trigger(locked ? 'lock' : 'unlock')
        _this.render()
        _this.setFocusToElement()
        _this.closeTooltip()
        return null
      }
    })(this),
    (function (_this) {
      return function (_error) {
        return _this.setFocusToElement()
      }
    })(this)
  )
}

LockButton.prototype.isLocked = function () {
  return this.model.get('restricted_by_master_course')
}

LockButton.prototype.isMasterCourseMasterContent = function () {
  return !!this.model.get('is_master_course_master_content')
}

LockButton.prototype.isMasterCourseChildContent = function () {
  return !!this.model.get('is_master_course_child_content')
}

LockButton.prototype.isMasterCourseContent = function () {
  return this.isMasterCourseMasterContent() || this.isMasterCourseChildContent()
}

LockButton.prototype.reset = function () {
  this.$el.removeClass(this.lockedClass + ' ' + this.unlockedClass + ' ' + this.disabledClass)
  this.$icon.removeClass('icon-lock icon-unlock icon-unlocked')
  this.$el.removeAttr('aria-label')
  return this.closeTooltip()
}

LockButton.prototype.closeTooltip = function () {
  return $('.ui-tooltip').remove()
}

LockButton.prototype.render = function () {
  if (!this.isMasterCourseContent()) {
    return
  }
  this.$el.attr('role', 'button')
  if (!this.disabled) {
    this.$el.attr('tabindex', '0')
  }
  this.$el.html('<i></i><span class="lock-text screenreader-only"></span>')
  this.cacheEls()
  if (this.isLocked()) {
    return this.renderLocked()
  } else {
    return this.renderUnlocked()
  }
}

// when locked can
LockButton.prototype.renderLocked = function () {
  return this.renderState({
    hint: I18n.t('Locked'),
    label: this.lockedText,
    buttonClass: this.lockedClass + ' ' + this.disabledClass,
    iconClass: 'icon-blueprint-lock',
  })
}

LockButton.prototype.renderWillUnlock = function () {
  return this.renderState({
    hint: I18n.t('Unlock'),
    label: this.lockedText,
    buttonClass: this.unlockedClass + ' ' + this.disabledClass,
    iconClass: 'icon-blueprint',
  })
}

LockButton.prototype.renderUnlocking = function () {
  return this.renderState({
    hint: I18n.t('Unlocking...'),
    buttonClass: this.lockedClass + ' ' + this.disabledClass,
    iconClass: 'icon-blueprint-lock',
  })
}

// when unlocked can..
LockButton.prototype.renderUnlocked = function () {
  return this.renderState({
    hint: I18n.t('Unlocked'),
    label: this.unlockedText,
    buttonClass: this.unlockedClass + ' ' + this.disabledClass,
    iconClass: 'icon-blueprint',
  })
}

LockButton.prototype.renderWillLock = function () {
  return this.renderState({
    hint: I18n.t('Lock'),
    label: this.unlockedText,
    buttonClass: this.lockedClass + ' ' + this.disabledClass,
    iconClass: 'icon-blueprint-lock',
  })
}

LockButton.prototype.renderLocking = function () {
  return this.renderState({
    hint: I18n.t('Locking...'),
    buttonClass: this.unlockedClass + ' ' + this.disabledClass,
    iconClass: 'icon-blueprint',
  })
}

LockButton.prototype.renderState = function (options) {
  this.reset()
  this.$el.addClass(options.buttonClass)
  if (!this.disabled) {
    this.$el.attr('aria-pressed', options.buttonClass === this.lockedClass)
  } else {
    this.$el.attr('aria-disabled', true)
  }
  this.$icon.attr('class', options.iconClass)
  this.$text.html('' + htmlEscape(options.label || options.hint))
  return this.$el.attr('title', options.hint) // tooltip picks this up (and htmlEscapes it)
}

export default LockButton
