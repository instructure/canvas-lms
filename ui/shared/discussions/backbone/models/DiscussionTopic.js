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
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import {defaults, result} from 'lodash'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import ParticipantCollection from '../collections/ParticipantCollection'
import DiscussionEntriesCollection from '../collections/DiscussionEntriesCollection'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import DateGroup from '@canvas/date-group/backbone/models/DateGroup'
import axios from '@canvas/axios'

const I18n = useI18nScope('discussion_topics')

const stripTags = function (str) {
  const div = document.createElement('div')
  div.innerHTML = str
  return div.textContent || div.innerText || ''
}

extend(DiscussionTopic, Backbone.Model)

function DiscussionTopic() {
  this.groupCategoryId = this.groupCategoryId.bind(this)
  this.duplicate = this.duplicate.bind(this)
  this.present = this.present.bind(this)
  return DiscussionTopic.__super__.constructor.apply(this, arguments)
}

DiscussionTopic.prototype.resourceName = 'discussion_topics'

DiscussionTopic.prototype.defaults = {
  discussion_type: 'side_comment',
  podcast_enabled: false,
  podcast_has_student_posts: false,
  require_initial_post: false,
  is_announcement: false,
  subscribed: false,
  user_can_see_posts: true,
  subscription_hold: null,
  publishable: true,
  unpublishable: true,
}

DiscussionTopic.prototype.dateAttributes = ['last_reply_at', 'posted_at', 'delayed_post_at']

DiscussionTopic.prototype.initialize = function () {
  this.participants = new ParticipantCollection()
  this.entries = new DiscussionEntriesCollection()
  this.entries.url = (function (_this) {
    return function () {
      return _this.baseUrlWithoutQuerystring() + '/entries'
    }
  })(this)
  return (this.entries.participants = this.participants)
}

DiscussionTopic.prototype.parse = function (json) {
  json.set_assignment = json.assignment != null
  const assign_attributes = json.assignment || {}
  assign_attributes.assignment_overrides || (assign_attributes.assignment_overrides = [])
  assign_attributes.turnitin_settings || (assign_attributes.turnitin_settings = {})
  json.assignment = this.createAssignment(assign_attributes)
  json.publishable = json.can_publish
  json.unpublishable = !json.published || json.can_unpublish
  return json
}

DiscussionTopic.prototype.baseUrlWithoutQuerystring = function () {
  const baseUrl = result(this, 'url')
  return baseUrl.split('?')[0]
}

DiscussionTopic.prototype.createAssignment = function (attributes) {
  const assign = new Assignment(attributes)
  assign.alreadyScoped = true
  return assign
}

// always include assignment in view presentation
DiscussionTopic.prototype.present = function () {
  return Backbone.Model.prototype.toJSON.call(this)
}

DiscussionTopic.prototype.publish = function () {
  return this.updateOneAttribute('published', true)
}

DiscussionTopic.prototype.unpublish = function () {
  return this.updateOneAttribute('published', false)
}

DiscussionTopic.prototype.disabledMessage = function () {
  return I18n.t('cannot_unpublish_with_replies', "Can't unpublish if there are student replies")
}

DiscussionTopic.prototype.topicSubscribe = function () {
  this.set('subscribed', true)
  return $.ajaxJSON(this.baseUrlWithoutQuerystring() + '/subscribed', 'PUT')
}

DiscussionTopic.prototype.topicUnsubscribe = function () {
  this.set('subscribed', false)
  return $.ajaxJSON(this.baseUrlWithoutQuerystring() + '/subscribed', 'DELETE')
}

DiscussionTopic.prototype.toJSON = function () {
  const json = DiscussionTopic.__super__.toJSON.apply(this, arguments)
  let ref, ref1, ref2, ref3
  if (
    ((ref = ENV.MASTER_COURSE_DATA) != null ? ref.is_master_course_child_content : void 0) &&
    ((ref1 = ENV.MASTER_COURSE_DATA) != null
      ? (ref2 = ref1.master_course_restrictions) != null
        ? ref2.content
        : void 0
      : void 0)
  ) {
    delete json.message
  }
  if (!json.set_assignment) {
    delete json.assignment
  }
  Object.assign(json, {
    summary: this.summary(),
    unread_count_tooltip: this.unreadTooltip(),
    reply_count_tooltip: this.replyTooltip(),
    assignment: (ref3 = json.assignment) != null ? ref3.toJSON() : void 0,
    defaultDates: this.defaultDates().toJSON(),
    isRootTopic: this.isRootTopic(),
  })
  if (json.assignment) {
    delete json.assignment.rubric
  }
  return json
}

DiscussionTopic.prototype.duplicate = function (context_type, context_id, callback) {
  return (
    axios
      .post(
        '/api/v1/' +
          context_type +
          's/' +
          context_id +
          '/discussion_topics/' +
          this.id +
          '/duplicate',
        {}
      )
      // eslint-disable-next-line promise/no-callback-in-promise
      .then(callback)
      .catch(showFlashError(I18n.t('Could not duplicate discussion')))
  )
}

DiscussionTopic.prototype.toView = function () {
  return {
    ...this.toJSON(),
    name: this.get('title'),
  }
}

DiscussionTopic.prototype.unreadTooltip = function () {
  return I18n.t(
    'unread_count_tooltip',
    {
      zero: 'No unread replies.',
      one: '1 unread reply.',
      other: '%{count} unread replies.',
    },
    {
      count: this.get('unread_count'),
    }
  )
}

DiscussionTopic.prototype.replyTooltip = function () {
  return I18n.t(
    'reply_count_tooltip',
    {
      zero: 'No replies.',
      one: '1 reply.',
      other: '%{count} replies.',
    },
    {
      count: this.get('discussion_subentry_count'),
    }
  )
}

// this is for getting the topic 'full view' from the api
// see: https://<canvas>/doc/api/discussion_topics.html#method.discussion_topics_api.view
DiscussionTopic.prototype.fetchEntries = function () {
  return $.get(
    this.baseUrlWithoutQuerystring() + '/view',
    (function (_this) {
      return function (arg) {
        const unread_entries = arg.unread_entries
        const forced_entries = arg.forced_entries
        const participants = arg.participants
        const entries = arg.view
        _this.unreadEntries = unread_entries
        _this.forcedEntries = forced_entries
        _this.participants.reset(participants)
        // TODO: handle nested replies and 'new_entries' here
        return _this.entries.reset(entries)
      }
    })(this)
  )
}

DiscussionTopic.prototype.summary = function () {
  return stripTags(this.get('message'))
}

// TODO: this would belong in Backbone.model, but I dont know of others are going to need it much
// or want to commit to this api so I am just putting it here for now
DiscussionTopic.prototype.updateOneAttribute = function (key, value, options) {
  if (options == null) {
    options = {}
  }
  const data = {}
  data[key] = value
  return this.updatePartial(data, options)
}

DiscussionTopic.prototype.updatePartial = function (data, options) {
  if (options == null) {
    options = {}
  }
  if (!options.wait) {
    this.set(data)
  }
  options = defaults(options, {
    data: JSON.stringify(data),
    contentType: 'application/json',
  })
  return this.save({}, options)
}

DiscussionTopic.prototype.positionAfter = function (otherId) {
  this.updateOneAttribute('position_after', otherId, {
    wait: true,
  })
  const collection = this.collection
  const otherIndex = collection.indexOf(collection.get(otherId))
  collection.remove(this, {
    silent: true,
  })
  collection.models.splice(otherIndex, 0, this)
  return collection.reset(collection.models)
}

DiscussionTopic.prototype.defaultDates = function () {
  const group = new DateGroup({
    due_at: this.dueAt(),
    unlock_at: this.unlockAt(),
    lock_at: this.lockAt(),
  })
  return group
}

DiscussionTopic.prototype.dueAt = function () {
  let ref
  return (ref = this.get('assignment')) != null ? ref.get('due_at') : void 0
}

DiscussionTopic.prototype.unlockAt = function () {
  let ref, unlock_at
  if ((unlock_at = (ref = this.get('assignment')) != null ? ref.get('unlock_at') : void 0)) {
    return unlock_at
  }
  return this.get('delayed_post_at')
}

DiscussionTopic.prototype.lockAt = function () {
  let lock_at, ref
  if ((lock_at = (ref = this.get('assignment')) != null ? ref.get('lock_at') : void 0)) {
    return lock_at
  }
  return this.get('lock_at')
}

DiscussionTopic.prototype.focusAfterMoving = function () {
  const $el = $(".discussion[data-id='" + this.get('id') + "']")
  const $prev = $el.prev('.discussion')
  if ($prev.length) {
    return $('.title', $prev)
  } else {
    return $el.closest('.discussion-list')
  }
}

DiscussionTopic.prototype.updateBucket = function (data) {
  let $toFocus
  $toFocus = this.focusAfterMoving()
  defaults(data, {
    pinned: this.get('pinned'),
    locked: this.get('locked'),
  })
  this.set('position', null)
  this.updatePartial(data)
  // assign focus only if it was lost; a discussion in multiple categories might not have actually moved
  if (document.activeElement == null || document.activeElement.nodeName === 'BODY') {
    if ($toFocus.hasClass('discussion-list')) {
      $toFocus = $('.ig-header-title', $toFocus)
    }
    return $toFocus.focus()
  }
}

DiscussionTopic.prototype.isRootTopic = function () {
  return !this.get('root_topic_id') && this.get('group_category_id')
}

DiscussionTopic.prototype.groupCategoryId = function (id) {
  if (!(arguments.length > 0)) {
    return this.get('group_category_id')
  }
  return this.set('group_category_id', id)
}

DiscussionTopic.prototype.canGroup = function () {
  return this.get('can_group')
}

export default DiscussionTopic
