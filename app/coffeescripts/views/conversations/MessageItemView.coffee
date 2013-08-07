define [
  'i18n!conversations'
  'Backbone'
  'jst/conversations/messageItem'
], (I18n, {View}, template) ->

  class MessageItemView extends View

    tagName: 'li'

    className: 'message-item-view'

    template: template

    els:
      '.message-participants-toggle'     : '$toggle'
      '.message-participants'            : '$participants'
      '.summarized-message-participants' : '$summarized'
      '.full-message-participants'       : '$full'

    events:
      'click'                              : 'onSelect'
      'click .message-participants-toggle' : 'onToggle'

    initialize: ->
      super
      @summarized = @model.get('summarizedParticipants')

    # Internal: Serialize the model for the view.
    #
    # Returns the model's "conversation" key object.
    toJSON: ->
      @model.toJSON().conversation

    # Internal: Update participant lists after render.
    #
    # Returns nothing.
    afterRender: ->
      super
      @updateParticipants(@summarized)

    # Public: Update participant and toggle link text 
    #
    # summarized - A boolean that, if true, will display a summarized list.
    #
    # Returns nothing.
    updateParticipants: (summarized) ->
      element = if summarized then @$summarized else @$full
      @$participants.text(element.text())
      @$toggle.text if summarized
          I18n.t('more_participants', '+%{total} more', total: @model.get('hiddenParticipantCount'))
        else
          I18n.t('hide', 'Hide')

    # Internal: Handle selecting this message.
    #
    # e - Event object.
    #
    # Returns nothing.
    onSelect: (e) ->
      e.preventDefault()
      @model.set('selected', !@model.get('selected'))
      @$el.toggleClass('active', @model.get('selected'))

    # Internal: Handle toggle events between the full and summarized lists.
    #
    # e - Event object.
    #
    # Returns nothing.
    onToggle: (e) ->
      e.preventDefault() and e.stopPropagation()
      @updateParticipants(@summarized = !@summarized)
