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
import I18n from '@canvas/i18n'
import $ from 'jquery'
import {map, max, find, each, uniqBy} from 'lodash'
import {Model, Collection} from '@canvas/backbone'
import {formatMessage, plainText} from '@canvas/util/TextHelper'

extend(Message, Model)

function Message() {
  return Message.__super__.constructor.apply(this, arguments)
}

Message.prototype.initialize = function () {
  this.messageCollection = new Collection(this.get('messages') || [])
  return this.on('change:messages', this.handleMessages)
}

Message.prototype.save = function (_attrs, _opts) {
  if (this.get('for_submission')) {
    return $.ajaxJSON(
      '/api/v1/courses/' +
        this.get('course_id') +
        '/assignments/' +
        this.get('assignment_id') +
        '/submissions/' +
        this.get('user_id') +
        '/read.json',
      this.unread() ? 'DELETE' : 'PUT'
    )
  } else {
    return Model.prototype.save.call(this)
  }
}

Message.prototype.parse = function (data) {
  let findParticipant
  if (data.type === 'Submission') {
    data.for_submission = true
    data.subject = data.course.name + ' - ' + data.title
    data.subject_url = data.html_url
    data.messages = data.submission_comments
    data.messages.reverse()
    each(data.messages, message => {
      message.author.name = message.author.display_name
      message.bodyHTML = formatMessage(message.comment)
      message.for_submission = true
    })
    data.participants = uniqBy(
      map(data.submission_comments, function (m) {
        return {
          name: m.author_name,
        }
      }),
      function (u) {
        return u.name
      }
    )
    data.last_authored_message_at = data.submission_comments[0].created_at
    data.last_message_at = data.submission_comments[0].created_at
    data.message_count = I18n.n(data.submission_comments.length)
    data.last_message = data.submission_comments[0].comment
    data.read = data.read_state
    data.workflow_state = data.read_state ? 'read' : 'unread'
  } else if (data.messages) {
    findParticipant = function (id) {
      return find(data.participants, {
        id,
      })
    }
    each(data.messages, message => {
      message.author = findParticipant(message.author_id)
      message.participants = []
      message.participantNames = []
      const ref = message.participating_user_ids
      let participant
      for (let i = 0, len = ref.length; i < len; i++) {
        const id = ref[i]
        if (id !== message.author_id) {
          if ((participant = findParticipant(id))) {
            message.participants.push(participant)
            message.participantNames.push({
              name: participant.name,
              pronouns: participant.pronouns,
            })
          }
        }
      }
      if (message.participants.length > 2) {
        message.summarizedParticipantNames = message.participantNames.slice(0, 2)
        message.hiddenParticipantCount = message.participants.length - 2
      }
      message.context_name = data.context_name
      message.has_attachments = message.media_comment || message.attachments.length
      message.bodyHTML = formatMessage(message.body)
      message.text = plainText(message.body)
    })
  }
  return data
}

Message.prototype.handleMessages = function () {
  this.messageCollection.reset(this.get('messages') || [])
  return this.listenTo(this.messageCollection, 'change:selected', this.handleSelection)
}

Message.prototype.handleSelection = function (model, value) {
  if (!value) {
    return
  }
  return this.messageCollection.each(m => {
    if (m !== model) {
      return m.set({
        selected: false,
      })
    }
  })
}

Message.prototype.unread = function () {
  return this.get('workflow_state') === 'unread'
}

Message.prototype.starred = function () {
  return this.get('starred')
}

Message.prototype.toggleReadState = function (set_read) {
  if (set_read == null) {
    set_read = this.unread()
  }
  return this.set('workflow_state', set_read ? 'read' : 'unread')
}

Message.prototype.toggleStarred = function (setStarred) {
  if (setStarred == null) {
    setStarred = !this.starred()
  }
  return this.set('starred', setStarred)
}

Message.prototype.timestamp = function () {
  const lastMessage = new Date(this.get('last_message_at')).getTime()
  const lastAuthored = new Date(this.get('last_authored_message_at')).getTime()
  return new Date(max([lastMessage, lastAuthored]))
}

Message.prototype.toJSON = function () {
  return {
    conversation: {
      ...Message.__super__.toJSON.apply(this, arguments),
      ...{
        unread: this.unread(),
        starred: this.starred(),
        timestamp: this.timestamp(),
      },
    },
  }
}

export default Message
