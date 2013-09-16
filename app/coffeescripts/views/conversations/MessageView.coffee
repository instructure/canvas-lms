define [
  'i18n!conversations'
  'Backbone'
  'jst/conversations/message'
], (I18n, {View}, template) ->

  class MessageView extends View

    tagName: 'li'

    template: template

    els:
      '.star-btn': '$starBtn'
      '.read-state': '$readBtn'

    events:
      'click': 'select'
      'click .open-message': 'select'
      'click .star-btn':   'toggleStar'
      'click .read-state': 'toggleRead'

    messages:
      read:     I18n.t('mark_as_read', 'Mark as read')
      unread:   I18n.t('mark_as_unread', 'Mark as unread')
      star:     I18n.t('star_conversation', 'Star conversation')
      unstar:   I18n.t('unstar_conversation', 'Unstar conversation')

    initialize: ->
      super
      @attachModel()

    attachModel: ->
      @model.on('change:starred', => @$starBtn.toggleClass('active'))
      @model.on('change:workflow_state', => @$readBtn.toggleClass('read', @model.get('workflow_state') isnt 'unread'))
      @model.on('change:selected', (m) => @$el.toggleClass('active', m.get('selected')))

    select: (e) ->
      return if e and e.target.className.match(/star|read/)
      @model.collection.each((m) -> m.set('selected', false))
      @model.set('selected', true)
      @model.set('workflow_state', 'read') if @model.unread()

    toggleStar: (e) ->
      e.preventDefault()
      @model.toggleStarred()
      @model.save()
      @$starBtn.attr
        'aria-checked': @model.starred()
        title: if @model.starred() then @messages.unstar else @messages.star

    toggleRead: (e) ->
      e.preventDefault()
      @model.toggleReadState()
      @model.save()
      @$readBtn.attr
        'aria-checked': @model.unread()
        title: if @model.unread() then @messages.read else @messages.unread

    toJSON: ->
      @model.toJSON().conversation
