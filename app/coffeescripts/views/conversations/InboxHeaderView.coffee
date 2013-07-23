define [
  'Backbone'
], ({View}) ->

  class InboxHeaderView extends View

    els:
      '#compose-btn': '$composeBtn'
      '#reply-btn': '$replyBtn'
      '#reply-all-btn': '$replyAllBtn'
      '#delete-btn': '$deleteBtn'
      '#type-filter': '$typeFilter'

    events:
      'click #compose-btn':   'onCompose'
      'click #reply-btn':     'onReply'
      'click #reply-all-btn': 'onReplyAll'
      'click #delete-btn':    'onDelete'
      'change #type-filter':  'onTypeChange'

    onCompose:  (e) -> @trigger('compose')

    onReply:    (e) -> @trigger('reply')

    onReplyAll: (e) -> @trigger('reply-all')

    onDelete:   (e) -> @trigger('delete')

    onTypeChange: (e) -> @trigger('type-filter', @$typeFilter.val())

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
