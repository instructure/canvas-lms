/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import I18n from 'i18n!conversations'
import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'
import MessageCollection from 'compiled/collections/MessageCollection'
import MessageListView from 'compiled/views/conversations/MessageListView'
import MessageDetailView from 'compiled/views/conversations/MessageDetailView'
import MessageFormDialog from 'compiled/views/conversations/MessageFormDialog'
import SubmissionCommentFormDialog from 'compiled/views/conversations/SubmissionCommentFormDialog'
import InboxHeaderView from 'compiled/views/conversations/InboxHeaderView'
import deparam from 'compiled/util/deparam'
import CourseCollection from 'compiled/collections/CourseCollection'
import FavoriteCourseCollection from 'compiled/collections/FavoriteCourseCollection'
import GroupCollection from 'compiled/collections/GroupCollection'
import 'compiled/behaviors/unread_conversations'
import 'jquery.disableWhileLoading'
import React from 'react'
import ReactDOM from 'react-dom'
import { decodeQueryString } from 'jsx/shared/queryString'
import ConversationStatusFilter from 'jsx/shared/components/ConversationStatusFilter'

const ConversationsRouter = Backbone.Router.extend({

  routes: {
    '': 'index',
    'filter=:state': 'filter'
  },
  sendingCount: 0,

  initialize () {
    ['onSelected', 'selectConversation', 'onSubmissionReply', 'onReply', 'onReplyAll', 'onArchive',
      'onDelete', 'onCompose', 'onMarkUnread', 'onMarkRead', 'onForward', 'onStarToggle', 'onFilter',
      'onCourse', '_replyFromRemote', '_initViews', 'onSubmit', 'onAddMessage', 'onSubmissionAddMessage',
      'onSearch', 'onKeyDown'].forEach(method => this[method] = this[method].bind(this))
    const dfd = this._initCollections()
    this._initViews()
    this._attachEvents()
    if (this._isRemoteLaunch()) return dfd.then(this._replyFromRemote)
  },

  // Public: Pull a value from the query string.
  //
  // name - The name of the query string param.
  //
  // Returns a string value or null.
  param (name) {
    const regex = new RegExp(`${name}=([^&]+)`)
    const value = window.location.search.match(regex)
    if (value) return decodeURIComponent(value[1])
    return null
  },

  // Internal: Perform a batch update of all selected messages.
  //
  // event - The event to batch (e.g. 'star' or 'destroy').
  // fn - A function called with each selected message. Used for side-effecting.
  //
  // Returns an array of impacted message IDs.
  batchUpdate (event, fn = $.noop) {
    const messages = _.map(this.list.selectedMessages, (message) => {
      fn.call(this, message)
      return message.get('id')
    })
    $.ajaxJSON('/api/v1/conversations', 'PUT', {
      'conversation_ids[]': messages,
      event
    })
    if (event === 'destroy') this.list.selectedMessages = []
    if (event === 'archive' && this.filters.type !== 'sent') this.list.selectedMessages = []
    if (event === 'mark_as_read' && this.filters.type === 'archived') this.list.selectedMessages = []
    if (event === 'unstar' && this.filters.type === 'starred') this.list.selectedMessages = []
    return messages
  },

  lastFetch: null,

  onSelected (model) {
    if (this.lastFetch) this.lastFetch.abort()
    this.header.onModelChange(null, this.model)
    this.detail.onModelChange(null, this.model)
    this.model = model
    const messages = this.list.selectedMessages
    if (messages.length === 0) {
      delete this.detail.model
      return this.detail.render()
    } else if (messages.length > 1) {
      delete this.detail.model

      messages[0].set('canArchive', this.filters.type !== 'sent')
      this.detail.onModelChange(messages[0], null)
      this.detail.render({batch: true})
      this.header.onModelChange(messages[0], null)
      this.header.toggleReplyBtn(true)
      this.header.toggleReplyAllBtn(true)
      this.header.hideForwardBtn(true)
      return
    } else {
      model = this.list.selectedMessage()
      if (model.get('messages')) {
        this.selectConversation(model)
      } else {
        this.lastFetch = model.fetch({
          data: {
            include_participant_contexts: false,
            include_private_conversation_enrollments: false
          },
          success: this.selectConversation
        })
        this.detail.$el.disableWhileLoading(this.lastFetch)
      }
    }
  },

  selectConversation (model) {
    if (model) model.set('canArchive', this.filters.type !== 'sent')

    this.header.onModelChange(model, null)
    this.detail.onModelChange(model, null)
    this.detail.render()
  },

  onSubmissionReply () {
    this.submissionReply.show(this.detail.model, {trigger: $('#submission-reply-btn')})
  },

  onReply (message, trigger) {
    if (this.detail.model.get('for_submission')) {
      this.onSubmissionReply()
    } else {
      this._delegateReply(message, 'reply', trigger)
    }
  },

  onReplyAll (message, trigger) {
    this._delegateReply(message, 'replyAll', trigger)
  },

  _delegateReply (message, type, trigger) {
    this.compose.show(this.detail.model, {to: type, trigger, message})
  },

  onArchive (focusNext, trigger) {
    const action = this.list.selectedMessage().get('workflow_state') === 'archived' ? 'mark_as_read' : 'archive'
    const confirmMessage = action === 'archive'
      ? I18n.t({
          one: 'Are you sure you want to archive your copy of this conversation?',
          other: 'Are you sure you want to archive your copies of these conversations?'
        }, {count: this.list.selectedMessages.length})
      : I18n.t({
          one: 'Are you sure you want to unarchive this conversation?',
          other: 'Are you sure you want to unarchive these conversations?'
        }, {count: this.list.selectedMessages.length})
    if (!confirm(confirmMessage)) {  // eslint-disable-line no-alert
      $(trigger).focus()
      return
    }
    const messages = this.batchUpdate(action, function (m) {
      const newState = action === 'mark_as_read' ? 'read' : 'archived'
      m.set('workflow_state', newState)
      this.header.onArchivedStateChange(m)
    })
    if (_.include(['inbox', 'archived'], this.filters.type)) {
      this.list.collection.remove(messages)
      this.selectConversation(null)
    }
    let $focusNext = $(focusNext)
    if ($focusNext.length === 0) {
      $focusNext = $('#compose-message-recipients')
    }
    $focusNext.focus()
  },

  onDelete (focusNext, trigger) {
    const confirmMsg = I18n.t({
      one: 'Are you sure you want to delete your copy of this conversation? This action cannot be undone.',
      other: 'Are you sure you want to delete your copy of these conversations? This action cannot be undone.'
    }, {count: this.list.selectedMessages.length})
    if (!confirm(confirmMsg)) {
      $(trigger).focus()
      return
    }
    const delmsg = I18n.t({
      one: 'Message Deleted!',
      other: 'Messages Deleted!'
    }, {count: this.list.selectedMessages.length})
    const messages = this.batchUpdate('destroy')
    delete this.detail.model
    this.list.collection.remove(messages)
    this.header.updateUi(null)
    $.flashMessage(delmsg)
    this.detail.render()

    let $focusNext = $(focusNext)
    if ($focusNext.length === 0) {
      $focusNext = $('#compose-message-recipients')
    }
    $focusNext.focus()
  },

  onCompose (e) {
    this.compose.show(null, {trigger: '#compose-btn'})
  },

  index () {
    return this.filter('')
  },

  filter (state) {
    const filters = this.filters = deparam(state)
    this.header.displayState(filters)
    this.selectConversation(null)
    this.list.selectedMessages = []
    this.list.collection.reset()
    if (filters.type === 'submission_comments') {
      _.each(
        ['scope', 'filter', 'filter_mode', 'include_private_conversation_enrollments'],
        this.list.collection.deleteParam,
        this.list.collection
      )
      this.list.collection.url = '/api/v1/users/self/activity_stream'
      this.list.collection.setParam('asset_type', 'Submission')
      if (filters.course) {
        this.list.collection.setParam('context_code', filters.course)
      } else {
        this.list.collection.deleteParam('context_code')
      }
    } else {
      _.each(
        ['context_code', 'asset_type', 'submission_user_id'],
        this.list.collection.deleteParam,
        this.list.collection
      )
      this.list.collection.url = '/api/v1/conversations'
      this.list.collection.setParam('scope', filters.type)
      this.list.collection.setParam('filter', this._currentFilter())
      this.list.collection.setParam('filter_mode', 'and')
      this.list.collection.setParam('include_private_conversation_enrollments', false)
    }
    this.list.collection.fetch()
    this.compose.setDefaultCourse(filters.course)
  },

  onMarkUnread () {
    return this.batchUpdate('mark_as_unread', m => m.toggleReadState(false))
  },

  onMarkRead () {
    return this.batchUpdate('mark_as_read', m => m.toggleReadState(true))
  },

  onForward (message, trigger) {
    let model
    if (message) {
      model = this.detail.model.clone()
      model.handleMessages()
      model.set('messages', _.filter(model.get('messages'), m =>
        m.id === message.id ||
        (_.include(m.participating_user_ids, message.author_id) && m.created_at < message.created_at)
      ))
    } else {
      model = this.detail.model
    }
    this.compose.show(model, {to: 'forward', trigger})
  },

  onStarToggle () {
    const event = this.list.selectedMessage().get('starred') ? 'unstar' : 'star'
    const messages = this.batchUpdate(event, m => m.toggleStarred(event === 'star'))
    if (this.filters.type === 'starred') {
      if (event === 'unstar') this.selectConversation(null)
      return this.list.collection.remove(messages)
    }
  },

  onFilter (filters) {
    // Update the hash. Replace if there isn't already a hash - we're in the
    // process of loading the page if so, and we wouldn't want to create a
    // spurious history entry by not doing so.
    const existingHash = window.location.hash && window.location.hash.substring(1)
    return this.navigate(`filter=${$.param(filters)}`, {trigger: true, replace: !existingHash})
  },

  onCourse (course) {
    return this.list.updateCourse(course)
  },

    // Internal: Determine if a reply was launched from another URL.
    //
    // Returns a boolean.
  _isRemoteLaunch () {
    return !!window.location.search.match(/user_id/)
  },

    // Internal: Open and populate the new message dialog from a remote launch.
    //
    // Returns nothing.
  _replyFromRemote () {
    this.compose.show(null, {
      user: {
        id: this.param('user_id'),
        name: this.param('user_name')
      },
      context: this.param('context_id'),
      remoteLaunch: true
    })
  },

  _initCollections () {
    const gc = new GroupCollection()
    gc.setParam('include[]', 'can_message')
    this.courses = {
      favorites: new FavoriteCourseCollection(),
      all: new CourseCollection(),
      groups: gc
    }
    return this.courses.favorites.fetch()
  },

  _initViews () {
    this._initListView()
    this._initDetailView()
    this._initHeaderView()
    this._initComposeDialog()
    this._initSubmissionCommentReplyDialog()
  },

  _attachEvents () {
    this.list.collection.on('change:selected', this.onSelected)
    this.header.on('compose', this.onCompose)
    this.header.on('reply', this.onReply)
    this.header.on('reply-all', this.onReplyAll)
    this.header.on('archive', this.onArchive)
    this.header.on('delete', this.onDelete)
    this.header.on('filter', this.onFilter)
    this.header.on('course', this.onCourse)
    this.header.on('mark-unread', this.onMarkUnread)
    this.header.on('mark-read', this.onMarkRead)
    this.header.on('forward', this.onForward)
    this.header.on('star-toggle', this.onStarToggle)
    this.header.on('search', this.onSearch)
    this.header.on('submission-reply', this.onReply)
    this.compose.on('close', this.onCloseCompose)
    this.compose.on('addMessage', this.onAddMessage)
    this.compose.on('addMessage', this.list.updateMessage)
    this.compose.on('newConversations', this.onNewConversations)
    this.compose.on('submitting', this.onSubmit)
    this.submissionReply.on('addMessage', this.onSubmissionAddMessage)
    this.submissionReply.on('submitting', this.onSubmit)
    this.detail.on('reply', this.onReply)
    this.detail.on('reply-all', this.onReplyAll)
    this.detail.on('forward', this.onForward)
    this.detail.on('star-toggle', this.onStarToggle)
    this.detail.on('delete', this.onDelete)
    this.detail.on('archive', this.onArchive)
    $(document).ready(this.onPageLoad)
    $(window).keydown(this.onKeyDown)
  },

  onPageLoad (e) {
    $('#main').css({display: 'block'})
  },

  onSubmit (dfd) {
    this._incrementSending(1)
    return dfd.always(() => this._incrementSending(-1))
  },

  onAddMessage (message, conversation) {
    const model = this.list.collection.get(conversation.id)
    if (model && model.get('messages')) {
      message.context_name = model.messageCollection.last().get('context_name')
      model.get('messages').unshift(message)
      model.trigger('change:messages')
      if (model === this.detail.model) {
        return this.detail.render()
      }
    }
  },

  onSubmissionAddMessage (message, submission) {
    const model = this.list.collection.findWhere({submission_id: submission.id})
    if (model && model.get('messages')) {
      model.get('messages').unshift(message)
      model.trigger('change:messages')
      if (model === this.detail.model) {
        return this.detail.render()
      }
    }
  },

  onNewConversations (conversations) {},

  _incrementSending (increment) {
    this.sendingCount += increment
    return this.header.toggleSending(this.sendingCount > 0)
  },

  _currentFilter () {
    let filter = this.searchTokens || []
    if (this.filters.course) filter = filter.concat(this.filters.course)
    return filter
  },

  onSearch (tokens) {
    this.list.collection.reset()
    this.searchTokens = tokens.length ? tokens : null
    if (this.filters.type === 'submission_comments') {
      let match
      if (this.searchTokens && (match = this.searchTokens[0].match(/^user_(\d+)$/))) {
        this.list.collection.setParam('submission_user_id', match[1])
      } else {
        this.list.collection.deleteParam('submission_user_id')
      }
    } else {
      this.list.collection.setParam('filter', this._currentFilter())
    }
    delete this.detail.model
    this.list.selectedMessages = []
    this.detail.render()
    return this.list.collection.fetch()
  },

  _initListView () {
    this.list = new MessageListView({
      collection: new MessageCollection(),
      el: $('.message-list'),
      scrollContainer: $('.message-list-scroller'),
      buffer: 50
    })
    this.list.render()
  },

  _initDetailView () {
    this.detail = new MessageDetailView({el: $('.message-detail')})
    this.detail.render()
  },

  _initHeaderView () {
    const defaultFilter = 'inbox'
    const filters = {
        inbox: I18n.t('Inbox'),
        unread: I18n.t('Unread'),
        starred: I18n.t('Starred'),
        sent: I18n.t('Sent'),
        archived: I18n.t('Archived'),
        submission_comments: I18n.t('Submission Comments')
    }

    // The onArchive function requires the filter to always be set in the url.
    // If you are accessing the page iniitially, the filter will be set to
    // inbox, but we have to update the url here manually to match. Further
    // updates to the url are handled by the filter trigger and backbone history
    const hash = window.location.hash
    const hashParams = hash.substring("#filter=".length)
    const filterType = decodeQueryString(hashParams).filter(i => i.type !== undefined)
    const validFilter = filterType.length === 1 && Object.keys(filters).includes(filterType[0].type)

    let initialFilter
    if (hash.startsWith("#filter=") && validFilter) {
      initialFilter = filterType[0].type
    } else {
      window.location.hash = `#filter=type=${defaultFilter}`
      initialFilter = defaultFilter
    }

    this.header = new InboxHeaderView({el: $('header.panel'), courses: this.courses})
    this.header.render()
    ReactDOM.render(
      <ConversationStatusFilter
        router={this}
        filters={filters}
        defaultFilter={defaultFilter}
        initialFilter={initialFilter}
      />,
      document.getElementById('conversation_filter')
    );
  },

  _initComposeDialog () {
    this.compose = new MessageFormDialog({
      courses: this.courses,
      folderId: ENV.CONVERSATIONS.ATTACHMENTS_FOLDER_ID,
      account_context_code: ENV.CONVERSATIONS.ACCOUNT_CONTEXT_CODE
    })
  },

  _initSubmissionCommentReplyDialog () {
    this.submissionReply = new SubmissionCommentFormDialog()
  },

  onKeyDown (e) {
    const nodeName = e.target.nodeName.toLowerCase()
    if (nodeName === 'input' || nodeName === 'textarea') return
    const ctrl = e.ctrlKey || e.metaKey
    if ((e.which === 65) && ctrl) { // ctrl-a
      e.preventDefault()
      this.list.selectAll()
    }
  }
})

window.conversationsRouter = new ConversationsRouter()
Backbone.history.start()
