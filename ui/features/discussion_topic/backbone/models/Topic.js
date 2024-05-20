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

import {extend as extend1} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {each, extend} from 'lodash'
import Backbone from '@canvas/backbone'
import {asJson, getPrefetchedXHR} from '@canvas/util/xhr'
import BackoffPoller from '@canvas/backoff-poller'
import walk from '../../array-walk'
import erase from '@canvas/array-erase'
import '@canvas/jquery/jquery.ajaxJSON'

const indexOf = [].indexOf

const I18n = useI18nScope('discussions')

const UNKNOWN_AUTHOR = {
  avatar_image_url: null,
  display_name: I18n.t('uknown_author', 'Unknown Author'),
  id: null,
}

extend1(MaterializedDiscussionTopic, Backbone.Model)

// TODO: consolidate this into DiscussionTopic

function MaterializedDiscussionTopic() {
  this.setEntryRoot = this.setEntryRoot.bind(this)
  this.parseNewEntry = this.parseNewEntry.bind(this)
  this.parseEntry = this.parseEntry.bind(this)
  this.setEntryState = this.setEntryState.bind(this)
  return MaterializedDiscussionTopic.__super__.constructor.apply(this, arguments)
}

MaterializedDiscussionTopic.prototype.defaults = {
  view: [],
  entries: [],
  new_entries: [],
  unread_entries: [],
  forced_entries: [],
  entry_ratings: {},
}

MaterializedDiscussionTopic.prototype.url = function () {
  return this.get('root_url')
}

MaterializedDiscussionTopic.prototype.fetch = function (options) {
  if (options == null) {
    options = {}
  }
  return asJson(getPrefetchedXHR(this.url())).then(
    (function (_this) {
      return function (data) {
        _this.set(_this.parse(data))
        return typeof options.success === 'function' ? options.success(_this, data) : void 0
      }
    })(this),
    (function (_this) {
      return function () {
        // this is probably not needed anymore but if anything does go wrong with
        // the fetch request we prefectch from rails, we can use this backoff
        // poller to keep trying.
        const loader = new BackoffPoller(
          _this.url(),
          function (data, xhr) {
            if (xhr.status === 503) {
              return 'continue'
            }
            if (xhr.status !== 200) {
              return 'abort'
            }
            _this.set(_this.parse(data, 200, xhr))
            if (typeof options.success === 'function') {
              options.success(_this, data)
            }
            // TODO: handle options.error
            return 'stop'
          },
          {
            handleErrors: true,
            initialDelay: false,
            // we'll abort after about 10 minutes
            baseInterval: 2000,
            maxAttempts: 12,
            backoffFactor: 1.6,
          }
        )
        return loader.start()
      }
    })(this)
  )
}

MaterializedDiscussionTopic.prototype.markAllAsRead = function () {
  $.ajaxJSON(ENV.DISCUSSION.MARK_ALL_READ_URL, 'PUT', {
    forced_read_state: false,
  })
  return this.setAllReadState('read')
}

MaterializedDiscussionTopic.prototype.markAllAsUnread = function () {
  $.ajaxJSON(ENV.DISCUSSION.MARK_ALL_UNREAD_URL, 'DELETE', {
    forced_read_state: false,
  })
  return this.setAllReadState('unread')
}

MaterializedDiscussionTopic.prototype.setAllReadState = function (newReadState) {
  each(this.flattened, function (entry) {
    entry.read_state = newReadState
  })
}

MaterializedDiscussionTopic.prototype.parse = function (data, _status, _xhr) {
  this.data = data
  // build up entries in @data.entries, mainly because we don't want deleted
  // entries, and deleting them in place messes with our loops
  this.data.entries = []
  // a place to do quick lookups to assign parents and other manipulation
  this.flattened = {}
  // keep track of this so we can know the root_entry_id since the api
  // doesn't return it to us
  this.lastRoot = null
  this.participants = {}
  this.flattenParticipants()
  walk(this.data.view, 'replies', this.parseEntry)
  each(this.data.new_entries, this.parseNewEntry)
  walk(this.data.entries, 'replies', this.setEntryRoot)
  delete this.lastRoot
  return this.data
}

MaterializedDiscussionTopic.prototype.flattenParticipants = function () {
  const ref = this.data.participants
  const results = []
  for (let i = 0, len = ref.length; i < len; i++) {
    const participant = ref[i]
    results.push((this.participants[participant.id] = participant))
  }
  return results
}

MaterializedDiscussionTopic.prototype.setEntryAuthor = function (entry) {
  if (entry.user_id != null) {
    return (entry.author = this.participants[entry.user_id])
  } else {
    return (entry.author = UNKNOWN_AUTHOR)
  }
}

MaterializedDiscussionTopic.prototype.setEntryState = function (entry) {
  let ref, ref1
  entry.parent = this.flattened[entry.parent_id]
  if (((ref = entry.id), indexOf.call(this.data.unread_entries, ref) >= 0)) {
    entry.read_state = 'unread'
  }
  if (((ref1 = entry.id), indexOf.call(this.data.forced_entries, ref1) >= 0)) {
    entry.forced_read_state = true
  }
  entry.rating = this.data.entry_ratings[entry.id]
  this.setEntryAuthor(entry)
  if (entry.editor_id != null) {
    return (entry.editor = this.participants[entry.editor_id])
  }
}

MaterializedDiscussionTopic.prototype.parseEntry = function (entry) {
  this.setEntryState(entry)
  this.flattened[entry.id] = entry
  if (!entry.parent) {
    this.data.entries.push(entry)
  }
  return entry
}

MaterializedDiscussionTopic.prototype.parseNewEntry = function (entry) {
  let base, oldEntry
  this.setEntryState(entry)
  if ((oldEntry = this.flattened[entry.id])) {
    extend(oldEntry, entry)
    return
  }
  this.flattened[entry.id] = entry
  const parent = this.flattened[entry.parent_id]
  entry.parent = parent
  if (entry.parent) {
    return ((base = entry.parent).replies != null ? base.replies : (base.replies = [])).push(entry)
  } else {
    return this.data.entries.push(entry)
  }
}

MaterializedDiscussionTopic.prototype.setEntryRoot = function (entry) {
  if (entry.parent_id != null) {
    entry.root_entry = this.lastRoot
    return (entry.root_entry_id = this.lastRoot.id)
  } else {
    return (this.lastRoot = entry)
  }
}

MaterializedDiscussionTopic.prototype.maybeRemove = function (entry) {
  let ref
  if (entry.deleted && !entry.replies) {
    if (((ref = entry.parent) != null ? ref.replies : void 0) != null) {
      erase(entry.parent.replies, entry)
    }
    return delete this.flattened[entry.id]
  }
}

export default MaterializedDiscussionTopic
