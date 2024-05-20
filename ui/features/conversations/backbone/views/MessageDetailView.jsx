//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {debounce} from 'lodash'
import {View} from '@canvas/backbone'
import MessageItemView from './MessageItemView'
import template from '../../jst/messageDetail.handlebars'
import noMessage from '../../jst/noMessage.handlebars'
import React from 'react'
import ReactDOM from 'react-dom'
import {Avatar} from '@instructure/ui-avatar'
import {nanoid} from 'nanoid'

const I18n = useI18nScope('conversations')

export default class MessageDetailView extends View {
  static initClass() {
    this.prototype.events = {
      'click .message-detail-actions .reply-btn': 'onReply',
      'keydown .message-detail-actions .reply-btn': 'onReply',
      'click .message-detail-actions .reply-all-btn': 'onReplyAll',
      'keydown .message-detail-actions .reply-all-btn': 'onReplyAll',
      'click .message-detail-actions .delete-btn': 'onDelete',
      'keydown .message-detail-actions .delete-btn': 'onDelete',
      'click .message-detail-actions .forward-btn': 'onForward',
      'keydown .message-detail-actions .forward-btn': 'onForward',
      'click .message-detail-actions .archive-btn': 'onArchive',
      'keydown .message-detail-actions .archive-btn': 'onArchive',
      'click .message-detail-actions .star-toggle-btn': 'onStarToggle',
      'keydown .message-detail-actions .star-toggle-btn': 'onStarToggle',
      modelChange: 'onModelChange',
      'changed:starred': 'render',
    }

    this.prototype.tagName = 'div'

    this.prototype.messages = {
      star: I18n.t('star', 'Star'),
      unstar: I18n.t('unstar', 'Unstar'),
      archive: I18n.t('archive', 'Archive'),
      unarchive: I18n.t('unarchive', 'Unarchive'),
    }
  }

  render(options = {}) {
    let $template
    super.render(...arguments)
    if (this.model) {
      const context = this.model.toJSON().conversation
      context.starToggleMessage = this.model.starred() ? this.messages.unstar : this.messages.star
      context.archiveToggleMessage =
        this.model.get('workflow_state') === 'archived'
          ? this.messages.unarchive
          : this.messages.archive
      $template = $(template(context))
      this.model.messageCollection.each(message => {
        message.attributes.avatarContainerId = `message-item-avatar-wrapper-${nanoid()}`
        if (!message.get('conversation_id')) {
          message.set('conversation_id', context.id)
        }
        if (context.cannot_reply) {
          message.set('cannot_reply', context.cannot_reply)
        }
        const childView = new MessageItemView({model: message}).render()
        $template.find('.message-content').append(childView.$el)
        ReactDOM.render(
          <Avatar
            name={message?.attributes?.author?.name}
            src={message?.attributes?.author?.avatar_url}
          />,
          $template.find(`#${message.attributes.avatarContainerId}`)[0]
        )
        this.listenTo(childView, 'reply', () =>
          this.trigger('reply', message, `.message-item-view[data-id=${message.id}] .reply-btn`)
        )
        this.listenTo(childView, 'reply-all', () =>
          this.trigger(
            'reply-all',
            message,
            `.message-item-view[data-id=${message.id}] .al-trigger`
          )
        )
        return this.listenTo(childView, 'forward', () =>
          this.trigger('forward', message, `.message-item-view[data-id=${message.id}] .al-trigger`)
        )
      })
    } else {
      $template = noMessage(options)
    }
    this.$el.html($template)

    this.$archiveToggle = this.$el.find('.archive-btn')
    this.$starToggle = this.$el.find('.star-toggle-btn')
    return this
  }

  renderEmptyTimeout() {
    const $template = noMessage({})
    this.$el.html($template)
    this.$archiveToggle = this.$el.find('.archive-btn').click()
    return (this.$starToggle = this.$el.find('.star-toggle-btn'))
  }

  renderEmpty() {
    return setTimeout(() => this.renderEmptyTimeout(), 0)
  }

  onModelChange(newModel) {
    this.detachModelEvents()
    this.model = newModel
    return this.attachModelEvents()
  }

  detachModelEvents() {
    if (this.model) {
      return this.model.off(null, null, this)
    }
  }

  attachModelEvents() {
    if (this.model) {
      return this.model.on(
        'change:starred change:workflow_state',
        debounce(this.updateLabels, 90),
        this
      )
    }
  }

  updateLabels() {
    if (!this.model) return
    this.$starToggle.text(this.model.starred() ? this.messages.unstar : this.messages.star)
    return this.$archiveToggle.text(
      this.model.get('workflow_state') === 'archived'
        ? this.messages.unarchive
        : this.messages.archive
    )
  }

  onStarToggle(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    e.preventDefault()
    this.$el.find('.message-detail-kyle-menu').focus()
    return this.trigger('star-toggle')
  }

  onReply(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    e.preventDefault()
    return this.trigger('reply', null, '.message-detail-actions .reply-btn')
  }

  onReplyAll(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    e.preventDefault()
    return this.trigger('reply-all', null, '.message-detail-actions .al-trigger')
  }

  onForward(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    e.preventDefault()
    return this.trigger('forward', null, '.message-detail-actions .al-trigger')
  }

  onDelete(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    e.preventDefault()
    return this.trigger(
      'delete',
      '.conversations .message-actions:last .star-btn',
      '.message-detail-actions .al-trigger'
    )
  }

  onArchive(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    e.preventDefault()
    return this.trigger(
      'archive',
      '.conversations .message-actions:last .star-btn',
      '.message-detail-actions .al-trigger'
    )
  }
}
MessageDetailView.initClass()
