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

import {useScope as useI18nScope} from '@canvas/i18n'

import $ from 'jquery'
import {each, extend} from 'lodash'
import Backbone from '@canvas/backbone'
import CyoeHelper from '@canvas/conditional-release-cyoe-helper'
import PublishIconView from '@canvas/publish-icon-view'
import LockIconView from '@canvas/lock-icon'
import DateDueColumnView from '@canvas/assignments/backbone/views/DateDueColumnView'
import DateAvailableColumnView from '@canvas/assignments/backbone/views/DateAvailableColumnView'
import SisButtonView from '@canvas/sis/backbone/views/SisButtonView'
import template from '../../jst/QuizItemView.handlebars'
import '@canvas/jquery/jquery.disableWhileLoading'
import Quiz from '@canvas/quizzes/backbone/models/Quiz'
import React from 'react'
import ReactDOM from 'react-dom'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import ItemAssignToTray from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'

const I18n = useI18nScope('quizzes.index')

export default class ItemView extends Backbone.View {
  static initClass() {
    this.prototype.template = template

    this.prototype.tagName = 'li'
    this.prototype.className = 'quiz'

    this.child('publishIconView', '[data-view=publish-icon]')
    this.child('lockIconView', '[data-view=lock-icon]')
    this.child('dateDueColumnView', '[data-view=date-due]')
    this.child('dateAvailableColumnView', '[data-view=date-available]')
    this.child('sisButtonView', '[data-view=sis-button]')

    this.prototype.events = {
      click: 'clickRow',
      'click .delete-item': 'onDelete',
      'click .migrate': 'migrateQuiz',
      'click .quiz-copy-to': 'copyQuizTo',
      'click .quiz-send-to': 'sendQuizTo',
      'click .duplicate_assignment': 'onDuplicate',
      'click .duplicate-failed-retry': 'onDuplicateFailedRetry',
      'click .migrate-failed-retry': 'onMigrateFailedRetry',
      'click .duplicate-failed-cancel': 'onDuplicateOrImportFailedCancel',
      'click .import-failed-cancel': 'onDuplicateOrImportFailedCancel',
      'click .migrate-failed-cancel': 'onDuplicateOrImportFailedCancel',
      'click .alignment-clone-failed-retry': 'onAlignmentCloneFailedRetry',
      'click .alignment-clone-failed-cancel': 'onDuplicateOrImportFailedCancel',
      'click .assign-to-link': 'onAssign',
    }

    this.prototype.messages = {
      confirm: I18n.t('confirms.delete_quiz', 'Are you sure you want to delete this quiz?'),
      multipleDates: I18n.t('multiple_due_dates', 'Multiple Dates'),
      deleteSuccessful: I18n.t('flash.removed', 'Quiz successfully deleted.'),
      deleteFail: I18n.t('flash.fail', 'Quiz deletion failed.'),
    }

    this.prototype.els = {
      '.al-trigger': '$settingsButton',
    }
  }

  initialize(_options) {
    this.initializeChildViews()
    this.observeModel()
    this.model.pollUntilFinishedLoading(3000)
    return super.initialize(...arguments)
  }

  initializeChildViews() {
    this.publishIconView = false
    this.lockIconView = false
    this.sisButtonView = false
    const content_type = this.model.get('quiz_type') === 'quizzes.next' ? 'assignment' : 'quiz'

    if (this.canManage()) {
      this.publishIconView = new PublishIconView({
        model: this.model,
        title: this.model.get('title'),
      })
      this.lockIconView = new LockIconView({
        model: this.model,
        unlockedText: I18n.t('%{name} is unlocked. Click to lock.', {
          name: this.model.get('title'),
        }),
        lockedText: I18n.t('%{name} is locked. Click to unlock', {name: this.model.get('title')}),
        course_id: ENV.COURSE_ID,
        content_id: this.model.get('id'),
        content_type,
      })
      if (
        this.model.postToSISEnabled() &&
        this.model.postToSIS() !== null &&
        this.model.attributes.published
      ) {
        this.sisButtonView = new SisButtonView({
          model: this.model,
          sisName: this.model.postToSISName(),
          dueDateRequired: this.model.dueDateRequiredForAccount(),
          maxNameLengthRequired: this.model.maxNameLengthRequiredForAccount(),
        })
      }
    }

    this.dateDueColumnView = new DateDueColumnView({model: this.model})
    return (this.dateAvailableColumnView = new DateAvailableColumnView({model: this.model}))
  }

  afterRender() {
    return this.$el.toggleClass('quiz-loading-overrides', !!this.model.get('loadingOverrides'))
  }

  // make clicks follow through to url for entire row
  clickRow(e) {
    const target = $(e.target)
    if (target.parents('.ig-admin').length > 0 || target.hasClass('ig-title')) return

    const row = target.parents('li')
    const title = row.find('.ig-title')
    if (title.length > 0) return this.redirectTo(title.attr('href'))
  }

  redirectTo(path) {
    return (window.location.href = path)
  }

  migrateQuizEnabled() {
    const isOldQuiz = this.model.get('quiz_type') !== 'quizzes.next'
    return ENV.FLAGS && ENV.FLAGS.migrate_quiz_enabled && isOldQuiz
  }

  migrateQuiz(e) {
    e.preventDefault()
    const courseId = ENV.context_asset_string.split('_')[1]
    const quizId = this.options.model.id
    const url = `/api/v1/courses/${courseId}/content_exports?export_type=quizzes2&quiz_id=${quizId}&include[]=migrated_quiz`
    const dfd = $.ajaxJSON(url, 'POST')
    this.$el.disableWhileLoading(dfd)
    return $.when(dfd)
      .done(response => {
        this.addMigratedQuizToList(response)
        return $.flashMessage(I18n.t('Migration in progress'))
      })
      .fail(() => {
        return $.flashError(I18n.t('An error occurred while migrating.'))
      })
  }

  addMigratedQuizToList(response) {
    if (!response) return
    const quizzes = response.migrated_quiz
    if (quizzes) {
      this.addQuizToList(quizzes[0])
    }
  }

  renderItemAssignToTray(open, returnFocusTo, itemProps) {
    ReactDOM.render(
      <ItemAssignToTray
        open={open}
        onClose={() => {
          ReactDOM.unmountComponentAtNode(document.getElementById('assign-to-mount-point'))
        }}
        onDismiss={() => {
          this.renderItemAssignToTray(false, returnFocusTo, itemProps)
          returnFocusTo.focus()
        }}
        itemType="assignment"
        locale={ENV.LOCALE || 'en'}
        timezone={ENV.TIMEZONE || 'UTC'}
        {...itemProps}
      />,
      document.getElementById('assign-to-mount-point')
    )
  }

  onAssign(e) {
    e.preventDefault()
    const returnFocusTo = $(e.target).closest('ul').prev('.al-trigger')

    const courseId = e.target.getAttribute('data-quiz-context-id')
    const itemName = e.target.getAttribute('data-quiz-name')
    const itemContentId = e.target.getAttribute('data-quiz-id')
    const iconType = e.target.getAttribute('data-is-lti-quiz') ? 'lti-quiz' : 'quiz'
    const pointsPossible = this.model.get('points_possible')
    this.renderItemAssignToTray(true, returnFocusTo, {
      courseId,
      itemName,
      itemContentId,
      pointsPossible,
      iconType,
    })
  }

  canDelete() {
    return this.model.get('permissions').delete
  }

  onDelete(e) {
    e.preventDefault()
    if (this.canDelete()) {
      // eslint-disable-next-line no-alert
      if (window.confirm(this.messages.confirm)) return this.delete()
    }
  }

  // delete quiz item
  delete(opts) {
    this.$el.hide()
    return this.model.destroy({
      success: () => {
        this.$el.remove()
        if (opts.silent !== true) {
          $.flashMessage(this.messages.deleteSuccessful)
        }
      },
      error: () => {
        this.$el.show()
        return $.flashError(this.messages.deleteFail)
      },
    })
  }

  renderCopyToTray(open) {
    const quizId = this.model.get('id')
    const isOldQuiz = this.model.get('quiz_type') !== 'quizzes.next'
    const contentSelection = isOldQuiz ? {quizzes: [quizId]} : {assignments: [quizId]}
    ReactDOM.render(
      <DirectShareCourseTray
        open={open}
        sourceCourseId={ENV.COURSE_ID}
        contentSelection={contentSelection}
        onDismiss={() => {
          this.renderCopyToTray(false)
          return setTimeout(() => this.$settingsButton.focus(), 100)
        }}
      />,
      document.getElementById('direct-share-mount-point')
    )
  }

  copyQuizTo(ev) {
    ev.preventDefault()
    this.renderCopyToTray(true)
  }

  renderSendToTray(open) {
    const quizId = this.model.get('id')
    const isOldQuiz = this.model.get('quiz_type') !== 'quizzes.next'
    const contentType = isOldQuiz ? 'quiz' : 'assignment'
    ReactDOM.render(
      <DirectShareUserModal
        open={open}
        sourceCourseId={ENV.COURSE_ID}
        contentShare={{content_type: contentType, content_id: quizId}}
        onDismiss={() => {
          this.renderSendToTray(false)
          return setTimeout(() => this.$settingsButton.focus(), 100)
        }}
      />,
      document.getElementById('direct-share-mount-point')
    )
  }

  sendQuizTo(ev) {
    ev.preventDefault()
    this.renderSendToTray(true)
  }

  observeModel() {
    this.model.on('change:published', this.updatePublishState, this)
    this.model.on('change:loadingOverrides', this.render, this)
    this.model.on('change:workflow_state', this.render, this)
  }

  updatePublishState() {
    this.$('.speed-grader-link-container')?.toggleClass('hidden', !this.model.get('published'))
    return this.$('.ig-row').toggleClass('ig-published', this.model.get('published'))
  }

  canManage() {
    return ENV.PERMISSIONS.manage
  }

  canCreate() {
    return ENV.PERMISSIONS.create
  }

  isStudent() {
    // must check canManage because current_user_roles will include roles from other enrolled courses
    return ENV.current_user_roles?.includes('student') && !this.canManage()
  }

  canDuplicate() {
    const userIsAdmin = ENV.current_user_is_admin
    const canDuplicate = this.model.get('can_duplicate')
    return (userIsAdmin || this.canCreate()) && canDuplicate
  }

  onDuplicate(e) {
    if (!this.canDuplicate()) return
    e.preventDefault()
    this.model.duplicate(this.addQuizToList.bind(this))
  }

  addQuizToList(response) {
    if (!response) return
    const quiz = new Quiz(response)
    if (ENV.PERMISSIONS.by_assignment_id) {
      ENV.PERMISSIONS.by_assignment_id[quiz.id] =
        ENV.PERMISSIONS.by_assignment_id[quiz.originalAssignmentID()]
    }
    this.model.collection.add(quiz)
    this.focusOnQuiz(response)
  }

  focusOnQuiz(quiz) {
    $(`#assignment_${quiz.id}`).attr('tabindex', -1).focus()
  }

  onDuplicateOrImportFailedCancel(e) {
    e.preventDefault()
    this.delete({silent: true})
  }

  onDuplicateFailedRetry(e) {
    e.preventDefault()
    const button = $(e.target)
    button.prop('disabled', true)
    this.model
      .duplicate_failed(response => {
        this.addQuizToList(response)
        this.delete({silent: true})
      })
      .always(() => {
        button.prop('disabled', false)
      })
  }

  onAlignmentCloneFailedRetry(e) {
    e.preventDefault()
    const button = $(e.target)
    button.prop('disabled', true)
    this.model
      .alignment_clone_failed(response => {
        this.addQuizToList(response)
        this.delete({silent: true})
      })
      .always(() => {
        button.prop('disabled', false)
      })
  }

  onMigrateFailedRetry(e) {
    e.preventDefault()
    const button = $(e.target)
    button.prop('disabled', true)
    this.model
      .retry_migration(response => {
        this.addMigratedQuizToList(response)
        this.delete({silent: true})
      })
      .always(() => {
        button.prop('disabled', false)
      })
  }

  toJSON() {
    const base = extend(this.model.toJSON(), this.options)
    base.quiz_menu_tools = ENV.quiz_menu_tools
    each(base.quiz_menu_tools, tool => {
      tool.url = tool.base_url + `&quizzes[]=${this.model.get('id')}`
    })

    base.cyoe = CyoeHelper.getItemData(base.assignment_id, base.quiz_type === 'assignment')
    base.return_to = encodeURIComponent(window.location.pathname)

    if (this.model.get('multiple_due_dates')) {
      base.selector = this.model.get('id')
      base.link_text = this.messages.multipleDates
      base.link_href = this.model.get('url')
    }

    base.migrateQuizEnabled = this.migrateQuizEnabled()
    base.canDuplicate = this.canDuplicate()
    base.isDuplicating = this.model.get('workflow_state') === 'duplicating'
    base.failedToDuplicate = this.model.get('workflow_state') === 'failed_to_duplicate'
    base.isMigrating = this.model.get('workflow_state') === 'migrating'
    base.isImporting = this.model.get('workflow_state') === 'importing'
    base.failedToImport = this.model.get('workflow_state') === 'fail_to_import'
    base.isMasterCourseChildContent = this.model.isMasterCourseChildContent()
    base.failedToMigrate = this.model.get('workflow_state') === 'failed_to_migrate'
    base.showAvailability =
      !(this.model.get('in_paced_course') && this.canManage()) &&
      (this.model.multipleDueDates() || !this.model.defaultDates().available())
    base.showDueDate =
      !(this.model.get('in_paced_course') && this.canManage()) &&
      (this.model.multipleDueDates() || this.model.singleSectionDueDate())
    base.name = this.model.name()
    base.isQuizzesNext = this.model.isQuizzesNext()
    base.useQuizzesNextIcon = this.model.isQuizzesNext() || this.isStudent()
    base.isQuizzesNextAndNotStudent = this.model.isQuizzesNext() && !this.isStudent()
    base.canShowQuizBuildShortCut =
      this.model.isQuizzesNext() &&
      this.model.get('can_update') &&
      !this.isStudent() &&
      ENV.FLAGS &&
      ENV.FLAGS.quiz_lti_enabled
    base.quizzesRespondusEnabled =
      this.isStudent() &&
      this.model.get('require_lockdown_browser') &&
      this.model.get('quiz_type') === 'quizzes.next'

    base.is_locked =
      this.model.get('is_master_course_child_content') &&
      this.model.get('restricted_by_master_course')

    base.courseId = ENV.context_asset_string.split('_')[1]
    base.differentiatedModulesFlag = ENV.FEATURES?.differentiated_modules
    base.showSpeedGraderLinkFlag = ENV.FLAGS?.show_additional_speed_grader_link
    base.showSpeedGraderLink = ENV.SHOW_SPEED_GRADER_LINK

    // publishing and unpublishing the underlying model does not rerender this view.
    // this sets initial value, then it keeps up with class toggling behavior on updatePublishState()
    base.initialUnpublishedState = !this.model.get('published')

    base.DIRECT_SHARE_ENABLED = ENV.FLAGS && ENV.FLAGS.DIRECT_SHARE_ENABLED
    base.canOpenManageOptions =
      this.canManage() || this.canDuplicate() || this.canDelete() || base.DIRECT_SHARE_ENABLED
    return base
  }
}
ItemView.initClass()
