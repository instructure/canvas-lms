define [
  'i18n!conversations'
  'underscore'
  'Backbone'
  'compiled/views/conversations/CourseSelectionView'
  'compiled/views/conversations/SearchView'
  'vendor/bootstrap/bootstrap-dropdown'
  'vendor/bootstrap-select/bootstrap-select'
], (I18n, _, {View}, CourseSelectionView, SearchView) ->

  class InboxHeaderView extends View

    els:
      '#compose-btn'     : '$composeBtn'
      '#reply-btn'       : '$replyBtn'
      '#reply-all-btn'   : '$replyAllBtn'
      '#archive-btn'     : '$archiveBtn'
      '#delete-btn'      : '$deleteBtn'
      '#type-filter'     : '$typeFilter'
      '#course-filter'   : '$courseFilter'
      '#admin-btn'       : '$adminBtn'
      '#mark-unread-btn' : '$markUnreadBtn'
      '#forward-btn'     : '$forwardBtn'
      '#star-toggle-btn' : '$starToggleBtn'
      '#admin-menu'      : '$adminMenu'
      '#sending-message' : '$sendingMessage'
      '#sending-spinner' : '$sendingSpinner'
      '[role=search]'    : '$search'

    events:
      'click #compose-btn':       'onCompose'
      'click #reply-btn':         'onReply'
      'click #reply-all-btn':     'onReplyAll'
      'click #archive-btn':       'onArchive'
      'click #delete-btn':        'onDelete'
      'change #type-filter':      'onFilterChange'
      'change #course-filter':    'onFilterChange'
      'click #mark-unread-btn':   'onMarkUnread'
      'click #forward-btn':       'onForward'
      'click #star-toggle-btn':   'onStarToggle'

    messages:
      star: I18n.t('star', 'Star')
      unstar: I18n.t('unstar', 'Unstar')
      archive: I18n.t('archive', 'Archive')
      unarchive: I18n.t('unarchive', 'Unarchive')
      archive_conversation: I18n.t('archive_conversation', 'Archive conversation')
      unarchive_conversation: I18n.t('unarchive_conversation', 'Unarchive conversation')

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

    onArchive:     (e) -> @trigger('archive')

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
      @onArchivedStateChange(newModel)

    detachModelEvents: (oldModel) ->
      oldModel.off(null, null, this) if oldModel

    attachModelEvents: (newModel) ->
      if newModel
        newModel.on('change:workflow_state', @onReadStateChange, this)
        newModel.on('change:starred', @onStarStateChange, this)

    onReadStateChange: (msg) ->
      @hideForwardBtn(!msg)
      @hideMarkUnreadBtn(!msg || msg.unread())

    onStarStateChange: (msg) ->
      if msg
        key = if msg.starred() then 'unstar' else 'star'
        @$starToggleBtn.text(@messages[key])

    onArchivedStateChange: (msg) ->
      return if !msg
      archived = msg.get('workflow_state') == 'archived'
      @$archiveBtn.find('i').attr('class', if archived then 'icon-remove-from-collection' else 'icon-collection-save')
      @$archiveBtn.attr('title', if archived then @messages['unarchive'] else @messages['archive'])
      @$archiveBtn.find('.screenreader-only')
        .text(if archived then @messages['unarchive_conversation'] else @messages['archive_conversation'])

    filterObj: (obj) -> _.object(_.filter(_.pairs(obj), (x) -> !!x[1]))

    onFilterChange: (e) =>
      @searchView?.autocompleteView.setContext(@courseView.getCurrentCourse())
      @trigger('filter', @filterObj({type: @$typeFilter.val(), course: @$courseFilter.val()}))

    displayState: (state) ->
      @$typeFilter.selectpicker('val', state.type)
      @courseView.setValue(state.course)
      @trigger('course', @courseView.getCurrentCourse())

    toggleMessageBtns: (value) ->
      @toggleReplyBtn(value)
      @toggleReplyAllBtn(value)
      @toggleArchiveBtn(value)
      @toggleDeleteBtn(value)
      @toggleAdminBtn(value)

    toggleReplyBtn:    (value) -> @_toggleBtn(@$replyBtn, value)

    toggleReplyAllBtn: (value) -> @_toggleBtn(@$replyAllBtn, value)
    
    toggleArchiveBtn:  (value) -> @_toggleBtn(@$archiveBtn, value)

    toggleDeleteBtn:   (value) -> @_toggleBtn(@$deleteBtn, value)

    toggleAdminBtn:    (value) -> @_toggleBtn(@$adminBtn, value)

    hideMarkUnreadBtn: (hide) -> if hide then @$markUnreadBtn.parent().detach() else @$adminMenu.prepend(@$markUnreadBtn.parent())

    hideForwardBtn:    (hide) -> if hide then @$forwardBtn.parent().detach() else @$adminMenu.prepend(@$forwardBtn.parent())

    updateAdminMenu: (messages) ->
      @hideMarkUnreadBtn(!messages.length)
      @hideForwardBtn(messages.length > 1)

    focusCompose: ->
      @$composeBtn.focus()

    _toggleBtn: (btn, value) ->
      value = if typeof value is 'undefined' then !btn.prop('disabled') else value
      btn.prop('disabled', value)

    toggleSending: (shouldShow) ->
      @$sendingMessage.toggle(shouldShow)
