#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'i18n!conversations'
  'underscore'
  'Backbone'
  'spin.js'
  '../conversations/CourseSelectionView'
  '../conversations/SearchView'
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
      'change #course-filter':    'changeCourseFilter'
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
      @courseView = new CourseSelectionView(el: @$courseFilter, courses: @options.courses)
      @searchView = new SearchView(el: @$search)
      @searchView.on('search', @onSearch)
      spinner = new Spinner(@spinnerOptions)
      spinner.spin(@$sendingSpinner[0])
      @toggleSending(false)
      @updateFilterLabels()

      @courseFilterValue = @$courseFilter.val()

    onSearch:      (tokens) => @trigger('search', tokens)

    onCompose:     (e) -> @trigger('compose')

    onReply:       (e) -> @trigger('reply', null, '#reply-btn')

    onReplyAll:    (e) -> @trigger('reply-all', null, '#reply-all-btn')

    onArchive:     (e) -> @trigger('archive', '#compose-btn', '#archive-btn')

    onDelete:      (e) -> @trigger('delete', '#compose-btn', '#delete-btn')

    onMarkUnread: (e) ->
      e.preventDefault()
      @trigger('mark-unread')

    onMarkRead: (e) ->
      e.preventDefault()
      @trigger('mark-read')

    onForward: (e) ->
      e.preventDefault()
      @trigger('forward', null, '#admin-btn')

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

    changeTypeFilter: (type) ->
      @typeFilter = type
      @onFilterChange()

    changeCourseFilter: () ->
      # This is getting called not just when the course filter gets changed,
      # but also when the url changes at all. This if statements limits
      # the onFilterChange to only be called if the filter was actually
      # changed.
      if @courseFilterValue != @$courseFilter.val()
        @courseFilterValue = @$courseFilter.val()
        @onFilterChange()


    onFilterChange: (e) =>
      @searchView?.autocompleteView.setContext(@courseView.getCurrentContext())
      if @typeFilter == 'submission_comments'
        @$search.show()
        @$conversationActions.hide()
        @$submissionCommentActions.show()
      else
        @$search.show()
        @$conversationActions.show()
        @$submissionCommentActions.hide()
      @trigger('filter', @filterObj({type: @typeFilter, course: @courseFilterValue}))
      @updateFilterLabels()

    updateFilterLabels: ->
      @$courseFilterSelectionLabel = $("##{@$courseFilter.attr('aria-labelledby')}").find('.current-selection-label') unless @$courseFilterSelectionLabel?.length
      @$courseFilterSelectionLabel.text(@$courseFilter.find(':selected').text())

    displayState: (state) ->
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
