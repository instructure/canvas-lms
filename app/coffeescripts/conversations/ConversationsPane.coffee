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
      $contextMenuActions = $('#conversation_actions').find('li a')
      $contextMenuActions.click (e) =>
        e.preventDefault()
        @app.closeMenus()

      $contextMenuActions.filter('.standard_action').click (e) =>
        @action $(e.currentTarget), method: 'PUT'

      $('#action_delete_all').click (e) =>
        if confirm I18n.t('confirm.delete_conversation', "Are you sure you want to delete your copy of this conversation? This action cannot be undone.")
          @action $(e.currentTarget), method: 'DELETE'

    updateView: (params) ->
      @list.load params

    action: ($actionNode, options) ->
      conversationId = options.conversationId ? $actionNode.closest('div.conversations li').data('id')
      conversationId ?= $('#conversation_actions').data('activeConversationId')
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

    openConversationMenu: ($node) ->
      @app.closeMenus()
      # get elements
      elements =
        node         : $node
        container    : $('#conversation_actions')
        conversation : $node.closest 'li'
        parent       : $node.parent()
        lists        : $('#conversation_actions ul')
        listElements : $('#conversation_actions li')
        focusable    : $('a, input, select, textarea')
        actions      :
          markAsRead   : $('#action_mark_as_read').parent()
          markAsUnread : $('#action_mark_as_unread').parent()
          unstar       : $('#action_unstar').parent()
          star         : $('#action_star').parent()
          unsubscribe  : $('#action_unsubscribe').parent()
          subscribe    : $('#action_subscribe').parent()
          forward      : $('#action_forward').parent()
          archive      : $('#action_archive').parent()
          unarchive    : $('#action_unarchive').parent()
          delete       : $('#action_delete').parent()
          deleteAll    : $('#action_delete_all').parent()

      @activeActionMenu = elements.node

      # add selected classes
      elements.parent.addClass 'selected'
      elements.container.addClass 'selected'
      elements.conversation.addClass 'menu_active'

      $container    = elements.container
      $conversation = elements.conversation

      # prep action container
      elements.container.data 'activeConversationId', elements.conversation.data('id')
      elements.lists.removeClass('first last').hide()
      elements.listElements.hide()

      # show/hide relevant links
      elements.actions.markAsRead.show() if elements.conversation.hasClass 'unread'
      elements.actions.markAsUnread.show() if elements.conversation.hasClass 'read'

      if elements.conversation.hasClass 'starred'
        elements.actions.unstar.show()
      else
        elements.actions.star.show()

      if elements.conversation.hasClass('private')
        elements.actions.subscribe.hide()
        elements.actions.unsubscribe.hide()
      else
        elements.actions.unsubscribe.show() unless elements.conversation.hasClass 'unsubscribed'
        elements.actions.subscribe.show() if elements.conversation.hasClass 'unsubscribed'

      elements.actions.forward.show()
      elements.actions.delete.show()
      elements.actions.deleteAll.show()
      if elements.conversation.hasClass 'archived' then elements.actions.unarchive.show() else elements.actions.archive.show()

      $(window).one 'keydown', (e) =>
        return if e.keyCode isnt 9 or e.shiftKey

        elements.focusable.one 'focus.actions_menu', (e) =>
          @nextElement = $(e.target)
          elements.focusable.unbind '.actions_menu'
          elements.container.find('a:visible:first').focus()

          elements.container.find('a:visible:first').bind 'blur.actions_menu', (e), =>
            $(window).one 'keyup', (e) =>
              actionMenuActive = elements.container.find('a:focus').length
              unless actionMenuActive
                elements.container.find('a.visible').unbind '.actions_menu'
                @activeActionMenu.focus()
          elements.container.find('a:visible:last').bind 'blur.actions_menu', (e), =>
            $(window).one 'keyup', (e) =>
              actionMenuActive = elements.container.find('a:focus').length
              unless actionMenuActive
                elements.container.find('a.visible').unbind '.actions_menu'
                @nextElement.focus()
                @closeMenus()

      elements.container.find('li[style*="list-item"]').parent().show()
      elements.groups = elements.container.find('ul[style*="block"]')
      if elements.groups.length
        elements.groups.first().addClass 'first'
        elements.groups.last().addClass 'last'

      offset = elements.node.offsetFrom(elements.container.offsetParent())
      elements.container.css
        left: (offset.left + (elements.node.width() / 2) - (elements.container.width() / 2)),
        top : (offset.top + (elements.node.height() * 0.9))

    resize: (newHeight) ->
      @list.$scroller.height(newHeight - $('#actions').outerHeight(true))
      @list.fetchVisible()
