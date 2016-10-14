define [
  'i18n!conversations'
  'Backbone'
  'underscore'
  'jst/conversations/message'
], (I18n, {View}, _, template) ->

  class MessageView extends View

    tagName: 'li'

    template: template

    els:
      '.star-btn': '$starBtn'
      '.StarButton-LabelContainer': '$starBtnScreenReaderMessage'
      '.read-state': '$readBtn'

    events:
      'click': 'onSelect'
      'click .open-message': 'onSelect'
      'click .star-btn':   'toggleStar'
      'click .read-state': 'toggleRead'
      'mousedown': 'onMouseDown'

    messages:
      read:     I18n.t('mark_as_read', 'Mark as read')
      unread:   I18n.t('mark_as_unread', 'Mark as unread')
      star:     I18n.t('star_conversation', 'Star conversation')
      unstar:   I18n.t('unstar_conversation', 'Unstar conversation')

    initialize: ->
      super
      @attachModel()

    attachModel: ->
      @model.on('change:starred', @setStarBtnChecked)
      @model.on('change:workflow_state', => @$readBtn.toggleClass('read', @model.get('workflow_state') isnt 'unread'))
      @model.on('change:selected', (m) => @$el.toggleClass('active', m.get('selected')))

    onSelect: (e) ->
      e.preventDefault()
      return if e and e.target.className.match(/star|read-state/)
      if e.shiftKey
        return @model.collection.selectRange(@model)
      modifier = e.metaKey or e.ctrlKey
      if @model.get('selected') and modifier then @deselect(modifier) else @select(modifier)

    select: (modifier) ->
      _.each(@model.collection.without(@model), (m) -> m.set('selected', false)) unless modifier
      @model.set('selected', true)
      if @model.unread()
        @model.set('workflow_state', 'read')
        @model.save() if @model.get('for_submission')

    deselect: (modifier) ->
      @model.set('selected', false) if modifier

    setStarBtnCheckedScreenReaderMessage: ->
      text = if @model.starred()
               if @model.get('subject')
                 I18n.t('Starred "%{subject}", Click to unstar.', subject: @model.get('subject'))
               else
                 I18n.t('Starred "(No Subject)", Click to unstar.')
             else
               if @model.get('subject')
                 I18n.t('Not starred "%{subject}", Click to star.', subject: @model.get('subject'))
               else
                 I18n.t('Not starred "(No Subject)", Click to star.')
      @$starBtnScreenReaderMessage.text(text)

    setStarBtnChecked: =>
      @$starBtn.attr
        'aria-checked': @model.starred()
        title: if @model.starred() then @messages.unstar else @messages.star
      @$starBtn.toggleClass('active', @model.starred())
      @setStarBtnCheckedScreenReaderMessage()

    toggleStar: (e) ->
      e.preventDefault()
      @model.toggleStarred()
      @model.save()
      @setStarBtnChecked()

    toggleRead: (e) ->
      e.preventDefault()
      @model.toggleReadState()
      @model.save()
      @$readBtn.attr
        'aria-checked': @model.unread()
        title: if @model.unread() then @messages.read else @messages.unread

    onMouseDown: (e) ->
      if e.shiftKey
        e.preventDefault()
        setTimeout ->
          window.getSelection().removeAllRanges() # IE
        , 0

    toJSON: ->
      @model.toJSON().conversation
