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
  '../../util/deparam'
  'i18n!conversations'
  'underscore'
  'Backbone'
  'react',
  'react-dom',
  'spin.js'
  '../conversations/SearchView'
  'jsx/shared/components/CoursesGroupsAutocomplete'
  'jsx/shared/components/ConversationStatusFilter'
], ($, deparam, I18n, _, {View}, React, ReactDOM, Spinner, SearchView, CoursesGroupsAutocomplete, ConversationStatusFilter) ->

  class InboxHeaderView extends View

    els:
      '#compose-btn'     : '$composeBtn'
      '#reply-btn'       : '$replyBtn'
      '#reply-all-btn'   : '$replyAllBtn'
      '#archive-btn'     : '$archiveBtn'
      '#delete-btn'      : '$deleteBtn'
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
      '#course-group-filter'        : '$courseGroupFilter'
      '#conversation-filter'        : '$conversationFilter'

    events:
      'click #compose-btn':       'onCompose'
      'click #reply-btn':         'onReply'
      'click #reply-all-btn':     'onReplyAll'
      'click #archive-btn':       'onArchive'
      'click #delete-btn':        'onDelete'
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

    getFilterParams: () ->
      hash = window.location.hash.substring("#filter=".length)
      deparam(hash)

    statusFilterOptions: [
      { value: 'inbox', label: I18n.t('Inbox') },
      { value: 'unread', label: I18n.t('Unread') },
      { value: 'starred', label: I18n.t('Starred') },
      { value: 'sent', label: I18n.t('Sent') },
      { value: 'archived', label: I18n.t('Archived') },
      { value: 'submission_comments', label: I18n.t('Submission Comments') }
    ]
    defaultStatusFilterOption: 'inbox'

    filterIsValid: (filter) ->
      filter && @statusFilterOptions.some((option) => return option.value == filter)

    updateWindowHash: () ->
      filterParams = @getFilterParams()
      filter = filterParams.type
      if !@filterIsValid(filter)
        window.location.hash = "#filter=type=#{@defaultStatusFilterOption}"

    renderTypeFilter: () ->
      urlParams = @getFilterParams()
      @typeFilter = urlParams.type
      if !@filterIsValid(@typeFilter)
        @typeFilter = @defaultStatusFilterOption

      ReactDOM.render(React.createElement(ConversationStatusFilter, {
        filters: @statusFilterOptions,
        initialFilter: @typeFilter,
        defaultFilter: @defaultStatusFilterOption,
        onChange: @changeTypeFilter
      }), @$conversationFilter[0])

    renderCourseGroupFilter: () ->
      urlParams = @getFilterParams()
      @courseGroupFilterSelection = urlParams.course
      selectedOption = null
      if @courseGroupFilterSelection
        courseParamSplit = @courseGroupFilterSelection.split("_")
        courseParamType = courseParamSplit[0]
        courseParamId = parseInt(courseParamSplit[1])
        selectedOption = {
          entityType: courseParamType,
          entityId: courseParamId
        }
      ReactDOM.render(React.createElement(CoursesGroupsAutocomplete, {
        placeholder: I18n.t('Select Courses or Groups'),
        onChange: @changeCourseGroupFilter,
        selectedOption: selectedOption
      }), @$courseGroupFilter[0])

    render: () ->
      super()
      @searchView = new SearchView(el: @$search)
      @searchView.on('search', @onSearch)
      spinner = new Spinner(@spinnerOptions)
      spinner.spin(@$sendingSpinner[0])
      @toggleSending(false)
      @updateWindowHash()
      @updateFilterLabels()

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

    updateFilterLabels: () ->
      @renderTypeFilter()
      @renderCourseGroupFilter()

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

    changeTypeFilter: (type) =>
      @typeFilter = type
      @hideOrShowSubmissionComments()
      @trigger('filter', @filterObj({type: @typeFilter, course: @courseGroupFilterSelection }))

    hideOrShowSubmissionComments: () =>
      if @typeFilter == 'submission_comments'
        # It seems weird that @$search.show() is called first in both branches
        # but i'm not sure what the right thing is: should one of these be
        # a "hide" or should this line be pulled before the if?
        @$search.show()
        @$conversationActions.hide()
        @$submissionCommentActions.show()
      else
        @$search.show()
        @$conversationActions.show()
        @$submissionCommentActions.hide()

    changeCourseGroupFilter: (_, course) =>
      @courseGroupFilterSelection = course?.id
      @hideOrShowSubmissionComments()
      @trigger('filter', @filterObj({type: @typeFilter, course: @courseGroupFilterSelection }))

    onFilterChange: (e) =>
      @hideOrShowSubmissionComments()
      @trigger('filter', @filterObj({type: @typeFilter, course: @courseGroupFilterSelection }))

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
