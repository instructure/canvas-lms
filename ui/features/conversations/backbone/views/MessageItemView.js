/* eslint-disable no-alert */

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
import {extend} from 'lodash'
import * as tz from '@canvas/datetime'
import {View} from '@canvas/backbone'
import template from '../../jst/messageItem.handlebars'
import '@canvas/avatar/jst/_avatar.handlebars'

const I18n = useI18nScope('conversations')

export default class MessageItemView extends View {
  static initClass() {
    this.prototype.tagName = 'li'

    this.prototype.className = 'message-item-view'

    this.prototype.template = template

    this.prototype.els = {
      '.message-participants-toggle': '$toggle',
      '.message-participants': '$participants',
      '.summarized-message-participants': '$summarized',
      '.full-message-participants': '$full',
      '.message-metadata': '$metadata',
    }

    this.prototype.events = {
      'blur .actions a': 'onActionBlur',
      'click .al-trigger': 'onMenuOpen',
      'keydown .al-trigger': 'onMenuOpen',
      'click .delete-btn': 'onDelete',
      'keydown .delete-btn': 'onDelete',
      'click .forward-btn': 'onForward',
      'keydown .forward-btn': 'onForward',
      'click .message-participants-toggle': 'onToggle',
      'click .reply-btn': 'onReply',
      'keydown .reply-btn': 'onReply',
      'click .reply-all-btn': 'onReplyAll',
      'keydown .reply-all-btn': 'onReplyAll',
      'focus .actions a': 'onActionFocus',
    }

    this.prototype.messages = {
      confirmDelete: I18n.t(
        'confirm.delete_message',
        'Are you sure you want to delete your copy of this message? This action cannot be undone.'
      ),
    }
  }

  initialize() {
    super.initialize(...arguments)
    return (this.summarized = this.model.get('summarizedParticipantNames'))
  }

  // Internal: Serialize the model for the view.
  //
  // Returns the model's "conversation" key object.
  toJSON() {
    const json = this.model.toJSON()
    const fudged = $.fudgeDateForProfileTimezone(tz.parse(json.created_at))
    return extend(json, {created_at: fudged})
  }

  // Internal: Update participant lists after render.
  //
  // Returns nothing.
  afterRender() {
    super.afterRender(...arguments)
    this.updateParticipants(this.summarized)
    return this.$el.attr('data-id', this.model.id)
  }

  // Public: Update participant and toggle link text
  //
  // summarized - A boolean that, if true, will display a summarized list.
  //
  // Returns nothing.
  updateParticipants(summarized) {
    const element = summarized ? this.$summarized : this.$full
    this.$participants.text(element.text())
    return this.$toggle.text(
      summarized
        ? I18n.t('more_participants', '+%{total} more', {
            total: this.model.get('hiddenParticipantCount'),
          })
        : I18n.t('hide', 'Hide')
    )
  }

  // Internal: Handle toggle events between the full and summarized lists.
  //
  // e - Event object.
  //
  // Returns nothing.
  onToggle(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    e.preventDefault()
    return this.updateParticipants((this.summarized = !this.summarized))
  }

  // Internal: Reply to this message.
  //
  // e - Event Object.
  //
  // Returns nothing.
  onReply(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    e.preventDefault()
    return this.trigger('reply')
  }

  // Internal: Reply all to this message.
  //
  // e - Event Object.
  //
  // Returns nothing.
  onReplyAll(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    e.preventDefault()
    return this.trigger('reply-all')
  }

  // Internal: Delete this message.
  //
  // e - Event object.
  //
  // Returns nothing.
  onDelete(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    let $toFocus
    e.preventDefault()
    //
    if (!window.confirm(this.messages.confirmDelete)) {
      $(`.message-item-view[data-id=${this.model.id}] .al-trigger`).focus()
      return
    }
    const prevId = $(this.el).prev().data('id')
    const url = `/api/v1/conversations/${this.model.get('conversation_id')}/remove_messages`
    $.ajaxJSON(url, 'POST', {remove: [this.model.id]})
    this.remove()
    if (prevId) $toFocus = $(`.message-item-view[data-id=${prevId}] .al-trigger`)
    if (!($toFocus != null ? $toFocus.length : undefined))
      $toFocus = $('.message-detail-actions .al-trigger')
    if (!$toFocus.length) $toFocus = $('.conversations .message-actions:last .star-btn')
    if (!$toFocus.length) $toFocus = $('#compose-message-recipients')
    return $toFocus.focus()
  }

  // Internal: Forward this message.
  //
  // e - Event object.
  //
  // Returns nothing.
  onForward(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    e.preventDefault()
    return this.trigger('forward')
  }

  // Internal: Stop any route changes when opening a message's menu.
  //
  // e - Event object.
  //
  // Returns nothing.
  onMenuOpen(e) {
    if (e.keyCode !== 13 && e.keyCode !== 32 && e.keyCode !== undefined) {
      return
    }
    return e.preventDefault()
  }

  // Internal: Manage visibility of date/message actions when using keyboard.
  //
  // e - Event object.
  //
  // Returns nothing.
  onActionFocus() {
    return this.$metadata.addClass('hover')
  }

  // Internal: Manage visibility of date/message actions when using keyboard.
  //
  // e - Event object.
  //
  // Returns nothing.
  onActionBlur() {
    return this.$metadata.removeClass('hover')
  }
}
MessageItemView.initClass()
