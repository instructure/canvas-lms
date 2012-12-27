define [
  'i18n!conversations.conversations_pane'
  'compiled/conversations/ConversationsList'
  'str/htmlEscape'
  'compiled/util/shortcut'
  'compiled/jquery/offsetFrom'
], (I18n, ConversationsList, h, shortcut) ->

  class
    shortcut this, 'list',
      'baseData'
      'updateItems'
      'isActive'

    constructor: (@app, @$pane) ->
      @list = new ConversationsList(this, @$pane.find('> div.conversations'))
      @selected = []
      @initializeActions()

    initializeActions: ->
      $('#conversations').on 'click', 'a.action_delete_all', (e) =>
        e.preventDefault()
        if confirm I18n.t('confirm.delete_conversation', "Are you sure you want to delete your copy of this conversation? This action cannot be undone.")
          @action($(e.currentTarget), method: 'DELETE')

    updateView: (params) ->
      @list.load params

    action: ($actionNode, options) ->
      conversationId = options.conversationId or
        $actionNode.closest('div.conversations li').data('id') or
        $actionNode.parents('ul[data-id]:first').data('id')
      conversation = @list.item(conversationId)
      options = $.extend(true, {}, {url: @actionUrlFor($actionNode, conversationId)}, options)
      origCb = options.success
      options.success = (data) =>
        @app.addMessage(data.messages[0]) if data.messages?.length
        origCb?(data)
      conversation.inboxAction options

    actionUrlFor: ($actionNode, conversationId) ->
      url = $.replaceTags($actionNode.attr('href'), 'id', conversationId)
      url + (if url.match(/\?/) then '&' else '?') + $.param(@baseData())

    active: ->
      @list.active

    filterMenu: (e) ->
      $conversation = $(e.currentTarget).parents('li:first')
      $list         = $(e.currentTarget).siblings('ul:first')

      # reset visibility of all actions
      $list.find('li').show()

      # get current state of the conversation
      isRead       = $conversation.hasClass('read')
      isStarred    = $conversation.hasClass('starred')
      isPrivate    = $conversation.hasClass('private')
      isSubscribed = !$conversation.hasClass('unsubscribed')
      isArchived   = $conversation.hasClass('archived')

      # set action visibility based on current state
      $list.find('.action_mark_as_read').parent().hide() if isRead
      $list.find('.action_mark_as_unread').parent().hide() unless isRead
      $list.find('.action_star').parent().hide() if isStarred
      $list.find('.action_unstar').parent().hide() unless isStarred
      $list.find('.action_archive').parent().hide() if isArchived
      $list.find('.action_unarchive').parent().hide() unless isArchived
      if isArchived
        $list.find('.action_mark_as_read').parent().hide()
        $list.find('.action_mark_as_unread').parent().hide()
      if isPrivate
        $list.find('.action_subscribe, .action_unsubscribe').parent().hide()
      else
        $list.find('.action_subscribe').parent().hide() if isSubscribed
        $list.find('.action_unsubscribe').parent().hide() unless isSubscribed

    resize: (newHeight) ->
      @list.$scroller.height(newHeight - $('#actions').outerHeight(true))
      @list.fetchVisible()
