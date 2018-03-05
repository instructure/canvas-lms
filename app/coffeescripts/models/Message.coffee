#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18nObj'
  'jquery'
  'underscore'
  'Backbone'
  '../str/TextHelper'
], (I18n, $, _, {Model, Collection}, TextHelper) ->

  class Message extends Model
    initialize: ->
      @messageCollection = new Collection(this.get('messages') || [])
      @on('change:messages', @handleMessages)

    save: (attrs, opts) ->
      if @get('for_submission')
        $.ajaxJSON "/api/v1/courses/#{@get('course_id')}/assignments/#{@get('assignment_id')}/submissions/#{@get('user_id')}/read.json", if @unread() then 'DELETE' else 'PUT'
      else
        Model.prototype.save.call(this)

    parse: (data) ->
      if data.type == 'Submission'
        data.for_submission = true
        data.subject = "#{data.course.name} - #{data.title}"
        data.subject_url = data.html_url
        data.messages = data.submission_comments
        data.messages.reverse()
        _.each data.messages, (message) ->
          message.author.name = message.author.display_name
          message.bodyHTML = TextHelper.formatMessage(message.comment)
          message.for_submission = true
        data.participants = _.uniq(_.map(data.submission_comments, (m) -> {name: m.author_name}), null, (u) -> u.name)
        data.last_authored_message_at = data.submission_comments[0].created_at
        data.last_message_at = data.submission_comments[0].created_at
        data.message_count = I18n.n(data.submission_comments.length)
        data.last_message = data.submission_comments[0].comment
        data.read = data.read_state
        data.workflow_state = if data.read_state then 'read' else 'unread'
      else if data.messages
        findParticipant = (id) -> _.find(data.participants, id: id)
        _.each data.messages, (message) ->
          message.author = findParticipant(message.author_id)

          message.participants = []
          message.participantNames = []
          for id in message.participating_user_ids when id isnt message.author_id
            if participant = findParticipant(id)
              message.participants.push participant
              message.participantNames.push participant.name

          if message.participants.length > 2
            message.summarizedParticipantNames = message.participantNames.slice(0, 2)
            message.hiddenParticipantCount = message.participants.length - 2
          message.context_name = data.context_name
          message.has_attachments = message.media_comment || message.attachments.length
          message.bodyHTML = TextHelper.formatMessage(message.body)
      data

    handleMessages: ->
      @messageCollection.reset(@get('messages') || [])
      @listenTo(@messageCollection, 'change:selected', @handleSelection)

    handleSelection: (model, value) ->
      return if !value
      @messageCollection.each (m) -> m.set(selected: false) if m != model

    unread: ->
      @get('workflow_state') is 'unread'

    starred: ->
      @get('starred')

    toggleReadState: (set_read) ->
      set_read ?= @unread()
      @set('workflow_state', if set_read then 'read' else 'unread')

    toggleStarred: (setStarred) ->
      setStarred ?= !@starred()
      @set('starred', setStarred)

    timestamp: ->
      lastMessage  = new Date(@get('last_message_at')).getTime()
      lastAuthored = new Date(@get('last_authored_message_at')).getTime()
      new Date(_.max([lastMessage, lastAuthored]))

    toJSON: ->
      { conversation: _.extend(super, unread: @unread(), starred: @starred(), timestamp: @timestamp()) }
