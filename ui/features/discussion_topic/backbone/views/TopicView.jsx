//
// Copyright (C) 2012 - present Instructure, Inc.
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
import React from 'react'
import ReactDOM from 'react-dom'
import Backbone from '@canvas/backbone'
import DiscussionTopic from '@canvas/discussions/backbone/models/DiscussionTopic'
import EntryView from './EntryView'
import PublishButtonView from '@canvas/publish-button-view'
import replyTemplate from '../../jst/_reply_form.handlebars'
import Reply from '../Reply'
import assignmentRubricDialog from '../../jquery/assignmentRubricDialog'
import * as RceCommandShim from '@canvas/rce-command-shim'
import htmlEscape from '@instructure/html-escape'
import AssignmentExternalTools from '@canvas/assignments/react/AssignmentExternalTools'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'

const I18n = useI18nScope('discussions')

export default class TopicView extends Backbone.View {
  static initClass() {
    this.prototype.events = {
      // #
      // Only catch events for the top level "add reply" form,
      // EntriesView handles the clicks for the other replies
      'click #discussion_topic .discussion-reply-action[data-event]': 'handleEvent',
      'click .add_root_reply': 'addRootReply',
      'click .discussion_locked_toggler': 'toggleLocked',
      'click .toggle_due_dates': 'toggleDueDates',
      'click .topic-subscribe-button': 'subscribeTopic',
      'click .topic-unsubscribe-button': 'unsubscribeTopic',
      'click .mark_all_as_read': 'markAllAsRead',
      'click .mark_all_as_unread': 'markAllAsUnread',
      'click .direct-share-send-to-menu-item': 'openSendTo',
      'click .direct-share-copy-to-menu-item': 'openCopyTo',
    }

    this.prototype.els = {
      '.add_root_reply': '$addRootReply',
      '.topic .discussion-entry-reply-area': '$replyLink',
      '.due_date_wrapper': '$dueDates',
      '.reply-textarea:first': '$textarea',
      '#discussion-toolbar': '$discussionToolbar',
      '.topic-subscribe-button': '$subscribeButton',
      '.topic-unsubscribe-button': '$unsubscribeButton',
      '.announcement_cog': '$announcementCog',
      '#assignment_external_tools': '$AssignmentExternalTools',
    }

    this.prototype.filter = this.prototype.afterRender

    this.prototype.addReplyAttachment = EntryView.prototype.addReplyAttachment

    this.prototype.removeReplyAttachment = EntryView.prototype.removeReplyAttachment
  }

  initialize() {
    super.initialize(...arguments)
    this.model.set('id', ENV.DISCUSSION.TOPIC.ID)
    // overwrite cid so Reply::getModelAttributes gets the right "go to parent" link
    this.model.cid = 'main'
    this.model.set('canAttach', ENV.DISCUSSION.PERMISSIONS.CAN_ATTACH_TOPIC)
    this.filterModel = this.options.filterModel
    this.filterModel.on('change', this.hideIfFiltering, this)
    this.topic = new DiscussionTopic({id: ENV.DISCUSSION.TOPIC.ID})
    // get rid of the /view on /api/vl/courses/x/discusison_topics/x/view
    this.topic.url = ENV.DISCUSSION.ROOT_URL.replace(/\/view/m, '')
    // set initial subscribed state
    this.topic.set('subscribed', ENV.DISCUSSION.TOPIC.IS_SUBSCRIBED)

    // catch when non-root replies are added so we can twiddle the subscribed button
    EntryView.on('addReply', () => this.setSubscribed(true))
    $(window).on('keydown', e => this.handleKeyDown(e))
  }

  hideIfFiltering() {
    if (this.filterModel.hasFilter()) {
      return this.$replyLink.addClass('hidden')
    } else {
      return this.$replyLink.removeClass('hidden')
    }
  }

  afterRender() {
    let $el
    super.afterRender(...arguments)
    assignmentRubricDialog.initTriggers()
    this.$el.toggleClass('side_comment_discussion', !ENV.DISCUSSION.THREADED)
    this.subscriptionStatusChanged()
    if (($el = this.$('#topic_publish_button'))) {
      this.topic.set({
        unpublishable: ENV.DISCUSSION.TOPIC.CAN_UNPUBLISH,
        published: ENV.DISCUSSION.TOPIC.IS_PUBLISHED,
      })
      new PublishButtonView({model: this.topic, el: $el}).render()
    }

    const [context, context_id] = ENV.context_asset_string.split('_')
    if (context === 'course') {
      const elementToRenderInto = this.$AssignmentExternalTools.get(0)
      if (elementToRenderInto) {
        this.AssignmentExternalTools = AssignmentExternalTools.attach(
          elementToRenderInto,
          'assignment_view',
          parseInt(context_id, 10),
          ENV.DISCUSSION.IS_ASSIGNMENT ? parseInt(ENV.DISCUSSION.ASSIGNMENT_ID, 10) : undefined
        )
      }
    }
  }

  toggleLocked(event) {
    // this is weird but Topic.js was not set up to talk to the API for CRUD
    const locked = $(event.currentTarget).data('mark-locked')
    return this.topic.save({locked}).done(() => window.location.reload())
  }

  toggleDueDates(event) {
    event.preventDefault()
    this.$dueDates.toggleClass('hidden')
    $(event.currentTarget).text(
      this.$dueDates.hasClass('hidden')
        ? I18n.t('show_due_dates', 'Show Due Dates')
        : I18n.t('hide_due_dates', 'Hide Due Dates')
    )
  }

  toggleEditorMode(event) {
    event.preventDefault()
    event.stopPropagation()
    RceCommandShim.send(this.$textarea, 'toggle')
  }

  subscribeTopic(event) {
    event.preventDefault()
    this.topic.topicSubscribe()
    this.subscriptionStatusChanged()
    // focus the toggled button if the toggled button was focused
    if (this.$subscribeButton.is(':focus')) {
      return this.$unsubscribeButton.focus()
    }
  }

  unsubscribeTopic(event) {
    event.preventDefault()
    this.topic.topicUnsubscribe()
    this.subscriptionStatusChanged()
    // focus the toggled button if the toggled button was focused
    if (this.$unsubscribeButton.is(':focus')) {
      return this.$subscribeButton.focus()
    }
  }

  subscriptionStatusChanged() {
    const subscribed = this.topic.get('subscribed')
    this.$discussionToolbar.removeClass('subscribed')
    this.$discussionToolbar.removeClass('unsubscribed')
    if (ENV.DISCUSSION.CAN_SUBSCRIBE) {
      if (subscribed) {
        return this.$discussionToolbar.addClass('subscribed')
      } else {
        return this.$discussionToolbar.addClass('unsubscribed')
      }
    }
  }

  // #
  // Adds a root level reply to the main topic
  //
  // @api private
  addReply(event) {
    if (event != null) {
      event.preventDefault()
    }
    if (this.reply == null) {
      this.reply = new Reply(this, {topLevel: true, focus: true})
      this.reply.on('edit', () =>
        this.$addRootReply != null ? this.$addRootReply.hide() : undefined
      )
      this.reply.on('hide', () =>
        this.$addRootReply != null ? this.$addRootReply.show() : undefined
      )
      this.reply.on('save', entry => {
        if (!ENV.DISCUSSION.TOPIC.IS_ANNOUNCEMENT) {
          ENV.DISCUSSION.CAN_SUBSCRIBE = true
          this.topic.set('subscription_hold', false)
        }
        this.setSubscribed(true)
        return this.trigger('addReply', entry)
      })
    }
    this.model.set('notification', '')
    return this.reply.edit()
  }

  // Update subscribed state without posted. Done when replies are posted and
  // user is auto-subscribed.
  setSubscribed(_newValue) {
    this.topic.set('subscribed', true)
    return this.subscriptionStatusChanged()
  }

  // #
  // Handles events for declarative HTML. Right now only catches the reply
  // form allowing EntriesView to handle its own events
  handleEvent(event) {
    // get the element and the method to call
    const el = $(event.currentTarget)
    const method = el.data('event')
    return typeof this[method] === 'function' ? this[method](event, el) : undefined
  }

  render() {
    // erb renders most of this
    if (ENV.DISCUSSION.PERMISSIONS.CAN_REPLY) {
      const modelData = this.model.toJSON()
      modelData.showBoxReplyLink = true
      modelData.root = true
      modelData.title = ENV.DISCUSSION.TOPIC.TITLE
      modelData.isForMainDiscussion = true
      const html = replyTemplate(modelData)
      this.$('#discussion_topic').append(html)
    }
    return super.render(...arguments)
  }

  format(attr, value) {
    if (attr === 'notification') {
      return value
    } else {
      return htmlEscape(value)
    }
  }

  addRootReply(event) {
    const target = $('#discussion_topic .discussion-reply-form')
    this.addReply(event)
    $('html, body').animate({scrollTop: target.offset().top - 100})
  }

  markAllAsRead(event) {
    event.preventDefault()
    this.trigger('markAllAsRead')
    return this.$announcementCog.focus()
  }

  markAllAsUnread(event) {
    event.preventDefault()
    this.trigger('markAllAsUnread')
    return this.$announcementCog.focus()
  }

  openSendTo(event, open = true) {
    if (event) event.preventDefault()
    ReactDOM.render(
      <DirectShareUserModal
        open={open}
        sourceCourseId={ENV.COURSE_ID}
        contentShare={{content_type: 'discussion_topic', content_id: this.topic.id}}
        onDismiss={() => {
          this.openSendTo(null, false)
          this.$announcementCog.focus()
        }}
      />,
      document.getElementById('direct-share-mount-point')
    )
  }

  openCopyTo(event, open = true) {
    if (event) event.preventDefault()
    ReactDOM.render(
      <DirectShareCourseTray
        open={open}
        sourceCourseId={ENV.COURSE_ID}
        contentSelection={{discussion_topics: [this.topic.id]}}
        onDismiss={() => {
          this.openCopyTo(null, false)
          this.$announcementCog.focus()
        }}
      />,
      document.getElementById('direct-share-mount-point')
    )
  }

  handleKeyDown(e) {
    const nodeName = e.target.nodeName.toLowerCase()
    if (
      nodeName === 'input' ||
      nodeName === 'textarea' ||
      document.querySelector('.tox-editor-container') ||
      window.ENV.disable_keyboard_shortcuts
    )
      return
    if (e.which !== 78) return // n
    this.addRootReply(e)
    e.preventDefault()
    return e.stopPropagation()
  }
}
TopicView.initClass()
