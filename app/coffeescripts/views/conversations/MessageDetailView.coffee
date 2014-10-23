define [
  'i18n!conversations'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/Message'
  'compiled/views/conversations/MessageItemView'
  'jst/conversations/messageDetail'
  'jst/conversations/noMessage'
], (I18n, $, _, {View}, Message, MessageItemView, template, noMessage) ->

  class MessageDetailView extends View
    events:
      'click .message-detail-actions .reply-btn':         'onReply'
      'click .message-detail-actions .reply-all-btn':     'onReplyAll'
      'click .message-detail-actions .delete-btn':        'onDelete'
      'click .message-detail-actions .forward-btn':       'onForward'
      'click .message-detail-actions .archive-btn':       'onArchive'
      'click .message-detail-actions .star-toggle-btn':   'onStarToggle'
      'modelChange':              'onModelChange'
      'changed:starred':          'render'

    tagName: 'div'

    messages:
      star: I18n.t('star', 'Star')
      unstar: I18n.t('unstar', 'Unstar')
      archive: I18n.t('archive', 'Archive')
      unarchive: I18n.t('unarchive', 'Unarchive')

    render: (options = {})->
      super
      if @model
        context   = @model.toJSON().conversation
        context.starToggleMessage = if @model.starred() then @messages['unstar'] else @messages['star']
        context.archiveToggleMessage = if @model.get('workflow_state') == 'archived' then @messages['unarchive'] else @messages['archive']
        $template = $(template(context))

        @model.messageCollection.each (message) =>
          message.set('conversation_id', context.id) unless message.get('conversation_id')
          childView = new MessageItemView(model: message).render()
          $template.find('.message-content').append(childView.$el)
          @listenTo(childView, 'reply',     => @trigger('reply', message))
          @listenTo(childView, 'reply-all', => @trigger('reply-all', message))
          @listenTo(childView, 'forward',   => @trigger('forward', message))
      else
        $template = noMessage(options)
      @$el.html($template)
      @$el.find('.subject').focus()

      @$archiveToggle = @$el.find('.archive-btn')
      @$starToggle = @$el.find('.star-toggle-btn')
      this

    onModelChange: (newModel) ->
      @detachModelEvents()
      @model = newModel
      @attachModelEvents()

    detachModelEvents: () ->
      @model.off(null, null, this) if @model

    attachModelEvents: () ->
      @model.on("change:starred change:workflow_state", _.debounce(@updateLabels, 90), this) if @model

    updateLabels: ->
      @$starToggle.text(if @model.starred() then @messages['unstar'] else @messages['star'])
      @$archiveToggle.text(if @model.get('workflow_state') == 'archived' then @messages['unarchive'] else @messages['archive'])

    onStarToggle: (e) ->
      e.preventDefault()
      @trigger('star-toggle')

    onReply: (e) ->
      e.preventDefault()
      @trigger('reply')

    onReplyAll: (e) ->
      e.preventDefault()
      @trigger('reply-all')

    onForward: (e) ->
      e.preventDefault()
      @trigger('forward')

    onDelete: (e) ->
      e.preventDefault()
      @trigger('delete')

    onArchive: (e) ->
      e.preventDefault()
      @trigger('archive')