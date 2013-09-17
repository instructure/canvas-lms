define [
  'i18n!conversations'
  'underscore'
  'Backbone'
  'compiled/views/conversations/CourseSelectionView'
  'compiled/views/conversations/SearchView'
  'use!vendor/bootstrap/bootstrap-dropdown'
  'use!vendor/bootstrap-select/bootstrap-select'
], (I18n, _, {View}, CourseSelectionView, SearchView) ->

  class InboxHeaderView extends View

    els:
      '#compose-btn'     : '$composeBtn'
      '#reply-btn'       : '$replyBtn'
      '#reply-all-btn'   : '$replyAllBtn'
      '#delete-btn'      : '$deleteBtn'
      '#type-filter'     : '$typeFilter'
      '#course-filter'   : '$courseFilter'
      '#admin-btn'       : '$adminBtn'
      '#mark-unread-btn' : '$markUnreadBtn'
      '#star-toggle-btn' : '$starToggleBtn'
      '#admin-menu'      : '$adminMenu'
      '#sending-message' : '$sendingMessage'
      '#sending-spinner' : '$sendingSpinner'
      '[role=search]'    : '$search'

    events:
      'click #compose-btn':       'onCompose'
      'click #reply-btn':         'onReply'
      'click #reply-all-btn':     'onReplyAll'
      'click #delete-btn':        'onDelete'
      'change #type-filter':      'onFilterChange'
      'change #course-filter':    'onFilterChange'
      'click #mark-unread-btn':   'onMarkUnread'
      'click #forward-btn':       'onForward'
      'click #star-toggle-btn':   'onStarToggle'

    messages:
      star: I18n.t('star', 'Star')
      unstar: I18n.t('unstar', 'Unstar')

    spinnerOptions:
      color: '#fff'
      lines: 10
      length: 2
      radius: 2
      width: 2
      left: 0

    render: () ->
      super()
      @$typeFilter.selectpicker()
      @courseView = new CourseSelectionView(el: @$courseFilter, courses: @options.courses)
      @searchView = new SearchView(el: @$search)
      @searchView.on('search', @onSearch)
      spinner = new Spinner(@spinnerOptions)
      spinner.spin(@$sendingSpinner[0])
      @toggleSending(false)

    onSearch:      (tokens) => @trigger('search', tokens)

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

    onStarToggle: (e) ->
      e.preventDefault()
      @trigger('star-toggle')

    onModelChange: (newModel, oldModel) ->
      @detachModelEvents(oldModel)
      @attachModelEvents(newModel)
      @updateUi(newModel)

    updateUi: (newModel) ->
      @toggleMessageBtns(!newModel || !newModel.get('selected'))
      @onReadStateChange(newModel)
      @onStarStateChange(newModel)

    detachModelEvents: (oldModel) ->
      oldModel.off(null, null, this) if oldModel

    attachModelEvents: (newModel) ->
      if newModel
        newModel.on('change:workflow_state', @onReadStateChange, this)
        newModel.on('change:starred', @onStarStateChange, this)

    onReadStateChange: (msg) ->
      @hideMarkUnreadBtn(!msg || msg.unread())

    onStarStateChange: (msg) ->
      if msg
        key = if msg.starred() then 'unstar' else 'star'
        @$starToggleBtn.text(@messages[key])

    filterObj: (obj) -> _.object(_.filter(_.pairs(obj), (x) -> !!x[1]))

    onFilterChange: (e) =>
      @searchView?.autocompleteView.setContext
        name: @$courseFilter.find(':selected').text().trim()
        id: @$courseFilter.val()
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

    toggleSending: (shouldShow) ->
      @$sendingMessage.toggle(shouldShow)
