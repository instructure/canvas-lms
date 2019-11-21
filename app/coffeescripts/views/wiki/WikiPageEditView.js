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
import React from 'react'
import ReactDOM from 'react-dom'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import template from 'jst/wiki/WikiPageEdit'
import ValidatedFormView from '../ValidatedFormView'
import WikiPageDeleteDialog from './WikiPageDeleteDialog'
import WikiPageReloadView from './WikiPageReloadView'
import I18n from 'i18n!pages'
import KeyboardShortcuts from '../editor/KeyboardShortcuts'
import DueDateCalendarPicker from 'jsx/due_dates/DueDateCalendarPicker'
import 'jquery.instructure_date_and_time'

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
        '#student_planner_checkbox': '$studentPlannerCheckbox'
      },

      events: {
        'click a.switch_views': 'switchViews',
        'click .delete_page': 'deleteWikiPage',
        'click .form-actions .cancel': 'cancel',
        'click .form-actions .save_and_publish': 'saveAndPublish',
        'click #student_planner_checkbox': 'toggleStudentTodo'
      }
    })

    this.prototype.template = template
    this.prototype.className = 'form-horizontal edit-form validated-form-view'
    this.prototype.dontRenableAfterSaveSuccess = true

    this.optionProperty('wiki_pages_path')
    this.optionProperty('WIKI_RIGHTS')
    this.optionProperty('PAGE_RIGHTS')
  }

  initialize(options = {}) {
    super.initialize(...arguments)
    if (!this.WIKI_RIGHTS) this.WIKI_RIGHTS = {}
    if (!this.PAGE_RIGHTS) this.PAGE_RIGHTS = {}
    this.on('success', args => (window.location.href = this.model.get('html_url')))
    this.lockedItems = options.lockedItems || {}
    const todoDate = this.model.get('todo_date')
    return (this.studentTodoAtDateValue = todoDate ? new Date(todoDate) : '')
  }

  toJSON() {
    let IS
    const json = super.toJSON(...arguments)
    json.use_rce_enhancements = ENV.use_rce_enhancements

    json.IS = IS = {
      TEACHER_ROLE: false,
      STUDENT_ROLE: false,
      MEMBER_ROLE: false,
      ANYONE_ROLE: false
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
      EDIT_ROLES: !!this.WIKI_RIGHTS.manage
    }
    json.SHOW = {COURSE_ROLES: json.contextName === 'courses'}

    json.assignment = json.assignment != null ? json.assignment.toView() : undefined

    json.content_is_locked = this.lockedItems.content

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
  toggleStudentTodo(e) {
    return this.$studentTodoAtContainer.toggle()
  }

  handleStudentTodoUpdate = newDate => {
    this.studentTodoAtDateValue = newDate
    return this.renderStudentTodoAtDate()
  }

  renderStudentTodoAtDate() {
    const elt = this.$studentTodoAtContainer[0]
    if (elt) {
      return ReactDOM.render(
        <DueDateCalendarPicker
          dateType="todo_date"
          name="student_todo_at"
          handleUpdate={this.handleStudentTodoUpdate}
          rowKey="student_todo_at_date"
          labelledBy="student_todo_at_date_label"
          inputClasses=""
          disabled={false}
          isFancyMidnight
          dateValue={this.studentTodoAtDateValue}
          labelText="Student Planner Date"
          labelClasses="screenreader-only"
        />,
        elt
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

    RichContentEditor.initSidebar()
    RichContentEditor.loadNewEditor(this.$wikiPageBody, {focus: true, manageParent: true})

    this.checkUnsavedOnLeave = true
    $(window).on('beforeunload', this.onUnload.bind(this))

    if (!this.firstRender) {
      this.firstRender = true
      $(() =>
        $('[autofocus]:not(:focus)')
          .eq(0)
          .focus()
      )
    }

    this.reloadPending = false
    this.reloadView = new WikiPageReloadView({
      el: this.$pageChangedAlert,
      model: this.model,
      interval: 60000,
      reloadMessage: I18n.t(
        'reload_editing_page',
        'This page has changed since you started editing it. *Reloading* will lose all of your changes.',
        {wrapper: '<a class="reload" href="#">$1</a>'}
      ),
      warning: true
    })
    this.reloadView.on('changed', () => {
      this.$headerBarOuterContainer.addClass('page-changed')
      return (this.reloadPending = true)
    })
    this.reloadView.on('reload', () => this.render())
    this.reloadView.pollForChanges()

    return this.$helpDialog.html(new KeyboardShortcuts().render().$el)
  }

  destroyEditor() {
    RichContentEditor.destroyRCE(this.$wikiPageBody)
    return this.$el.remove()
  }

  switchViews(event) {
    if (event != null) {
      event.preventDefault()
    }
    RichContentEditor.callOnRCE(this.$wikiPageBody, 'toggle')
    // hide the clicked link, and show the other toggle link.
    // todo: replace .andSelf with .addBack when JQuery is upgraded.
    $(event.currentTarget)
      .siblings('a')
      .andSelf()
      .toggle()
      .focus()
  }

  // Validate they entered in a title.
  // @api ValidatedFormView override
  validateFormData(data) {
    const errors = {}

    if (data.title === '') {
      errors.title = [
        {
          type: 'required',
          message: I18n.t('errors.require_title', 'You must enter a title')
        }
      ]
    }

    const studentTodoAtValid = data.student_todo_at != null && data.student_todo_at !== ''
    if (data.student_planner_checkbox && !studentTodoAtValid) {
      errors.student_todo_at = [
        {
          type: 'required',
          message: I18n.t('You must enter a date')
        }
      ]
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
      'You have unsaved changes. Do you want to continue without saving these changes?'
    )
  }

  submit(event) {
    this.checkUnsavedOnLeave = false
    if (this.reloadPending) {
      if (
        !confirm(
          I18n.t(
            'warnings.overwrite_changes',
            'You are about to overwrite other changes that have been made since you started editing.\n\nOverwrite these changes?'
          )
        )
      ) {
        if (event != null) {
          event.preventDefault()
        }
        return
      }
    }

    if (this.reloadView != null) {
      this.reloadView.stopPolling()
    }
    return super.submit(...arguments)
  }

  saveAndPublish(event) {
    this.shouldPublish = true
    return this.submit(event)
  }

  onSaveFail(xhr) {
    this.shouldPublish = false
    return super.onSaveFail(xhr)
  }

  getFormData() {
    const page_data = super.getFormData(...arguments)

    const assign_data = page_data.assignment

    if ((assign_data != null ? assign_data.set_assignment : undefined) === '1') {
      assign_data.only_visible_to_overrides = true
      page_data.assignment = this.model.get('assignment') || this.model.createAssignment()
      page_data.assignment.set(assign_data)
    } else {
      page_data.assignment = this.model.createAssignment({set_assignment: '0'})
    }
    page_data.set_assignment = page_data.assignment.get('set_assignment')
    page_data.student_planner_checkbox = this.$studentPlannerCheckbox.is(':checked')
    if (page_data.student_planner_checkbox) {
      page_data.student_todo_at = this.studentTodoAtDateValue
    } else {
      page_data.student_todo_at = null
    }

    if (this.shouldPublish) page_data.published = true
    return page_data
  }

  cancel(event) {
    if (event != null) {
      event.preventDefault()
    }
    if (!this.hasUnsavedChanges() || confirm(this.unsavedWarning())) {
      this.checkUnsavedOnLeave = false
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
      wiki_pages_path: this.wiki_pages_path
    })
    return deleteDialog.open()
  }
}
WikiPageEditView.initClass()
