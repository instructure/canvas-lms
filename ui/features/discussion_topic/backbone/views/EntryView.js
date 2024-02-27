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
import $ from 'jquery'
import {each, isEmpty, extend as lodashExtend} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import MarkAsReadWatcher from '../MarkAsReadWatcher'
import walk from '../../array-walk'
import Backbone from '@canvas/backbone'
import EntryCollection from '../collections/EntryCollection'
import deletedEntriesTemplate from '../../jst/_deleted_entry.handlebars'
import entryWithRepliesTemplate from '../../jst/entry_with_replies.handlebars'
import entryStatsTemplate from '../../jst/entryStats.handlebars'
import Reply from '../Reply'
import EntryEditor from '../EntryEditor'
import htmlEscape from '@instructure/html-escape'
import {publish} from 'jquery-tinypubsub'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import {isRTL} from '@canvas/i18n/rtlHelper'
import '@canvas/avatar/jst/_avatar.handlebars'
import '../../jst/_reply_form.handlebars'

const I18n = useI18nScope('discussions')

extend(EntryView, Backbone.View)

function EntryView() {
  this.handleKeyDown = this.handleKeyDown.bind(this)
  this.renderRatingSum = this.renderRatingSum.bind(this)
  this.renderRating = this.renderRating.bind(this)
  this.focus = this.focus.bind(this)
  this.renderTree = this.renderTree.bind(this)
  this.toggleDeleted = this.toggleDeleted.bind(this)
  this.toggleReadState = this.toggleReadState.bind(this)
  return EntryView.__super__.constructor.apply(this, arguments)
}

EntryView.instances = {}

EntryView.collapseRootEntries = function () {
  each(this.instances, function (view) {
    if (!view.model.get('parent')) {
      view.collapse()
    }
  })
}

EntryView.expandRootEntries = function () {
  each(this.instances, function (view) {
    if (!view.model.get('parent')) {
      view.expand()
    }
  })
}

EntryView.setAllReadState = function (newReadState) {
  each(this.instances, function (view) {
    view.model.set('read_state', newReadState)
  })
}

EntryView.prototype.els = {
  '.discussion_entry:first': '$entryContent',
  '.replies:first': '$replies',
  '.headerBadges:first': '$headerBadges',
  '.discussion-read-state-btn:first': '$readStateToggle',
  '.discussion-rate-action': '$rateLink',
  '.discussion-rating': '$ratingSum',
}

EntryView.prototype.events = {
  'click .loadDescendants': 'loadDescendants',
  'click [data-event]': 'handleDeclarativeEvent',
  keydown: 'handleKeyDown',
}

EntryView.prototype.defaults = {
  treeView: null,
  descendants: 2,
  children: 5,
  showMoreDescendants: 2,
}

EntryView.prototype.template = entryWithRepliesTemplate

EntryView.prototype.tagName = 'li'

EntryView.prototype.className = 'entry'

EntryView.prototype.initialize = function () {
  EntryView.__super__.initialize.apply(this, arguments)
  this.constructor.instances[this.cid] = this
  this.$el.attr('id', 'entry-' + this.model.get('id'))
  this.$el.toggleClass('no-replies', !this.model.hasActiveReplies())
  if (this.model.get('deleted')) {
    this.$el.addClass('deleted')
  }
  this.model.on('change:deleted', this.toggleDeleted)
  this.model.on('change:read_state', this.toggleReadState)
  this.model.on(
    'change:editor',
    (function (_this) {
      return function (entry) {
        _this.render()
        return entry.trigger('edited')
      }
    })(this)
  )
  this.model.on(
    'change:replies',
    (function (_this) {
      return function (model, value) {
        _this.$el.toggleClass('no-replies', !_this.model.hasActiveReplies())
        if (isEmpty(value)) {
          return delete _this.treeView
        } else {
          return _this.renderTree()
        }
      }
    })(this)
  )
  this.model.on('change:rating', this.renderRating)
  return this.model.on('change:rating_sum', this.renderRatingSum)
}

EntryView.prototype.toggleRead = function (e) {
  e.preventDefault()
  if (this.model.get('read_state') === 'read') {
    this.model.markAsUnread()
  } else {
    this.model.markAsRead()
  }
  return EntryView.trigger('readStateChanged', this.model, this)
}

EntryView.prototype.handleDeclarativeEvent = function (event) {
  const $el = $(event.currentTarget)
  const method = $el.data('event')
  if (this.bypass(event)) {
    return
  }
  event.stopPropagation()
  event.preventDefault()
  return this[method](event, $el)
}

EntryView.prototype.bypass = function (event) {
  const target = $(event.target)
  if (target.data('bypass') != null) {
    return true
  }
  const clickedAdminLinks = $(event.target).closest('.admin-links').length
  const targetHasEvent = $(event.target).data('event')
  if (clickedAdminLinks && !targetHasEvent) {
    return true
  } else {
    return false
  }
}

EntryView.prototype.toJSON = function () {
  const json = this.model.attributes
  // for discussion entries, do not make the avatar a link
  if (json.author) {
    json.author.no_avatar_link = true
  }
  json.edited_at = $.datetimeString(json.updated_at)
  if (json.editor) {
    json.editor_name = json.editor.display_name
    json.editor_href = json.editor.html_url
  } else {
    json.editor_name = I18n.t('unknown', 'Unknown')
    json.editor_href = ''
  }
  return json
}

EntryView.prototype.toggleReadState = function (model, read_state) {
  this.setToggleTooltip()
  this.$entryContent.toggleClass('unread', read_state === 'unread')
  return this.$entryContent.toggleClass('read', read_state === 'read')
}

EntryView.prototype.toggleCollapsed = function (event, $el) {
  if (!this.addedCountsToHeader) {
    this.addCountsToHeader()
  }
  this.$el.toggleClass('collapsed')
  if (this.$el.hasClass('collapsed')) {
    return $el.find('.screenreader-only').text(I18n.t('Expand Subdiscussion'))
  } else {
    return $el.find('.screenreader-only').text(I18n.t('Collapse Subdiscussion'))
  }
}

EntryView.prototype.expand = function () {
  return this.$el.removeClass('collapsed')
}

EntryView.prototype.collapse = function () {
  if (!this.addedCountsToHeader) {
    this.addCountsToHeader()
  }
  return this.$el.addClass('collapsed')
}

EntryView.prototype.addCountsToHeader = function () {
  const stats = this.countPosterity()
  this.$headerBadges.append(
    entryStatsTemplate({
      stats,
    })
  )
  return (this.addedCountsToHeader = true)
}

EntryView.prototype.toggleDeleted = function (model, deleted) {
  this.$el.toggleClass('deleted', deleted)
  this.$entryContent.toggleClass('deleted-discussion-entry', deleted)
  if (deleted) {
    this.model.set('updated_at', new Date().toISOString())
    return this.model.set('editor', ENV.current_user)
  }
}

EntryView.prototype.setToggleTooltip = function () {
  const tooltip =
    this.model.get('read_state') === 'unread'
      ? I18n.t('mark_as_read', 'Mark as Read')
      : I18n.t('mark_as_unread', 'Mark as Unread')
  return this.$readStateToggle.attr('title', tooltip)
}

EntryView.prototype.afterRender = function () {
  EntryView.__super__.afterRender.apply(this, arguments)
  const directionToPad = isRTL() ? 'right' : 'left'
  const shouldPosition = this.$el.find('.entry-content[data-should-position]')
  const level = shouldPosition.parents('li.entry').length
  const offset = (level - 1) * 30
  shouldPosition.css('padding-' + directionToPad, offset)
  shouldPosition.find('.discussion-title').attr({
    role: 'heading',
    'aria-level': level + 1,
  })
  if (this.options.collapsed) {
    this.collapse()
  }
  this.setToggleTooltip()
  this.renderRating()
  this.renderRatingSum()
  if (
    this.model.get('read_state') === 'unread' &&
    !this.model.get('forced_read_state') &&
    !ENV.DISCUSSION.MANUAL_MARK_AS_READ
  ) {
    if (this.readMarker == null) {
      this.readMarker = new MarkAsReadWatcher(this)
    }
    MarkAsReadWatcher.checkForVisibleEntries()
  }
  return publish('userContent/change')
}

EntryView.prototype.filter = EntryView.prototype.afterRender

EntryView.prototype.renderTree = function (opts) {
  if (opts == null) {
    opts = {}
  }
  if (this.treeView != null) {
    return
  }
  const replies = this.model.get('replies')
  const descendants = (opts.descendants || this.options.descendants) - 1
  const children = opts.children || this.options.children
  const collection = new EntryCollection(replies, {
    perPage: children,
  })
  const page = collection.getPageAsCollection(0)
  // eslint-disable-next-line new-cap
  this.treeView = new this.options.treeView({
    el: this.$replies[0],
    descendants,
    collection: page,
    threaded: this.options.threaded,
    showMoreDescendants: this.options.showMoreDescendants,
  })
  this.treeView.render()
  const boundReplies = collection.map(function (x) {
    return x.attributes
  })
  return this.model.set('replies', boundReplies)
}

EntryView.prototype.renderDescendantsLink = function () {
  const stats = this.countPosterity()
  this.$descendantsLink = $('<div/>')
  this.$descendantsLink.html(
    entryStatsTemplate({
      stats,
      showMore: true,
    })
  )
  this.$descendantsLink.addClass('showMore loadDescendants')
  return this.$replies.append(this.$descendantsLink)
}

EntryView.prototype.countPosterity = function () {
  const stats = {
    unread: 0,
    total: 0,
  }
  if (this.model.attributes.replies == null) {
    return stats
  }
  walk(this.model.attributes.replies, 'replies', function (entry) {
    if (entry.read_state === 'unread') {
      stats.unread++
    }
    return stats.total++
  })
  return stats
}

EntryView.prototype.loadDescendants = function (event) {
  event.stopPropagation()
  event.preventDefault()
  return this.renderTree({
    children: this.options.children,
    descendants: this.options.showMoreDescendants,
  })
}

EntryView.prototype.remove = function () {
  let html
  if (!this.model.canModerate()) {
    return
  }
  if (
    // eslint-disable-next-line no-alert
    window.confirm(I18n.t('are_your_sure_delete', 'Are you sure you want to delete this entry?'))
  ) {
    this.model.set('deleted', true)
    this.model.destroy()
    html = deletedEntriesTemplate(this.toJSON())
    return this.$('.entry-content:first').html(html)
  }
}

EntryView.prototype.edit = function () {
  if (!this.model.canModerate()) {
    return
  }
  if (this.editor == null) {
    this.editor = new EntryEditor(this)
  }
  if (!this.editor.editing) {
    this.editor.edit()
  }
  return this.editor.on(
    'display',
    (function (_this) {
      return function () {
        return setTimeout(_this.focus, 0)
      }
    })(this)
  )
}

EntryView.prototype.focus = function () {
  return this.$('.author').first().focus()
}

EntryView.prototype.addReply = function (_event, _$el) {
  if (this.reply == null) {
    this.reply = new Reply(this, {
      focus: true,
    })
  }
  this.model.set('notification', '')
  this.reply.edit()
  return this.reply.on(
    'save',
    (function (_this) {
      return function (entry) {
        _this.renderTree()
        _this.treeView.collection.add(entry)
        _this.treeView.collection.fullCollection.add(entry)
        _this.model.get('replies').push(entry.attributes)
        _this.trigger('addReply')
        return EntryView.trigger('addReply', entry)
      }
    })(this)
  )
}

EntryView.prototype.toggleLike = function (e) {
  e.preventDefault()
  return this.model.toggleLike()
}

EntryView.prototype.renderRating = function () {
  this.$rateLink.toggleClass('discussion-rate-action--checked', !!this.model.get('rating'))
  return this.$rateLink.attr(
    'aria-label',
    this.model.get('rating') ? I18n.t('Unlike this Entry') : I18n.t('Like this Entry')
  )
}

EntryView.prototype.renderRatingSum = function () {
  return this.$ratingSum.text(this.model.ratingString())
}

EntryView.prototype.addReplyAttachment = function (event, $el) {
  event.preventDefault()
  return this.reply.addAttachment($el)
}

EntryView.prototype.removeReplyAttachment = function (event, $el) {
  event.preventDefault()
  return this.reply.removeAttachment($el)
}

EntryView.prototype.format = function (attr, value) {
  if (attr === 'message') {
    value = apiUserContent.convert(value)
    this.$el.find('.message').removeClass('enhanced')
    publish('userContent/change')
    return value
  } else if (attr === 'notification') {
    return value
  } else {
    return htmlEscape(value)
  }
}

EntryView.prototype.handleKeyDown = function (e) {
  const nodeName = e.target.nodeName.toLowerCase()
  if (nodeName === 'input' || nodeName === 'textarea' || ENV.disable_keyboard_shortcuts) {
    return
  }
  if (e.which === 68) {
    this.remove()
  } else if (e.which === 69) {
    this.edit()
  } else if (e.which === 82) {
    this.addReply()
  } else {
    return
  }
  e.preventDefault()
  return e.stopPropagation()
}

export default lodashExtend(EntryView, Backbone.Events)
