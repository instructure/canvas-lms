define [
  'underscore'
  'Backbone'
  'compiled/views/conversations/CourseSelectionView'
  'use!vendor/bootstrap/bootstrap-dropdown'
  'use!vendor/bootstrap-select/bootstrap-select'
], (_, {View}, CourseSelectionView) ->

  class InboxHeaderView extends View

    els:
      '#compose-btn':     '$composeBtn'
      '#reply-btn':       '$replyBtn'
      '#reply-all-btn':   '$replyAllBtn'
      '#delete-btn':      '$deleteBtn'
      '#type-filter':     '$typeFilter'
      '#course-filter':   '$courseFilter'
      '#admin-btn':       '$adminBtn'
      '#mark-unread-btn': '$markUnreadBtn'
      '#admin-menu':      '$adminMenu'

    events:
      'click #compose-btn':       'onCompose'
      'click #reply-btn':         'onReply'
      'click #reply-all-btn':     'onReplyAll'
      'click #delete-btn':        'onDelete'
      'change #type-filter':      'onFilterChange'
      'change #course-filter':    'onFilterChange'
      'click #mark-unread-btn':   'onMarkUnread'
      'click #forward-btn':       'onForward'

    render: () ->
      super()
      @$typeFilter.selectpicker()
      @courseView = new CourseSelectionView(el: @$courseFilter, courses: @options.courses)

    onCompose:     (e) -> @trigger('compose')

    onReply:       (e) -> @trigger('reply')

    onReplyAll:    (e) -> @trigger('reply-all')

    onDelete:      (e) -> @trigger('delete')

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

    filterObj: (obj) -> _.object(_.filter(_.pairs(obj), (x) -> !!x[1]))

    onFilterChange: (e) ->
      @trigger('filter', @filterObj({type: @$typeFilter.val(), course: @$courseFilter.val()}))

    displayState: (state) ->
      @$typeFilter.selectpicker('val', state.type)
      @courseView.setValue(state.course)
      course = @$courseFilter.find('option:selected')
      courseObj = if state.course then {name: course.text(), code: course.data('code')} else {}
      @trigger('course', courseObj)

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

    focusCompose: ->
      @$composeBtn.focus()

    _toggleBtn: (btn, value) ->
      value = if typeof value is 'undefined' then !btn.prop('disabled') else value
      btn.prop('disabled', value)
