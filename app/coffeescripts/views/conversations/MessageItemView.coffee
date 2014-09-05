define [
  'i18n!conversations'
  'jquery'
  'underscore'
  'timezone'
  'Backbone'
  'jst/conversations/messageItem'
  'jst/_avatar' # needed by messageItem template
], (I18n, $, _, tz, {View}, template) ->

  class MessageItemView extends View

    tagName: 'li'

    className: 'message-item-view'

    template: template

    els:
      '.message-participants-toggle'     : '$toggle'
      '.message-participants'            : '$participants'
      '.summarized-message-participants' : '$summarized'
      '.full-message-participants'       : '$full'
      '.message-metadata'                : '$metadata'

    events:
      'blur .actions a'                    : 'onActionBlur'
      'click .al-trigger'                  : 'onMenuOpen'
      'click .delete-btn'                  : 'onDelete'
      'click .forward-btn'                 : 'onForward'
      'click .message-participants-toggle' : 'onToggle'
      'click .reply-btn'                   : 'onReply'
      'click .reply-all-btn'               : 'onReplyAll'
      'focus .actions a'                   : 'onActionFocus'

    messages:
      confirmDelete: I18n.t('confirm.delete_message', 'Are you sure you want to delete your copy of this message? This action cannot be undone.')

    initialize: ->
      super
      @summarized = @model.get('summarizedParticipantNames')

    # Internal: Serialize the model for the view.
    #
    # Returns the model's "conversation" key object.
    toJSON: ->
      json = @model.toJSON()
      fudged = $.fudgeDateForProfileTimezone(tz.parse(json.created_at))
      _.extend json,
        created_at: fudged

    # Internal: Update participant lists after render.
    #
    # Returns nothing.
    afterRender: ->
      super
      @updateParticipants(@summarized)
      @$el.attr('data-id', @model.id)

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

    # Internal: Handle toggle events between the full and summarized lists.
    #
    # e - Event object.
    #
    # Returns nothing.
    onToggle: (e) ->
      e.preventDefault()
      @updateParticipants(@summarized = !@summarized)

    # Internal: Reply to this message.
    #
    # e - Event Object.
    #
    # Returns nothing.
    onReply: (e) ->
      e.preventDefault()
      @trigger('reply')

    # Internal: Reply all to this message.
    #
    # e - Event Object.
    #
    # Returns nothing.
    onReplyAll: (e) ->
      e.preventDefault()
      @trigger('reply-all')

    # Internal: Delete this message.
    #
    # e - Event object.
    #
    # Returns nothing.
    onDelete: (e) ->
      e.preventDefault()
      return unless confirm(@messages.confirmDelete)
      url = "/api/v1/conversations/#{@model.get('conversation_id')}/remove_messages"
      $.ajaxJSON(url, 'POST', remove: [@model.id])
      @remove()

    # Internal: Forward this message.
    #
    # e - Event object.
    #
    # Returns nothing.
    onForward: (e) ->
      e.preventDefault()
      @trigger('forward')

    # Internal: Stop any route changes when opening a message's menu.
    #
    # e - Event object.
    #
    # Returns nothing.
    onMenuOpen: (e) ->
      e.preventDefault()

    # Internal: Manage visibility of date/message actions when using keyboard.
    #
    # e - Event object.
    #
    # Returns nothing.
    onActionFocus: (e) ->
      @$metadata.addClass('hover')

    # Internal: Manage visibility of date/message actions when using keyboard.
    #
    # e - Event object.
    #
    # Returns nothing.
    onActionBlur: (e) ->
      @$metadata.removeClass('hover')
