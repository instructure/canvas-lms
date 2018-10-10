//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import I18n from 'i18n!conversations'
import _ from 'underscore'
import {View} from 'Backbone'
import Spinner from 'spin.js'
import CourseSelectionView from './CourseSelectionView'
import SearchView from './SearchView'
import 'vendor/bootstrap/bootstrap-dropdown'
import 'vendor/bootstrap-select/bootstrap-select'

export default class InboxHeaderView extends View {

  static initClass() {
    this.prototype.els = {
      '#compose-btn': '$composeBtn',
      '#reply-btn': '$replyBtn',
      '#reply-all-btn': '$replyAllBtn',
      '#archive-btn': '$archiveBtn',
      '#delete-btn': '$deleteBtn',
      '#course-filter': '$courseFilter',
      '#admin-btn': '$adminBtn',
      '#mark-unread-btn': '$markUnreadBtn',
      '#mark-read-btn': '$markReadBtn',
      '#forward-btn': '$forwardBtn',
      '#star-toggle-btn': '$starToggleBtn',
      '#admin-menu': '$adminMenu',
      '#sending-message': '$sendingMessage',
      '#sending-spinner': '$sendingSpinner',
      '[role=search]': '$search',
      '#conversation-actions': '$conversationActions',
      '#submission-comment-actions': '$submissionCommentActions',
      '#submission-reply-btn': '$submissionReplyBtn'
    }

    this.prototype.events = {
      'click #compose-btn': 'onCompose',
      'click #reply-btn': 'onReply',
      'click #reply-all-btn': 'onReplyAll',
      'click #archive-btn': 'onArchive',
      'click #delete-btn': 'onDelete',
      'change #course-filter': 'changeCourseFilter',
      'click #mark-unread-btn': 'onMarkUnread',
      'click #mark-read-btn': 'onMarkRead',
      'click #forward-btn': 'onForward',
      'click #star-toggle-btn': 'onStarToggle',
      'click #submission-reply-btn': 'onSubmissionReply'
    }

    this.prototype.messages = {
      star: I18n.t('star', 'Star'),
      unstar: I18n.t('unstar', 'Unstar'),
      archive: I18n.t('archive', 'Archive'),
      unarchive: I18n.t('unarchive', 'Unarchive'),
      archive_conversation: I18n.t('Archive Selected'),
      unarchive_conversation: I18n.t('Unarchive Selected')
    }

    this.prototype.spinnerOptions = {
      color: '#fff',
      lines: 10,
      length: 2,
      radius: 2,
      width: 2,
      left: 0
    }
  }

  render() {
    super.render()
    this.courseView = new CourseSelectionView({
      el: this.$courseFilter,
      courses: this.options.courses
    })
    this.searchView = new SearchView({el: this.$search})
    this.searchView.on('search', this.onSearch, this)
    const spinner = new Spinner(this.spinnerOptions)
    spinner.spin(this.$sendingSpinner[0])
    this.toggleSending(false)
    this.updateFilterLabels()

    return (this.courseFilterValue = this.$courseFilter.val())
  }

  onSearch(tokens) {
    return this.trigger('search', tokens)
  }

  onCompose(e) {
    return this.trigger('compose')
  }

  onReply(e) {
    return this.trigger('reply', null, '#reply-btn')
  }

  onReplyAll(e) {
    return this.trigger('reply-all', null, '#reply-all-btn')
  }

  onArchive(e) {
    return this.trigger('archive', '#compose-btn', '#archive-btn')
  }

  onDelete(e) {
    return this.trigger('delete', '#compose-btn', '#delete-btn')
  }

  onMarkUnread(e) {
    e.preventDefault()
    return this.trigger('mark-unread')
  }

  onMarkRead(e) {
    e.preventDefault()
    return this.trigger('mark-read')
  }

  onForward(e) {
    e.preventDefault()
    return this.trigger('forward', null, '#admin-btn')
  }

  onStarToggle(e) {
    e.preventDefault()
    this.$adminBtn.focus()
    return this.trigger('star-toggle')
  }

  onSubmissionReply(e) {
    return this.trigger('submission-reply')
  }

  onModelChange(newModel, oldModel) {
    this.detachModelEvents(oldModel)
    this.attachModelEvents(newModel)
    return this.updateUi(newModel)
  }

  updateUi(newModel) {
    this.toggleMessageBtns(newModel)
    this.onReadStateChange(newModel)
    this.onStarStateChange(newModel)
    return this.onArchivedStateChange(newModel)
  }

  detachModelEvents(oldModel) {
    if (oldModel) return oldModel.off(null, null, this)
  }

  attachModelEvents(newModel) {
    if (newModel) {
      newModel.on('change:workflow_state', this.onReadStateChange, this)
      return newModel.on('change:starred', this.onStarStateChange, this)
    }
  }

  onReadStateChange(msg) {
    this.hideMarkUnreadBtn(!msg || msg.unread())
    this.hideMarkReadBtn(!msg || !msg.unread())
    return this.refreshMenu()
  }

  onStarStateChange(msg) {
    if (msg) {
      const key = msg.starred() ? 'unstar' : 'star'
      this.$starToggleBtn.text(this.messages[key])
    }
    return this.refreshMenu()
  }

  onArchivedStateChange(msg) {
    if (!msg) return
    const archived = msg.get('workflow_state') === 'archived'
    this.$archiveBtn
      .find('i')
      .attr('class', archived ? 'icon-remove-from-collection' : 'icon-collection-save')
    this.$archiveBtn.attr('title', archived ? this.messages.unarchive : this.messages.archive)
    this.$archiveBtn
      .find('.screenreader-only')
      .text(archived ? this.messages.unarchive_conversation : this.messages.archive_conversation)
    if (msg.get('canArchive')) {
      this.$archiveBtn.removeAttr('disabled')
    } else {
      this.$archiveBtn.attr('disabled', true)
    }
    return this.refreshMenu()
  }

  refreshMenu() {
    if (this.$adminMenu.is('.ui-menu')) return this.$adminMenu.menu('refresh')
  }

  filterObj(obj) {
    return _.object(_.filter(_.pairs(obj), x => !!x[1]))
  }

  changeTypeFilter(type) {
    this.typeFilter = type
    return this.onFilterChange()
  }

  changeCourseFilter() {
    // This is getting called not just when the course filter gets changed,
    // but also when the url changes at all. This if statements limits
    // the onFilterChange to only be called if the filter was actually
    // changed.
    if (this.courseFilterValue !== this.$courseFilter.val()) {
      this.courseFilterValue = this.$courseFilter.val()
      return this.onFilterChange()
    }
  }

  onFilterChange(e) {
    if (this.searchView != null) {
      this.searchView.autocompleteView.setContext(this.courseView.getCurrentContext())
    }
    if (this.typeFilter === 'submission_comments') {
      this.$search.show()
      this.$conversationActions.hide()
      this.$submissionCommentActions.show()
    } else {
      this.$search.show()
      this.$conversationActions.show()
      this.$submissionCommentActions.hide()
    }
    this.trigger('filter', this.filterObj({type: this.typeFilter, course: this.courseFilterValue}))
    return this.updateFilterLabels()
  }

  updateFilterLabels() {
    if (
      !(this.$courseFilterSelectionLabel != null
        ? this.$courseFilterSelectionLabel.length
        : undefined)
    )
      this.$courseFilterSelectionLabel = $(`#${this.$courseFilter.attr('aria-labelledby')}`).find(
        '.current-selection-label'
      )
    return this.$courseFilterSelectionLabel.text(this.$courseFilter.find(':selected').text())
  }

  displayState(state) {
    this.courseView.setValue(state.course)
    return this.trigger('course', this.courseView.getCurrentContext())
  }

  toggleMessageBtns(newModel) {
    const no_model = !newModel || !newModel.get('selected')
    const cannot_reply = no_model || newModel.get('cannot_reply')

    this.toggleReplyBtn(cannot_reply)
    this.toggleReplyAllBtn(cannot_reply)
    this.toggleArchiveBtn(no_model)
    this.toggleDeleteBtn(no_model)
    this.toggleAdminBtn(no_model)
    return this.hideForwardBtn(no_model)
  }

  toggleReplyBtn(value) {
    this._toggleBtn(this.$replyBtn, value)
    return this._toggleBtn(this.$submissionReplyBtn, value)
  }

  toggleReplyAllBtn(value) {
    return this._toggleBtn(this.$replyAllBtn, value)
  }

  toggleArchiveBtn(value) {
    return this._toggleBtn(this.$archiveBtn, value)
  }

  toggleDeleteBtn(value) {
    return this._toggleBtn(this.$deleteBtn, value)
  }

  toggleAdminBtn(value) {
    return this._toggleBtn(this.$adminBtn, value)
  }

  hideMarkUnreadBtn(hide) {
    if (hide) {
      return this.$markUnreadBtn.parent().detach()
    } else {
      return this.$adminMenu.prepend(this.$markUnreadBtn.parent())
    }
  }

  hideMarkReadBtn(hide) {
    if (hide) {
      return this.$markReadBtn.parent().detach()
    } else {
      return this.$adminMenu.prepend(this.$markReadBtn.parent())
    }
  }

  hideForwardBtn(hide) {
    if (hide) {
      return this.$forwardBtn.parent().detach()
    } else {
      return this.$adminMenu.prepend(this.$forwardBtn.parent())
    }
  }

  focusCompose() {
    return this.$composeBtn.focus()
  }

  _toggleBtn(btn, value) {
    value = typeof value === 'undefined' ? !btn.prop('disabled') : value
    return btn.prop('disabled', value)
  }

  toggleSending(shouldShow) {
    return this.$sendingMessage.toggle(shouldShow)
  }
}
InboxHeaderView.initClass()
