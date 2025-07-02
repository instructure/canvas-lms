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
import React, {lazy, Suspense} from 'react'
import ReactDOM from 'react-dom'
import {createRoot} from 'react-dom/client'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import template from '../../jst/WikiPageEdit.handlebars'
import ValidatedFormView from '@canvas/forms/backbone/views/ValidatedFormView'
import WikiPageDeleteDialog from './WikiPageDeleteDialog'
import WikiPageReloadView from './WikiPageReloadView'
import {useScope as createI18nScope} from '@canvas/i18n'
import DueDateCalendarPicker from '@canvas/due-dates/react/DueDateCalendarPicker'
import {unfudgeDateForProfileTimezone} from '@instructure/moment-utils'
import {renderDatetimeField} from '@canvas/datetime/jquery/DatetimeField'
import renderWikiPageTitle from '../../react/renderWikiPageTitle'
import {renderAssignToTray} from '../../react/renderAssignToTray'
import {itemTypeToApiURL} from '@canvas/context-modules/differentiated-modules/utils/assignToHelper'
import {LATEST_BLOCK_DATA_VERSION} from '@canvas/block-editor/react/utils'
import {BODY_MAX_LENGTH} from '../../utils/constants'
import MasteryPathToggle from '@canvas/mastery-path-toggle/react/MasteryPathToggle'

const I18n = createI18nScope('pages')

const INPUT_LENGTH_ERROR = {
  type: 'too_long',
  message: I18n.t('Input exceeds 500 KB limit. Please reduce the text size.'),
}

RichContentEditor.preloadRemoteModule()

export default class WikiPageEditView extends ValidatedFormView {
  static initClass() {
    this.mixin({
      els: {
        '[name="body"]': '$wikiPageBody',
        '.header-bar-outer-container': '$headerBarOuterContainer',
        '.page-changed-alert': '$pageChangedAlert',
        '.help_dialog': '$helpDialog',
        '#todo_date_container': '$studentTodoAtContainer',
        '#student_planner_checkbox': '$studentPlannerCheckbox',
      },

      events: {
        'click a.switch_views': 'switchViews',
        'click .delete_page': 'deleteWikiPage',
        'click .form-actions .cancel': 'cancel',
        'click .form-actions .save_and_publish': 'saveAndPublish',
        'click #student_planner_checkbox': 'toggleStudentTodo',
      },
    })

    this.prototype.template = template
    this.prototype.className = 'form-horizontal edit-form validated-form-view'
    this.prototype.dontRenableAfterSaveSuccess = true
    this.prototype.disablingDfd = new $.Deferred()
    this.prototype.attributes = {
      novalidate: true,
    }
    this.optionProperty('wiki_pages_path')
    this.optionProperty('WIKI_RIGHTS')
    this.optionProperty('PAGE_RIGHTS')
  }

  initialize(options = {}) {
    super.initialize(...arguments)
    if (!this.WIKI_RIGHTS) this.WIKI_RIGHTS = {}
    if (!this.PAGE_RIGHTS) this.PAGE_RIGHTS = {}
    this.queryParams = new URLSearchParams(window.location.search)
    this.enableAssignTo = ENV.COURSE_ID != null && ENV.WIKI_RIGHTS.manage_assign_to
    this.coursePaceWithMasteryPaths =
      this.enableAssignTo &&
      ENV.IN_PACED_COURSE &&
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED &&
      ENV.FEATURES.course_pace_pacing_with_mastery_paths
    const redirect = () => {
      window.location.href = this.model.get('html_url')
    }
    let callBack = redirect
    if (this.enableAssignTo) {
      callBack = _args => this.handleOverridesSave(_args, redirect)
    }
    this.on('success', callBack)
    this.lockedItems = options.lockedItems || {}
    const todoDate = this.model.get('todo_date')
    this.overrides = null
    return (this.studentTodoAtDateValue = todoDate ? new Date(todoDate) : '')
  }

  handleOverridesSave(page, redirect) {
    if (!page.page_id) return
    const url = itemTypeToApiURL(ENV.COURSE_ID, 'page', page.page_id)
    const errorCallBack = () => {
      this.disablingDfd.reject()
      $.flashError(I18n.t("Oops! We weren't able to save your page. Please try again"))
    }

    const data = this.overrides

    if (
      ENV.FEATURES.course_pace_pacing_with_mastery_paths &&
      ENV.IN_PACED_COURSE &&
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
    ) {
      data.only_visible_to_overrides = this.overrides.only_visible_to_overrides
    } else {
      data.only_visible_to_overrides = ENV.IN_PACED_COURSE
        ? false
        : this.overrides.only_visible_to_overrides
    }

    $.ajaxJSON(url, 'PUT', JSON.stringify(data), redirect, errorCallBack, {
      contentType: 'application/json',
    })
  }

  toJSON() {
    let IS
    const json = super.toJSON(...arguments)

    json.IS = IS = {
      TEACHER_ROLE: false,
      STUDENT_ROLE: false,
      MEMBER_ROLE: false,
      ANYONE_ROLE: false,
    }

    // rather than requiring the editing_roles to match a
    // string exactly, we check for individual editing roles
    let editing_roles = json.editing_roles || ''
    editing_roles = editing_roles.split(',').map(s => s.trim())
    if (editing_roles.includes('public')) {
      IS.ANYONE_ROLE = true
    } else if (editing_roles.includes('members')) {
      IS.MEMBER_ROLE = true
    } else if (editing_roles.includes('students')) {
      IS.STUDENT_ROLE = true
    } else {
      IS.TEACHER_ROLE = true
    }

    json.CAN = {
      PUBLISH: !!this.WIKI_RIGHTS.publish_page,
      // Annoying name conflict - PUBLISH means we're allowed to publish wiki
      // pages in general, PUBLISH_NOW means we can publish this page right
      // now (i.e. we can PUBLISH and this page is currently unpublished)
      PUBLISH_NOW: !!this.WIKI_RIGHTS.publish_page && !this.model.get('published'),
      DELETE: !!this.PAGE_RIGHTS.delete,
      EDIT_TITLE: !!this.PAGE_RIGHTS.update || json.new_record,
      EDIT_ROLES: !!this.WIKI_RIGHTS.update,
      SELECT_ROLES: !ENV?.horizon_course,
    }
    json.SHOW = {COURSE_ROLES: json.contextName === 'courses'}

    if (!window.ENV.FEATURES.create_wiki_page_mastery_path_overrides) {
      json.assignment = json.assignment != null ? json.assignment.toView() : undefined
    }

    json.content_is_locked = this.lockedItems.content
    json.show_assign_to = this.enableAssignTo
    json.course_pace_with_mastery_paths = this.coursePaceWithMasteryPaths
    json.edit_with_block_editor = this.model.get('editor') === 'block_editor'

    if (
      (this.queryParams.get('editor') === 'block_editor' ||
        window.ENV.text_editor_preference === 'block_editor') &&
      this.model.get('body') == null &&
      this.model.get('editor') !== 'rce'
    ) {
      json.edit_with_block_editor = true
    }

    return json
  }

  onUnload(ev) {
    // don't open the "are you sure" dialog unless we're still rendered in the page
    // so that, for example, our specs that don't clean up after themselves don't
    // fire this unintentionally
    if (
      this &&
      this.checkUnsavedOnLeave &&
      this.hasUnsavedChanges() &&
      document.body.contains(this.el)
    ) {
      const warning = this.unsavedWarning()
      ;(ev || window.event).returnValue = warning
      return warning
    }
  }

  // handles the toggling of the student todo date picker
  toggleStudentTodo(_e) {
    return this.$studentTodoAtContainer.toggle()
  }

  handleStudentTodoUpdate = newDate => {
    this.studentTodoAtDateValue = newDate
    return this.renderStudentTodoAtDate()
  }

  renderStudentTodoAtDate() {
    const elt = this.$studentTodoAtContainer[0]
    if (elt) {
      return createRoot(elt).render(
        <DueDateCalendarPicker
          dateType="todo_date"
          name="student_todo_at"
          handleUpdate={this.handleStudentTodoUpdate}
          rowKey="student_todo_at_date"
          labelledBy="student_todo_at_date_label"
          inputClasses=""
          disabled={false}
          isFancyMidnight={true}
          dateValue={this.studentTodoAtDateValue}
          labelText="Student Planner Date"
          labelClasses="screenreader-only"
        />,
      )
    }
  }

  // After the page loads, ensure the that wiki sidebar gets initialized
  // correctly.
  // @api custom backbone override
  afterRender() {
    super.afterRender(...arguments)
    this.renderStudentTodoAtDate()

    if (this.toJSON().todo_date == null) {
      this.$studentTodoAtContainer.hide()
    }

    renderWikiPageTitle({
      defaultValue: this.model.get('title'),
      isContentLocked: !!this.lockedItems.content,
      canEdit: this.toJSON().CAN.EDIT_TITLE,
      viewElement: this.$el,
      validationCallback: this.validateFormData,
      isRequired: true,
    })

    if (this.enableAssignTo) {
      const pageName = this.model.get('title')
      const pageId = this.model.id
      const mountElement = document.getElementById('assign-to-mount-point-edit-page')
      const onSync = payload => {
        this.overrides = payload
      }
      renderAssignToTray(mountElement, {pageId, onSync, pageName})
    }

    if (this.coursePaceWithMasteryPaths) {
      const mountElement = document.getElementById('mastery-paths-toggle-edit-page')
      const onSync = payload => {
        this.overrides = {
          assignment_overrides: payload,
          only_visible_to_overrides: payload.some(override => override.noop_id == 1),
        }
      }

      ReactDOM.render(
        React.createElement(MasteryPathToggle, {
          onSync,
          fetchOwnOverrides: true,
          courseId: ENV.COURSE_ID,
          itemType: 'wiki_page',
          itemContentId: this.model.id,
        }),
        mountElement,
      )
    }

    let chose_block_editor =
      window.location.href.split('?').filter(piece => {
        return piece.indexOf('editor=block_editor') !== -1
      }).length === 1
    if (!chose_block_editor) {
      chose_block_editor =
        window.ENV.text_editor_preference === 'block_editor' &&
        this.model.get('body') == null &&
        this.model.get('editor') !== 'rce'
    }

    if (
      (this.model.get('editor') === 'block_editor' && this.model.get('block_editor_attributes')) ||
      chose_block_editor
    ) {
      const BlockEditor = lazy(() => import('@canvas/block-editor'))
      const blockEditorData = this.model.get('block_editor_attributes')

      const container = document.getElementById('content')
      container.style.boxSizing = 'border-box'
      container.style.width = '100%'
      container.style.transition = 'width 0.3s ease-in-out'

      const root = createRoot(document.getElementById('block_editor'))
      root.render(
        <Suspense fallback={<div>{I18n.t('Loading...')}</div>}>
          <BlockEditor
            course_id={ENV.COURSE_ID}
            container={container}
            content={blockEditorData || {version: LATEST_BLOCK_DATA_VERSION, blocks: undefined}}
            onCancel={this.cancel.bind(this)}
          />
        </Suspense>,
      )
    } else {
      RichContentEditor.loadNewEditor(
        this.$wikiPageBody,
        {
          focus: true,
          manageParent: true,
          resourceType: 'wiki_page.body',
          resourceId: this.model.id,
        },
        rce => {
          rce.handleBlurEditor = () => {
            this.handleBlurContent()
          }
          rce.handleBlurRCE = () => {
            this.handleBlurContent()
          }
        },
      )
    }

    this.checkUnsavedOnLeave = true
    $(window).on('beforeunload', this.onUnload.bind(this))

    if (!this.firstRender) {
      this.firstRender = true
      $(() => $('[autofocus]:not(:focus)').eq(0).focus())

      const publishAtInput = $('#publish_at_input')
      if (this.model.get('published')) {
        publishAtInput.prop('disabled', true)
      } else {
        renderDatetimeField(publishAtInput, {showFormatExample: true})
          .change(e => {
            $('.save_and_publish').prop('disabled', e.target.value.length > 0)
            const isInvalid = e.target.getAttribute('aria-invalid') === 'true'
            $('.submit').prop('disabled', isInvalid)
          })
          .trigger('change')
      }
    }

    this.reloadPending = false
    this.reloadView = new WikiPageReloadView({
      el: this.$pageChangedAlert,
      model: this.model,
      interval: 60000,
      reloadMessage: I18n.t(
        'reload_editing_page',
        'This page has changed since you started editing it. *Reloading* will lose all of your changes.',
        {wrapper: '<a class="reload" href="#">$1</a>'},
      ),
      warning: true,
    })
    this.reloadView.on('changed', () => {
      this.$headerBarOuterContainer.addClass('page-changed')
      return (this.reloadPending = true)
    })
    this.reloadView.on('reload', () => this.render())
    this.reloadView.pollForChanges()
  }

  destroyEditor() {
    // hack fix for LF-1134
    try {
      if (this.model.get('editor') !== 'block_editor') {
        RichContentEditor.destroyRCE(this.$wikiPageBody)
      }
    } catch (e) {
      console.warn(e)
    } finally {
      this.$el.remove()
    }
  }

  switchViews(event) {
    if (event != null) {
      event.preventDefault()
    }
    RichContentEditor.callOnRCE(this.$wikiPageBody, 'toggle')
    // hide the clicked link, and show the other toggle link.
    // todo: replace .andSelf with .addBack when JQuery is upgraded.
    $(event.currentTarget).siblings('a').andSelf().toggle().focus()
  }

  toggleBodyError(error) {
    if (error) {
      const existingError = $('#wiki_page_body_error')
      $('.edit-content').addClass('has_body_errors')
      if (existingError.length) {
        existingError.show()
      } else {
        $('<span>', {
          id: 'wiki_page_body_error',
          class: 'ic-Form-message ic-Form-message--error',
          role: 'alert',
          'aria-live': 'assertive',
        })
          .append($('<i>', {class: 'icon-warning icon-Solid'}))
          .append(' ' + error.message)
          .hide()
          .insertBefore('#wiki_page_body_statusbar')
          .show()
      }
    } else {
      $('.edit-content').removeClass('has_body_errors')
      $('#wiki_page_body_error').hide()
    }
  }

  handleBlurContent() {
    const body = this.getFormData().body
    if (body && new Blob([body]).size > BODY_MAX_LENGTH) {
      this.toggleBodyError(INPUT_LENGTH_ERROR)
    } else {
      this.toggleBodyError(null)
    }
  }

  showErrors(errors) {
    const {title, body, ...otherErrors} = errors
    // IntsUI TextInput component show the title errors from server response
    // show the body errors in a different way
    if (body && this.model.get('editor') != 'block_editor') {
      this.toggleBodyError(body[0])

      // tinymce workaround for focus issue
      if (!tinymce.activeEditor.hidden) {
        tinymce.activeEditor.fire('focus')
        tinymce.activeEditor.container.scrollIntoView({behavior: 'smooth', block: 'center'})
      } else {
        const rceHtmlEditor = $('.RceHtmlEditor')
        if (rceHtmlEditor.length) {
          // div[role=textbox] can't be focused
          rceHtmlEditor[0].scrollIntoView({behavior: 'smooth', block: 'center'})
        } else {
          $('textarea#wiki_page_body')[0].focus()
        }
      }
    } else {
      if (body) otherErrors.body = body
    }

    super.showErrors(otherErrors)
  }

  hideErrors() {
    if (this.model.get('editor') != 'block_editor') {
      this.toggleBodyError(null)
    }
    super.hideErrors()
  }

  // Validate they entered in a title.
  // @api ValidatedFormView override
  validateFormData(data) {
    const errors = {}

    // title errors are handled by the TextInput component on server response
    // this validation is just to avoid sending a request with an empty title
    if (data.title === '') {
      errors.title = [
        {
          type: 'required',
          message: I18n.t('Title must contain at least one letter or number'),
        },
      ]
    }

    if (data.body && new Blob([data.body]).size > BODY_MAX_LENGTH) {
      errors.body = [INPUT_LENGTH_ERROR]
    }

    const studentTodoAtValid = data.student_todo_at != null && data.student_todo_at !== ''
    if (data.student_planner_checkbox && !studentTodoAtValid) {
      errors.student_todo_at = [
        {
          type: 'required',
          message: I18n.t('You must enter a date'),
        },
      ]
    }

    const sectionViewRef = document.getElementById(
      'manage-assign-to-container',
    )?.reactComponentInstance
    const invalidInput = sectionViewRef?.focusErrors()
    if (invalidInput) {
      errors.invalid_card = {$input: null, showError: this.showError}
    } else {
      delete errors.invalid_card
    }

    return errors
  }

  hasUnsavedChanges() {
    const hasEditor = RichContentEditor.callOnRCE(this.$wikiPageBody, 'exists?')
    let dirty = hasEditor && RichContentEditor.callOnRCE(this.$wikiPageBody, 'is_dirty')
    if (!dirty && this.toJSON().CAN.EDIT_TITLE) {
      dirty = (this.model.get('title') || '') !== (this.getFormData().title || '')
    }
    return dirty
  }

  unsavedWarning() {
    return I18n.t(
      'warnings.unsaved_changes',
      'You have unsaved changes. Do you want to continue without saving these changes?',
    )
  }

  async submit(event) {
    this.checkUnsavedOnLeave = false
    if (this.reloadPending) {
      if (
        !window.confirm(
          I18n.t(
            'warnings.overwrite_changes',
            'You are about to overwrite other changes that have been made since you started editing.\n\nOverwrite these changes?',
          ),
        )
      ) {
        if (event != null) {
          event.preventDefault()
        }
        return
      }
    }
    if (window.block_editor) {
      this.blockEditorData = window.block_editor().getBlocks()
    }

    if (this.reloadView != null) {
      this.reloadView.stopPolling()
    }
    return super.submit(...arguments)
  }

  saveAndPublish(_event) {
    this.shouldPublish = true
  }

  onSaveFail(xhr) {
    this.shouldPublish = false
    return super.onSaveFail(xhr)
  }

  getFormData() {
    const page_data = super.getFormData(...arguments)

    if (!window.ENV.FEATURES.create_wiki_page_mastery_path_overrides) {
      const assign_data = page_data.assignment

      if ((assign_data != null ? assign_data.set_assignment : undefined) === '1') {
        assign_data.only_visible_to_overrides = true
        page_data.assignment = this.model.get('assignment') || this.model.createAssignment()
        page_data.assignment.set(assign_data)
      } else {
        page_data.assignment = this.model.createAssignment({set_assignment: '0'})
      }
      page_data.set_assignment = page_data.assignment.get('set_assignment')
    }

    page_data.student_planner_checkbox = this.$studentPlannerCheckbox?.is(':checked')
    if (page_data.student_planner_checkbox) {
      page_data.student_todo_at = this.studentTodoAtDateValue
    } else {
      page_data.student_todo_at = null
    }

    if (page_data.publish_at) {
      page_data.publish_at = unfudgeDateForProfileTimezone(page_data.publish_at)
    }
    if (this.blockEditorData) {
      page_data.block_editor_attributes = this.blockEditorData
    }
    if (this.shouldPublish) page_data.published = true
    return page_data
  }

  cancel(event) {
    if (event != null) {
      event.preventDefault()
    }

    if (!this.hasUnsavedChanges() || window.confirm(this.unsavedWarning())) {
      this.checkUnsavedOnLeave = false
      if (this.model.get('editor') !== 'block_editor') {
        RichContentEditor.closeRCE(this.$wikiPageBody)
      }
      return this.trigger('cancel')
    }
  }

  deleteWikiPage(event) {
    if (event != null) {
      event.preventDefault()
    }
    if (!this.model.get('deletable')) return

    const deleteDialog = new WikiPageDeleteDialog({
      model: this.model,
      wiki_pages_path: this.wiki_pages_path,
    })
    return deleteDialog.open()
  }
}
WikiPageEditView.initClass()
