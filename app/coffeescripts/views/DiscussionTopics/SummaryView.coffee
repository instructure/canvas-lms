define [
  'i18n!discussion_topics'
  'Backbone'
  'jquery'
  'underscore'
  'jst/DiscussionTopics/SummaryView'
  'jst/_avatar'
], (I18n, Backbone, $, _, template) ->

  class DiscussionTopicSummaryView extends Backbone.View

    tagName: 'li'
    template: template

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
      super
      @model.on 'change reset', @render, this
      @model.on 'destroy', @remove, this
      @prevEl = null

    toJSON: ->
      json = super
      _.extend json,
        permissions: _.extend @options.permissions, json.permissions
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
