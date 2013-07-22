define [
  'Backbone'
], ({View}) ->

  class InboxHeaderView extends View

    els:
      '#compose-btn': '$composeBtn'
      '#reply-btn': '$replyBtn'
      '#reply-all-btn': '$replyAllBtn'
      '#delete-btn': '$deleteBtn'

    events:
      'click #compose-btn':   'onCompose'
      'click #reply-btn':     'onReply'
      'click #reply-all-btn': 'onReplyAll'
      'click #delete-btn':    'onDelete'

    onCompose:  (e) -> @trigger('compose')

    onReply:    (e) -> @trigger('reply')

    onReplyAll: (e) -> @trigger('reply-all')

    onDelete:   (e) -> @trigger('delete')

    toggleMessageBtns: (value) ->
      @toggleReplyBtn(value)
      @toggleReplyAllBtn(value)
      @toggleDeleteBtn(value)

    toggleReplyBtn:    (value) -> @_toggleBtn(@$replyBtn, value)

    toggleReplyAllBtn: (value) -> @_toggleBtn(@$replyAllBtn, value)

    toggleDeleteBtn:   (value) -> @_toggleBtn(@$deleteBtn, value)

    _toggleBtn: (btn, value) ->
      value = if typeof value is 'undefined' then !btn.prop('disabled') else value
      btn.prop('disabled', value)
