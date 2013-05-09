define [
  'Backbone'
  'i18n!discussions'
  'compiled/views/DiscussionTopic/EntryView'
  'jst/discussions/results_entry'
], ({View}, I18n, EntryView, template) ->

  class FilterEntryView extends View

    els:
      '.discussion_entry:first': '$entryContent'
      '.discussion-read-state-btn:first': '$readStateToggle'

    events:
      'click': 'click'
      'click .discussion-read-state-btn': 'toggleRead'

    tagName: 'li'

    className: 'entry'

    template: template

    initialize: ->
      super
      @model.on 'change:read_state', @toggleReadState

    toJSON: ->
      @model.attributes

    click: ->
      @trigger 'click', this

    afterRender: ->
      super
      @setToggleTooltip()

    toggleRead: (e) ->
      e.stopPropagation()
      e.preventDefault()
      if @model.get('read_state') is 'read'
        @model.markAsUnread()
      else
        @model.markAsRead()

    toggleReadState: (model, read_state) =>
      @setToggleTooltip()
      @$entryContent.toggleClass 'unread', read_state is 'unread'
      @$entryContent.toggleClass 'read', read_state is 'read'

    setToggleTooltip: ->
      tooltip = if @model.get('read_state') is 'unread'
        I18n.t('mark_as_read', 'Mark as Read')
      else
        I18n.t('mark_as_unread', 'Mark as Unread')

      @$readStateToggle.attr('title', tooltip)
