define [
  'Backbone'
  'jst/conversations/message'
], ({View}, template) ->

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

    initialize: ->
      @attachModel()

    attachModel: ->
      @model.on('change:starred', => @$starBtn.toggleClass('active'))
      @model.on('change:workflow_state', => @$readBtn.toggleClass('read', @model.get('workflow_state') isnt 'unread'))
      @model.on('change:selected', (m) => @$el.toggleClass('active', m.get('selected')))

    select: (e) ->
      return if e.target.className.match(/star|read/)
      @model.set('selected', true)
      @model.set('workflow_state', 'read') if @model.unread()

    toggleStar: (e) ->
      e.preventDefault()
      @model.save(starred: !@model.get('starred'))

    toggleRead: (e) ->
      e.preventDefault()
      @model.toggleReadState()
      @model.save()

    toJSON: ->
      @model.toJSON().conversation
