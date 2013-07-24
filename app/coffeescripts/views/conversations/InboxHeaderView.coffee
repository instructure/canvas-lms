define [
  'Backbone'
], ({View}) ->

  class InboxHeaderView extends View

    els:
      '#compose-btn':     '$composeBtn'
      '#reply-btn':       '$replyBtn'
      '#reply-all-btn':   '$replyAllBtn'
      '#delete-btn':      '$deleteBtn'
      '#type-filter':     '$typeFilter'
      '#admin-btn':       '$adminBtn'
      '#mark-unread-btn': '$markUnreadBtn'
      '#admin-menu':      '$adminMenu'

    events:
      'click #compose-btn':     'onCompose'
      'click #reply-btn':       'onReply'
      'click #reply-all-btn':   'onReplyAll'
      'click #delete-btn':      'onDelete'
      'change #type-filter':    'onTypeChange'
      'click #mark-unread-btn': 'onMarkUnread'
      'click #forward-btn':     'onForward'

    onCompose:     (e) -> @trigger('compose')

    onReply:       (e) -> @trigger('reply')

    onReplyAll:    (e) -> @trigger('reply-all')

    onDelete:      (e) -> @trigger('delete')

    onTypeChange:  (e) -> @trigger('type-filter', @$typeFilter.val())

    onMarkUnread: (e) ->
      e.preventDefault()
      @trigger('mark-unread')

    onForward: (e) ->
      e.preventDefault()
      @trigger('forward')

    onModelChange: (newModel, oldModel) ->
      @toggleMessageBtns(!newModel.get('selected'))
      oldModel.off(null, null, this) if oldModel
      @onReadStateChange(newModel)
      newModel.on('change:workflow_state', @onReadStateChange, this)

    onReadStateChange: (msg) ->
      @hideMarkUnreadBtn(msg.unread())

    toggleMessageBtns: (value) ->
      @toggleReplyBtn(value)
      @toggleReplyAllBtn(value)
      @toggleDeleteBtn(value)
      @toggleAdminBtn(value)

    toggleReplyBtn:    (value) -> @_toggleBtn(@$replyBtn, value)

    toggleReplyAllBtn: (value) -> @_toggleBtn(@$replyAllBtn, value)

    toggleDeleteBtn:   (value) -> @_toggleBtn(@$deleteBtn, value)

    toggleAdminBtn:    (value) -> @_toggleBtn(@$adminBtn, value)

    hideMarkUnreadBtn: (hide) -> if hide then @$markUnreadBtn.parent().detach() else @$adminMenu.prepend(@$markUnreadBtn.parent())

    _toggleBtn: (btn, value) ->
      value = if typeof value is 'undefined' then !btn.prop('disabled') else value
      btn.prop('disabled', value)
