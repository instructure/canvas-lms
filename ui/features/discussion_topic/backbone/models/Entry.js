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

// TODO: consolidate this into DiscussionEntry

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {isArray, pick, some} from 'lodash'
import Backbone from '@canvas/backbone'
import '@canvas/jquery/jquery.ajaxJSON'

const I18n = useI18nScope('discussions')

const stripTags = function (str) {
  const div = document.createElement('div')
  div.innerHTML = str
  return div.textContent || div.innerText || ''
}

extend(Entry, Backbone.Model)

// Model representing an entry in discussion topic
function Entry() {
  return Entry.__super__.constructor.apply(this, arguments)
}

Entry.prototype.defaults = function () {
  return {
    // Attributes persisted with the server
    id: null,
    parent_id: null,
    message: I18n.t('no_content', 'No Content'),
    user_id: null,
    read_state: 'read',
    forced_read_state: false,
    created_at: null,
    updated_at: null,
    deleted: false,
    attachment: null,

    // Received from API, but not persisted
    replies: [],

    // Client side attributes not persisted with the server
    canAttach: ENV.DISCUSSION.PERMISSIONS.CAN_ATTACH_ENTRIES,

    // so we can branch for new stuff
    new: false,
    highlight: false,
  }
}

Entry.prototype.computedAttributes = [
  'isAuthorsEntry',
  'canModerate',
  'canReply',
  'hiddenName',
  'canRate',
  'speedgraderUrl',
  'inlineReplyLink',
  {
    name: 'allowsSideComments',
    deps: ['parent_id', 'deleted'],
  },
  {
    name: 'allowsThreadedReplies',
    deps: ['deleted'],
  },
  {
    name: 'showBoxReplyLink',
    deps: ['allowsSideComments'],
  },
  {
    name: 'collapsable',
    deps: ['replies', 'allowsSideComments', 'allowsThreadedReplies'],
  },
  {
    name: 'summary',
    deps: ['message'],
  },
]

// We don't follow backbone's route conventions, a method for each
// http method, used in `@sync`
Entry.prototype.read = function () {
  return ENV.DISCUSSION.ENTRY_ROOT_URL + '?ids[]=' + this.get('id')
}

Entry.prototype.create = function () {
  this.set('author', ENV.DISCUSSION.CURRENT_USER)
  const parentId = this.get('parent_id')
  if (parentId === null) {
    return ENV.DISCUSSION.ROOT_REPLY_URL
  } else {
    return ENV.DISCUSSION.REPLY_URL.replace(/:entry_id/, parentId)
  }
}

Entry.prototype.delete = function () {
  return ENV.DISCUSSION.DELETE_URL.replace(/:id/, this.get('id'))
}

Entry.prototype.update = function () {
  return ENV.DISCUSSION.DELETE_URL.replace(/:id/, this.get('id'))
}

Entry.prototype.sync = function (method, model, options) {
  if (options == null) {
    options = {}
  }
  const replies = this.get('replies')
  this.set('replies', [])
  options.url = this[method]()
  const oldComplete = options.complete
  options.complete = (function (_this) {
    return function () {
      _this.set('replies', replies)
      if (oldComplete != null) {
        return oldComplete()
      }
    }
  })(this)
  return Backbone.sync(method, this, options)
}

Entry.prototype.parse = function (data) {
  if (isArray(data)) {
    return data[0]
  } else {
    return data
  }
}

Entry.prototype.toJSON = function () {
  const json = Entry.__super__.toJSON.apply(this, arguments)
  return pick(
    json,
    'id',
    'parent_id',
    'message',
    'user_id',
    'read_state',
    'forced_read_state',
    'created_at',
    'updated_at',
    'deleted',
    'attachment',
    'replies',
    'author'
  )
}

// Computed attribute to determine if the entry was created by
// the current user
Entry.prototype.isAuthorsEntry = function () {
  if (this.get('user_id') + '' === ENV.DISCUSSION.CURRENT_USER.id + '') {
    return true
  }
  return false
}

Entry.prototype.hiddenName = function () {
  let isStudentsEntry
  if (ENV.DISCUSSION.HIDE_STUDENT_NAMES) {
    isStudentsEntry = this.get('user_id') + '' === ENV.DISCUSSION.STUDENT_ID
    if (this.isAuthorsEntry()) {
      return this.get('author').display_name
    } else if (isStudentsEntry) {
      return I18n.t('this_student', 'This Student')
    } else {
      return I18n.t('discussion_participant', 'Discussion Participant')
    }
  }
}

Entry.prototype.ratingString = function () {
  let sum
  if (!(sum = this.get('rating_sum'))) {
    return ''
  }
  return I18n.t(
    'like_count',
    {
      one: '(%{count} like)',
      other: '(%{count} likes)',
    },
    {
      count: sum,
    }
  )
}

// Computed attribute to determine if the entry can be moderated
// by the current user
Entry.prototype.canModerate = function () {
  return (
    (this.isAuthorsEntry() && ENV.DISCUSSION.PERMISSIONS.CAN_MANAGE_OWN) ||
    ENV.DISCUSSION.PERMISSIONS.MODERATE
  )
}

// Computed attribute to determine if the entry can be replied to
// by the current user
Entry.prototype.canReply = function () {
  if (this.get('deleted')) {
    return false
  }
  if (!ENV.DISCUSSION.PERMISSIONS.CAN_REPLY) {
    return false
  }
  return true
}

// Computed attribute to determine if the entry can be liked
// by the current user
Entry.prototype.canRate = function () {
  return ENV.DISCUSSION.PERMISSIONS.CAN_RATE
}

// Computed attribute to determine if an inlineReplyLink should be
// displayed for the entry.
Entry.prototype.inlineReplyLink = function () {
  if (ENV.DISCUSSION.THREADED && (this.allowsThreadedReplies() || this.allowsSideComments())) {
    return true
  }
  return false
}

// Only threaded discussions get the ability to reply in an EntryView
// Directed discussions have the reply form in the EntryCollectionView
Entry.prototype.allowsThreadedReplies = function () {
  if (this.get('deleted')) {
    return false
  }
  if (!ENV.DISCUSSION.PERMISSIONS.CAN_REPLY) {
    return false
  }
  if (!ENV.DISCUSSION.THREADED) {
    return false
  }
  return true
}

Entry.prototype.allowsSideComments = function () {
  if (this.get('deleted')) {
    return false
  }
  if (!ENV.DISCUSSION.PERMISSIONS.CAN_REPLY) {
    return false
  }
  if (ENV.DISCUSSION.THREADED) {
    return false
  }
  if (this.get('parent_id')) {
    return false
  }
  return true
}

Entry.prototype.showBoxReplyLink = function () {
  return this.allowsSideComments()
}

Entry.prototype.collapsable = function () {
  return this.hasChildren() || this.allowsSideComments() || this.allowsThreadedReplies()
}

// Computed attribute
Entry.prototype.speedgraderUrl = function () {
  if (ENV.DISCUSSION.SPEEDGRADER_URL_TEMPLATE) {
    return ENV.DISCUSSION.SPEEDGRADER_URL_TEMPLATE.replace(/%3Astudent_id/, this.get('user_id'))
  }
}

// Computed attribute
Entry.prototype.summary = function () {
  return stripTags(this.get('message'))
}

Entry.prototype.markAsRead = function () {
  this.set('read_state', 'read')
  const url = ENV.DISCUSSION.MARK_READ_URL.replace(/:id/, this.get('id'))
  return $.ajaxJSON(url, 'PUT')
}

// Not familiar enough with Backbone.sync to do this, using ajaxJSON
// Also, we can't just @save() because the mark as read api is a different
// resource altogether
Entry.prototype.markAsUnread = function () {
  this.set({
    read_state: 'unread',
    forced_read_state: true,
  })
  const url = ENV.DISCUSSION.MARK_UNREAD_URL.replace(/:id/, this.get('id'))
  return $.ajaxJSON(url, 'DELETE', {
    forced_read_state: true,
  })
}

Entry.prototype.toggleLike = function () {
  const rating = this.get('rating') ? 0 : 1
  this.set({
    rating,
  })
  const sum = (this.get('rating_sum') || 0) + (rating ? 1 : -1)
  this.set('rating_sum', sum)
  const url = ENV.DISCUSSION.RATE_URL.replace(/:id/, this.get('id'))
  return $.ajaxJSON(url, 'POST', {
    rating,
  })
}

Entry.prototype._hasActiveReplies = function (replies) {
  if (
    some(replies, function (reply) {
      return !reply.deleted
    })
  ) {
    return true
  }
  if (
    some(
      replies,
      (function (_this) {
        return function (reply) {
          return _this._hasActiveReplies(reply.replies)
        }
      })(this)
    )
  ) {
    return true
  }
  return false
}

Entry.prototype.hasActiveReplies = function () {
  return this._hasActiveReplies(this.get('replies'))
}

Entry.prototype.hasChildren = function () {
  return this.get('replies').length > 0
}

export default Entry
