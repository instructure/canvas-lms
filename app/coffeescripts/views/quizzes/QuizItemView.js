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

import I18n from 'i18n!quizzes.index'

import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'
import CyoeHelper from 'jsx/shared/conditional_release/CyoeHelper'
import PublishIconView from '../PublishIconView'
import LockIconView from '../LockIconView'
import DateDueColumnView from '../assignments/DateDueColumnView'
import DateAvailableColumnView from '../assignments/DateAvailableColumnView'
import SisButtonView from '../SisButtonView'
import template from 'jst/quizzes/QuizItemView'
import 'jquery.disableWhileLoading'

export default class ItemView extends Backbone.View {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.clickRow = this.clickRow.bind(this)
    this.migrateQuizEnabled = this.migrateQuizEnabled.bind(this)
    this.migrateQuiz = this.migrateQuiz.bind(this)
    this.onDelete = this.onDelete.bind(this)
    this.updatePublishState = this.updatePublishState.bind(this)
    super(...args)
  }

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
      'click .migrate': 'migrateQuiz'
    }

    this.prototype.messages = {
      confirm: I18n.t('confirms.delete_quiz', 'Are you sure you want to delete this quiz?'),
      multipleDates: I18n.t('multiple_due_dates', 'Multiple Dates'),
      deleteSuccessful: I18n.t('flash.removed', 'Quiz successfully deleted.'),
      deleteFail: I18n.t('flash.fail', 'Quiz deletion failed.')
    }
  }

  initialize(options) {
    this.initializeChildViews()
    this.observeModel()
    return super.initialize(...arguments)
  }

  initializeChildViews() {
    this.publishIconView = false
    this.lockIconView = false
    this.sisButtonView = false

    if (this.canManage()) {
      this.publishIconView = new PublishIconView({
        model: this.model,
        title: this.model.get('title')
      })
      this.lockIconView = new LockIconView({
        model: this.model,
        unlockedText: I18n.t('%{name} is unlocked. Click to lock.', {
          name: this.model.get('title')
        }),
        lockedText: I18n.t('%{name} is locked. Click to unlock', {name: this.model.get('title')}),
        course_id: ENV.COURSE_ID,
        content_id: this.model.get('id'),
        content_type: 'quiz'
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
          maxNameLengthRequired: this.model.maxNameLengthRequiredForAccount()
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
    return (location.href = path)
  }

  migrateQuizEnabled() {
    return ENV.FLAGS && ENV.FLAGS.migrate_quiz_enabled
  }

  migrateQuiz(e) {
    e.preventDefault()
    const courseId = ENV.context_asset_string.split('_')[1]
    const quizId = this.options.model.id
    const url = `/api/v1/courses/${courseId}/content_exports?export_type=quizzes2&quiz_id=${quizId}`
    const dfd = $.ajaxJSON(url, 'POST')
    this.$el.disableWhileLoading(dfd)
    return $.when(dfd)
      .done((response, status, deferred) => {
        return $.flashMessage(I18n.t('Migration in progress'))
      })
      .fail(() => {
        return $.flashError(I18n.t('An error occurred while migrating.'))
      })
  }

  canDelete() {
    return this.model.get('permissions').delete
  }

  onDelete(e) {
    e.preventDefault()
    if (this.canDelete()) {
      if (confirm(this.messages.confirm)) return this.delete()
    }
  }

  // delete quiz item
  delete() {
    this.$el.hide()
    return this.model.destroy({
      success: () => {
        this.$el.remove()
        return $.flashMessage(this.messages.deleteSuccessful)
      },
      error: () => {
        this.$el.show()
        return $.flashError(this.messages.deleteFail)
      }
    })
  }

  observeModel() {
    this.model.on('change:published', this.updatePublishState)
    return this.model.on('change:loadingOverrides', this.render)
  }

  updatePublishState() {
    return this.$('.ig-row').toggleClass('ig-published', this.model.get('published'))
  }

  canManage() {
    return ENV.PERMISSIONS.manage
  }

  toJSON() {
    const base = _.extend(this.model.toJSON(), this.options)
    base.quiz_menu_tools = ENV.quiz_menu_tools
    _.each(base.quiz_menu_tools, tool => {
      tool.url = tool.base_url + `&quizzes[]=${this.model.get('id')}`
    })

    base.cyoe = CyoeHelper.getItemData(base.assignment_id, base.quiz_type === 'assignment')
    base.return_to = encodeURIComponent(window.location.pathname)

    if (this.model.get('multiple_due_dates')) {
      base.selector = this.model.get('id')
      base.link_text = this.messages.multipleDates
      base.link_href = this.model.get('url')
    }

    base.migrateQuizEnabled = this.migrateQuizEnabled
    base.showAvailability = this.model.multipleDueDates() || !this.model.defaultDates().available()
    base.showDueDate = this.model.multipleDueDates() || this.model.singleSectionDueDate()

    base.is_locked =
      this.model.get('is_master_course_child_content') &&
      this.model.get('restricted_by_master_course')
    return base
  }
}
ItemView.initClass()
