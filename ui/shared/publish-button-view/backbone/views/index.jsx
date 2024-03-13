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

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import htmlEscape from '@instructure/html-escape'
import '@canvas/jquery/jquery.instructure_forms'
import * as tz from '@canvas/datetime'
import React from 'react'
import ReactDOM from 'react-dom'
import DelayedPublishDialog from '../../react/components/DelayedPublishDialog'

const I18n = useI18nScope('publish_btn_module')

export default (function (superClass) {
  extend(PublishButton, superClass)

  function PublishButton() {
    this.renderDelayedPublish = this.renderDelayedPublish.bind(this)
    return PublishButton.__super__.constructor.apply(this, arguments)
  }

  PublishButton.prototype.disabledClass = 'disabled'

  PublishButton.prototype.publishClass = 'btn-publish'

  PublishButton.prototype.publishedClass = 'btn-published'

  PublishButton.prototype.unpublishClass = 'btn-unpublish'

  // This value allows the text to include the item title
  PublishButton.optionProperty('title')

  // These values allow the default text to be overridden if necessary
  PublishButton.optionProperty('publishText')

  PublishButton.optionProperty('unpublishText')

  // # This indicates that the button is disabled specifically because it is
  // # associated with a moderated assignment that the current user does not
  // # have the Select Final Grade permission.
  PublishButton.optionProperty('disabledForModeration')

  PublishButton.prototype.tagName = 'button'

  PublishButton.prototype.className = 'btn'

  PublishButton.prototype.events = {
    click: 'click',
    mouseenter: 'handleMouseEnter',
    mouseleave: 'handleMouseLeave',
  }

  PublishButton.prototype.els = {
    i: '$icon',
    '.publish-text': '$text',
    '.dpd-mount': '$dpd_mount',
  }

  PublishButton.prototype.initialize = function () {
    let ref
    PublishButton.__super__.initialize.apply(this, arguments)
    return (ref = this.model) != null
      ? ref.on(
          'change:unpublishable',
          (function (_this) {
            return function () {
              if (!_this.model.get('unpublishable') && _this.model.get('published')) {
                return _this.disable()
              }
            }
          })(this)
        )
      : void 0
  }

  PublishButton.prototype.setElement = function () {
    PublishButton.__super__.setElement.apply(this, arguments)
    if (!this.model.get('unpublishable') && this.model.get('published')) {
      return this.disable()
    }
  }

  // events
  PublishButton.prototype.handleMouseEnter = function () {
    if (this.isDelayedPublish()) {
      return
    }
    if (this.keepState || this.isPublish() || this.isDisabled()) {
      return
    }
    this.renderUnpublish()
    this.keepState = true
  }

  PublishButton.prototype.handleMouseLeave = function () {
    this.keepState = false
    if (!(this.isPublish() || this.isDisabled())) {
      this.renderPublished()
    }
  }

  PublishButton.prototype.click = function (event) {
    if (this.isDelayedPublish()) {
      return this.openDelayedPublishDialog()
    }
    event.preventDefault()
    event.stopPropagation()
    if (this.isDisabled()) {
      return
    }
    this.keepState = true
    if (this.isPublish()) {
      return this.publish()
    } else if (this.isUnpublish() || this.isPublished()) {
      return this.unpublish()
    }
  }

  PublishButton.prototype.addAriaLabel = function (label) {
    let $label = this.$el.find('span.screenreader-only.accessible_label')
    if (!$label.length) {
      $label = $('<span class="screenreader-only accessible_label"></span>').appendTo(this.$el)
    }
    $label.text(label)
    return this.$el.attr('aria-label', label)
  }

  PublishButton.prototype.setFocusToElement = function () {
    return this.$el.focus()
  }

  // calling publish/unpublish on the model expects a deferred object
  PublishButton.prototype.publish = function (_event) {
    this.renderPublishing()
    return this.model.publish().always(
      (function (_this) {
        return function () {
          let ref, ref1
          _this.trigger('publish')
          _this.enable()
          _this.render()
          _this.setFocusToElement()
          if (
            !['discussion_topic', 'quiz', 'assignment'].includes(
              _this.model.attributes.module_type
            ) ||
            (_this.model.attributes.module_type === 'discussion_topic' &&
              !((ref = _this.$el[0]) != null
                ? (ref1 = ref.dataset) != null
                  ? ref1.assignmentId
                  : void 0
                : void 0))
          ) {
            return false
          }
          const $sgLink = $(
            '#speed-grader-container-' +
              _this.model.attributes.module_type +
              '-' +
              _this.model.attributes.content_id
          )
          return $sgLink.removeClass('hidden')
        }
      })(this)
    )
  }

  PublishButton.prototype.unpublish = function (_event) {
    this.renderUnpublishing()
    return this.model
      .unpublish()
      .done(
        (function (_this) {
          return function () {
            _this.trigger('unpublish')
            _this.disable()
            _this.render()
            _this.setFocusToElement()
            const $sgLink = $(
              '#speed-grader-container-' +
                _this.model.attributes.module_type +
                '-' +
                _this.model.attributes.content_id
            )
            return $sgLink.addClass('hidden')
          }
        })(this)
      )
      .fail(
        (function (_this) {
          return function (error) {
            if (error.status === 403) {
              $.flashError(_this.model.disabledMessage())
            }
            _this.disable()
            _this.renderPublished()
            return _this.setFocusToElement()
          }
        })(this)
      )
  }

  // state

  PublishButton.prototype.isPublish = function () {
    return this.$el.hasClass(this.publishClass)
  }

  PublishButton.prototype.isPublished = function () {
    return this.$el.hasClass(this.publishedClass)
  }

  PublishButton.prototype.isUnpublish = function () {
    return this.$el.hasClass(this.unpublishClass)
  }

  PublishButton.prototype.isDisabled = function () {
    return this.$el.hasClass(this.disabledClass)
  }

  PublishButton.prototype.isDelayedPublish = function () {
    let ref
    return (
      (typeof ENV !== 'undefined' && ENV !== null
        ? (ref = ENV.FEATURES) != null
          ? ref.scheduled_page_publication
          : void 0
        : void 0) &&
      !this.model.get('published') &&
      this.model.get('publish_at')
    )
  }

  PublishButton.prototype.disable = function () {
    return this.$el.addClass(this.disabledClass)
  }

  PublishButton.prototype.enable = function () {
    return this.$el.removeClass(this.disabledClass)
  }

  PublishButton.prototype.reset = function () {
    this.$el.removeClass(
      this.publishClass +
        ' ' +
        this.publishedClass +
        ' ' +
        this.unpublishClass +
        ' published-status restricted'
    )
    this.$icon.removeClass('icon-publish icon-unpublish icon-unpublished')
    return this.$el.removeAttr('title aria-label')
  }

  PublishButton.prototype.publishLabel = function () {
    if (this.publishText) {
      return this.publishText
    }
    if (this.title) {
      return I18n.t('Unpublished.  Click to publish %{title}.', {
        title: this.title,
      })
    }
    return I18n.t('Unpublished.  Click to publish.')
  }

  PublishButton.prototype.unpublishLabel = function () {
    if (this.unpublishText) {
      return this.unpublishText
    }
    if (this.title) {
      return I18n.t('Published.  Click to unpublish %{title}.', {
        title: this.title,
      })
    }
    return I18n.t('Published.  Click to unpublish.')
  }

  // render

  PublishButton.prototype.render = function () {
    if (!this.$el.is('button')) {
      this.$el.attr('role', 'button')
    }
    this.$el.attr('tabindex', '0')
    this.$el.html('<i></i><span class="publish-text"></span><span class="dpd-mount"></span>')
    this.cacheEls()
    // don't read text of button with screenreader
    this.$text.attr('tabindex', '-1')
    if (this.model.get('published')) {
      this.renderPublished()
    } else if (this.isDelayedPublish()) {
      this.renderDelayedPublish()
    } else {
      this.renderPublish()
    }
    if (this.model.get('bulkPublishInFlight')) {
      this.disable()
    }
    return this
  }

  PublishButton.prototype.renderPublish = function () {
    return this.renderState({
      text: I18n.t('buttons.publish', 'Publish'),
      label: this.publishLabel(),
      buttonClass: this.publishClass,
      iconClass: 'icon-unpublish',
    })
  }

  PublishButton.prototype.renderPublished = function () {
    return this.renderState({
      text: I18n.t('buttons.published', 'Published'),
      label: this.unpublishLabel(),
      buttonClass: this.publishedClass,
      iconClass: 'icon-publish icon-Solid',
    })
  }

  PublishButton.prototype.renderUnpublish = function () {
    const text = I18n.t('buttons.unpublish', 'Unpublish')
    return this.renderState({
      text,
      buttonClass: this.unpublishClass,
      iconClass: 'icon-unpublish',
    })
  }

  PublishButton.prototype.renderPublishing = function () {
    this.disable()
    const text = I18n.t('buttons.publishing', 'Publishing...')
    return this.renderState({
      text,
      buttonClass: this.publishClass,
      iconClass: 'icon-publish icon-Solid',
    })
  }

  PublishButton.prototype.renderUnpublishing = function () {
    this.disable()
    const text = I18n.t('buttons.unpublishing', 'Unpublishing...')
    return this.renderState({
      text,
      buttonClass: this.unpublishClass,
      iconClass: 'icon-unpublished',
    })
  }

  PublishButton.prototype.renderDelayedPublish = function () {
    return this.renderState({
      text: I18n.t('Will publish on %{publish_date}', {
        publish_date: tz.format(this.model.get('publish_at'), 'date.formats.short'),
      }),
      iconClass: 'icon-calendar-month',
      buttonClass: this.$el.is('button') ? '' : 'published-status restricted',
    })
  }

  PublishButton.prototype.renderState = function (options) {
    this.reset()
    this.$el.addClass(options.buttonClass)
    this.$el.attr('aria-pressed', options.buttonClass === this.publishedClass)
    this.$icon.addClass(options.iconClass)
    this.$text.html('&nbsp;' + htmlEscape(options.text))

    // a riff on the code from initPublishButton
    const $row = this.$el.closest('.ig-row')
    $row.toggleClass('ig-published', this.model.get('published'))

    // uneditable because the current user does not have the Select Final
    // Grade permission.
    if (this.model.get('disabledForModeration')) {
      return this.disableWithMessage(
        'You do not have permissions to edit this moderated assignment'
      )
      // unpublishable (i.e., able to be unpublished)
    } else if (this.model.get('unpublishable') == null || this.model.get('unpublishable')) {
      this.enable()
      this.$el.data('tooltip', 'left')
      this.$el.attr('title', options.text)
      if (options.label) {
        return this.addAriaLabel(options.label)
      }
      // editable, but cannot be unpublished because submissions exist
    } else if (this.model.get('published')) {
      return this.disableWithMessage(this.model.disabledMessage())
    }
  }

  PublishButton.prototype.disableWithMessage = function (message) {
    this.disable()
    this.$el.attr('aria-disabled', true)
    this.$el.attr('title', message)
    this.$el.data('tooltip', 'left')
    return this.addAriaLabel(message)
  }

  PublishButton.prototype.openDelayedPublishDialog = function () {
    const props = {
      name: this.model.get('title') || this.model.get('module_item_name'),
      courseId: ENV.COURSE_ID,
      contentId: this.model.get('page_url') || this.model.get('url') || this.model.get('id'),
      publishAt: this.model.get('publish_at'),
      onPublish: (function (_this) {
        return function () {
          return _this.publish()
        }
      })(this),
      onUpdatePublishAt: (function (_this) {
        return function (val) {
          _this.model.set('publish_at', val)
          _this.render()
          return _this.setFocusToElement()
        }
      })(this),
      onClose: (function (_this) {
        return function () {
          return ReactDOM.unmountComponentAtNode(_this.$dpd_mount[0])
        }
      })(this),
    }
    // eslint-disable-next-line react/no-render-return-value
    return ReactDOM.render(React.createElement(DelayedPublishDialog, props), this.$dpd_mount[0])
  }

  return PublishButton
})(Backbone.View)
