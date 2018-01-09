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
  'i18n!discussion_topics'
  'Backbone'
  'jquery'
  '../LockIconView',
  'jst/DiscussionTopics/SummaryView'
  'jst/_avatar'
], (I18n, Backbone, $, LockIconView, template) ->

  class DiscussionTopicSummaryView extends Backbone.View

    tagName: 'li'
    template: template

    @child 'lockIconView', '[data-view=lock-icon]'

    attributes: ->
      'class': "discussion-topic #{@model.get('read_state')} #{if @model.selected then 'selected' else '' }"
      'data-id': @model.id
      'role': "listitem"

    events:
      'change .toggleSelected' : 'toggleSelected'
      'click' : 'openOnClick'
      'click .icon-lock':  'toggleLocked'
      'click .icon-trash': 'onDelete'

    els:
      '.discussion-actions .al-trigger' : '$gearButton'

    # Public: I18n translations.
    messages:
      confirm: I18n.t('Are you sure you want to delete this announcement?')
      deleteSuccessful: I18n.t('flash.removed', 'Announcement successfully deleted.')
      deleteFail: I18n.t('flash.fail', 'Announcement deletion failed.')

    initialize: ->
      @lockIconView = false
      if ENV.permissions.manage_content
        @lockIconView = new LockIconView({
          model: @model,
          unlockedText: I18n.t("%{name} is unlocked. Click to lock.", name: @model.get('title')),
          lockedText: I18n.t("%{name} is locked. Click to unlock", name: @model.get('title')),
          course_id: ENV.COURSE_ID,
          content_id: @model.get('id'),
          content_type: 'discussion_topic'
        })
      super
      @model.on 'change reset', @render, this
      @model.on 'destroy', @remove, this
      @prevEl = null

    toJSON: ->
      json = super
      Object.assign json,
        permissions: Object.assign @options.permissions, json.permissions
        selected: @model.selected
        unread_count_tooltip: (I18n.t 'unread_count_tooltip', {
          zero: 'No unread replies.'
          one: '1 unread reply.'
          other: '%{count} unread replies.'
        }, count: @model.get('unread_count'))

        reply_count_tooltip: (I18n.t 'reply_count_tooltip', {
          zero: 'No replies.',
          one: '1 reply.',
          other: '%{count} replies.'
        }, count: @model.get('discussion_subentry_count'))

        summary: @model.summary()

    render: ->
      super
      @$el.attr @attributes()
      this

    toggleSelected: ->
      @model.selected = !@model.selected
      @model.trigger 'change:selected'
      @$el.toggleClass 'selected', @model.selected

    toggleLocked: (e) =>
      e.preventDefault()
      e.stopPropagation()
      locked = !@model.get('locked')
      pinned = if locked then false else @model.get('pinned')
      @model.save({locked: locked, pinned: pinned}, { success: (model, response, options) =>
        @$gearButton.focus()
      })

    onDelete: (e) =>
      e.preventDefault()
      e.stopPropagation()
      if confirm(@messages.confirm)
        @preservePrevItem()
        @delete()
        @goToPrevItem()
      else
        @$gearButton.focus()

    delete: ->
      @model.destroy
        success : =>
          $.flashMessage @messages.deleteSuccessful
        error : =>
          $.flashError @messages.deleteFail

    preservePrevItem: ->
      prevEl = @$el.prev()
      if prevEl.length != 0
        @prevEl = prevEl.data("id")
      else
        @prevEl = null

    goToPrevItem: ->
      if @prevEl
        prevEl = $(".discussion-topic[data-id=\"#{@prevEl}\"]")
        prevEl.find('.al-trigger').focus()
      else
        $("#searchTerm").focus()

    openOnClick: (event) ->
      window.location = @model.get('html_url') unless $(event.target).closest(':focusable, label').length
