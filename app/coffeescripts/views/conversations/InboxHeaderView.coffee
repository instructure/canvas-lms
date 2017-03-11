define [
  'jquery'
  'i18n!conversations'
  'underscore'
  'Backbone'
  'spin.js'
  'compiled/views/conversations/CourseSelectionView'
  'compiled/views/conversations/SearchView'
  'vendor/bootstrap/bootstrap-dropdown'
  'vendor/bootstrap-select/bootstrap-select'
], ($, I18n, _, {View}, Spinner, CourseSelectionView, SearchView) ->

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
      '#mark-read-btn'   : '$markReadBtn'
      '#forward-btn'     : '$forwardBtn'
      '#star-toggle-btn' : '$starToggleBtn'
      '#admin-menu'      : '$adminMenu'
      '#sending-message' : '$sendingMessage'
      '#sending-spinner' : '$sendingSpinner'
      '[role=search]'    : '$search'
      '#conversation-actions'       : '$conversationActions'
      '#submission-comment-actions' : '$submissionCommentActions'
      '#submission-reply-btn'       : '$submissionReplyBtn'

    events:
      'click #compose-btn':       'onCompose'
      'click #reply-btn':         'onReply'
      'click #reply-all-btn':     'onReplyAll'
      'click #archive-btn':       'onArchive'
      'click #delete-btn':        'onDelete'
      'change #type-filter':      'onFilterChange'
      'change #course-filter':    'onFilterChange'
      'click #mark-unread-btn':   'onMarkUnread'
      'click #mark-read-btn':   'onMarkRead'
      'click #forward-btn':       'onForward'
      'click #star-toggle-btn':   'onStarToggle'
      'click #submission-reply-btn': 'onSubmissionReply'

    messages:
      star: I18n.t('star', 'Star')
      unstar: I18n.t('unstar', 'Unstar')
      archive: I18n.t('archive', 'Archive')
      unarchive: I18n.t('unarchive', 'Unarchive')
      archive_conversation: I18n.t('Archive Selected')
      unarchive_conversation: I18n.t('Unarchive Selected')

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
      @updateFilterLabels()

    onSearch:      (tokens) => @trigger('search', tokens)

    onCompose:     (e) -> @trigger('compose')

    onReply:       (e) -> @trigger('reply')

    onReplyAll:    (e) -> @trigger('reply-all')

    onArchive:     (e) -> @trigger('archive')

    onDelete:      (e) -> @trigger('delete')

    onMarkUnread: (e) ->
      e.preventDefault()
      @trigger('mark-unread')

    onMarkRead: (e) ->
      e.preventDefault()
      @trigger('mark-read')

    onForward: (e) ->
      e.preventDefault()
      @trigger('forward')

    onStarToggle: (e) ->
      e.preventDefault()
      @$adminBtn.focus()
      @trigger('star-toggle')

    onSubmissionReply: (e) -> @trigger('submission-reply')

    onModelChange: (newModel, oldModel) ->
      @detachModelEvents(oldModel)
      @attachModelEvents(newModel)
      @updateUi(newModel)

    updateUi: (newModel) ->
      @toggleMessageBtns(newModel)
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
      @hideMarkUnreadBtn(!msg || msg.unread())
      @hideMarkReadBtn(!msg || !msg.unread())
      @refreshMenu()

    onStarStateChange: (msg) ->
      if msg
        key = if msg.starred() then 'unstar' else 'star'
        @$starToggleBtn.text(@messages[key])
      @refreshMenu()

    onArchivedStateChange: (msg) ->
      return if !msg
      archived = msg.get('workflow_state') == 'archived'
      @$archiveBtn.find('i').attr('class', if archived then 'icon-remove-from-collection' else 'icon-collection-save')
      @$archiveBtn.attr('title', if archived then @messages['unarchive'] else @messages['archive'])
      @$archiveBtn.find('.screenreader-only')
        .text(if archived then @messages['unarchive_conversation'] else @messages['archive_conversation'])
      if msg.get('canArchive')
        @$archiveBtn.removeAttr('disabled')
      else
        @$archiveBtn.attr('disabled', true)
      @refreshMenu()

    refreshMenu: ->
      @$adminMenu.menu('refresh') if @$adminMenu.is('.ui-menu')

    filterObj: (obj) -> _.object(_.filter(_.pairs(obj), (x) -> !!x[1]))

    onFilterChange: (e) =>
      @searchView?.autocompleteView.setContext(@courseView.getCurrentContext())
      if @$typeFilter.val() == 'submission_comments'
        @$search.show()
        @$conversationActions.hide()
        @$submissionCommentActions.show()
      else
        @$search.show()
        @$conversationActions.show()
        @$submissionCommentActions.hide()
      @trigger('filter', @filterObj({type: @$typeFilter.val(), course: @$courseFilter.val()}))
      @updateFilterLabels()

    updateFilterLabels: ->
      @$typeFilterSelectionLabel = $("##{@$typeFilter.attr('aria-labelledby')}").find('.current-selection-label') unless @$typeFilterSelectionLabel?.length
      @$courseFilterSelectionLabel = $("##{@$courseFilter.attr('aria-labelledby')}").find('.current-selection-label') unless @$courseFilterSelectionLabel?.length
      @$typeFilterSelectionLabel.text(@$typeFilter.find(':selected').text())
      @$courseFilterSelectionLabel.text(@$courseFilter.find(':selected').text())

    displayState: (state) ->
      @$typeFilter.selectpicker('val', state.type)
      @courseView.setValue(state.course)
      @trigger('course', @courseView.getCurrentContext())

    toggleMessageBtns: (newModel) ->
      no_model = !newModel || !newModel.get('selected')
      cannot_reply = no_model || newModel.get('cannot_reply')

      @toggleReplyBtn(cannot_reply)
      @toggleReplyAllBtn(cannot_reply)
      @toggleArchiveBtn(no_model)
      @toggleDeleteBtn(no_model)
      @toggleAdminBtn(no_model)
      @hideForwardBtn(no_model)

    toggleReplyBtn:    (value) ->
      @_toggleBtn(@$replyBtn, value)
      @_toggleBtn(@$submissionReplyBtn, value)

    toggleReplyAllBtn: (value) -> @_toggleBtn(@$replyAllBtn, value)

    toggleArchiveBtn:  (value) -> @_toggleBtn(@$archiveBtn, value)

    toggleDeleteBtn:   (value) -> @_toggleBtn(@$deleteBtn, value)

    toggleAdminBtn:    (value) -> @_toggleBtn(@$adminBtn, value)

    hideMarkUnreadBtn: (hide) -> if hide then @$markUnreadBtn.parent().detach() else @$adminMenu.prepend(@$markUnreadBtn.parent())

    hideMarkReadBtn: (hide) -> if hide then @$markReadBtn.parent().detach() else @$adminMenu.prepend(@$markReadBtn.parent())

    hideForwardBtn:    (hide) -> if hide then @$forwardBtn.parent().detach() else @$adminMenu.prepend(@$forwardBtn.parent())

    focusCompose: ->
      @$composeBtn.focus()

    _toggleBtn: (btn, value) ->
      value = if typeof value is 'undefined' then !btn.prop('disabled') else value
      btn.prop('disabled', value)

    toggleSending: (shouldShow) ->
      @$sendingMessage.toggle(shouldShow)
