define [
  'i18n!conversations.conversations_list'
  'jquery'
  'compiled/widget/ScrollableList'
  'compiled/conversations/Conversation'
  'jst/conversations/conversationItem'
  'jquery.instructure_date_and_time'
  'jst/_avatar' # needed by conversationItem template
], (I18n, $, ScrollableList, Conversation, conversationItemTemplate) ->

  class extends ScrollableList
    constructor: (@pane, $scroller) ->
      @app = @pane.app
      @$empty = @pane.$pane.find('#no_messages')

      super $scroller,
        model: Conversation
        itemTemplate: @conversationItem
        elementHeight: 76
        itemIdsKey: 'conversation_ids'
        itemsKey: 'conversations'
        sortKey: 'last_message_at'
        sortDir: 'desc'
        baseUrl: '/conversations?include_all_conversation_ids=1&include_beta=1'
        noAutoLoad: true

      $('#menu-wrapper').on('click', 'a.standard_action', @triggerConversationAction)
      @$list.on('click', 'li[data-id] > a.standard_action', @triggerConversationAction)
      @$list.on('mousedown keydown', 'button.al-trigger', @pane.filterMenu.bind(@pane))

      $(window).unload(=> clearTimeout(@markAsUnread))

    triggerConversationAction: (e) =>
      e.preventDefault()
      @pane.action($(e.currentTarget), method: 'PUT')

    baseData: ->
      {scope: @scope, filter: @filters}

    load: (params, cb) ->
      @scope = params.scope
      @filters = params.filter ? []
      super
        sortKey: "#{@lastMessageKey()}_at"
        params: @baseData()
        force: params.force
        loadId: params.id # if set, make sure it's loaded, and scroll into view
        cb: =>
          @emptyCheck()
          cb?()

    # item will either be the loadId's item or null
    loaded: (id, item, $node) =>
      if id and not item? # invalid id (deleted or not relevant to scope/filter)
        @app.updateHashData id: null
      else
        @activate item, $node

    added: (conversation, $node) ->
      @$empty.hide()

    updated: (conversation, $node) ->
      @emptyCheck()
      if @isActive(conversation.id) and conversation.get('workflow_state') is 'unread'
        @markAsUnread = setTimeout =>
          return unless @isActive(conversation.id) and @$item(conversation.id)
          conversation.inboxAction
            method: 'PUT'
            data: {conversation: {workflow_state: 'read'}}
            success: (data) -> data.defer_visibility_check = true
        , 2000

    removed: (data, $node) ->
      @emptyCheck()
      @activate(null) if @isActive(data.id)

    clicked: (e) =>
      # ignore clicks that come from the gear menu
      unless $(e.target).closest('.admin-links').length
        @select $(e.currentTarget).attr('data-id')

    lastMessageKey: ->
      if @scope is 'sent'
        'last_authored_message'
      else
        'last_message'

    emptyCheck: ->
      map = @app.filterNameMap
      text = switch @scope
        when 'unread'   then I18n.t 'no_unread_messages',   'You have no unread messages'
        when 'starred'  then I18n.t 'no_starred_messages',  'You have no starred messages'
        when 'sent'     then I18n.t 'no_sent_messages',     'You have no sent messages'
        when 'archived' then I18n.t 'no_archived_messages', 'You have no archived messages'
        else                 I18n.t 'no_messages',          'You have no messages'
      filterNames = (map[i] for i in @filters when map[i])
      text += " (#{(filterNames.join(', '))})" if filterNames.length
      @$empty.text text
      @$empty.showIf !@$items().length

    select: (id, activate=true) ->
      @ensureSelected(id, activate)
      @app.updateHashData id: id if activate

    isActive: (id) ->
      @active and @active.id is id

    deactivate: ->
      return unless @active and item = @item(@active.id)
      delete @active
      @$item(item.id)?.removeClass('selected')
      @removeItem(item) unless item.get('visible')
      clearTimeout @markAsUnread

    ensureSelected: (id, activate=true) ->
      if activate # deselect any existing selection(s) ... soon we will have bulk conversation actions, so this will make more sense
        @selected = []
        @$items().removeClass('selected')
        @deactivate() unless @isActive(id)
      else
        @selected ?= []
      if id?
        @$item(id).addClass('selected')
        @selected.push id

    activate: (conversation, $node) ->
      if conversation and @isActive(conversation?.id)
        @app.deselectMessages()
        return

      @ensureSelected(conversation?.id)
      @active = conversation

      @app.loadConversation @active, $node, =>
        if $node?.hasClass 'unread'
          # we've already done this server-side
          $node.removeClass('read unread archived').addClass 'read'

    conversationItem: (item) =>
      data = $.extend({}, item.toJSON())

      if data.participants
        for user in data.participants when !@app.userCache[user.id]
          @app.userCache[user.id] = user

      if data.audience
        data.audienceHtml = @app.htmlAudience(data, highlightFilters: true)
        @app.formPane.refresh() if @isActive(data.id)

      data.lastMessage = data[@lastMessageKey()]
      data.lastMessageAt = $.friendlyDatetime($.fudgeDateForProfileTimezone(data[@lastMessageKey() + "_at"]))
      data.hideCount = data.message_count is 1

      classes = (property for property in data.properties)
      classes.push data.workflow_state
      classes.push 'private' if data['private']
      classes.push 'starred' if data.starred
      classes.push 'unsubscribed' unless data.subscribed
      classes.push 'selected' if $.inArray(data.id, @selected) >= 0
      data.classes = classes.join(' ')

      conversationItemTemplate(data)
