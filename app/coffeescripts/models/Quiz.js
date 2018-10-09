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
import _ from 'underscore'
import Backbone from 'Backbone'
import Assignment from '../models/Assignment'
import DateGroup from '../models/DateGroup'
import AssignmentOverrideCollection from '../collections/AssignmentOverrideCollection'
import DateGroupCollection from '../collections/DateGroupCollection'
import I18n from 'i18n!quizzes'
import 'jquery.ajaxJSON'
import 'jquery.instructure_misc_helpers'

export default class Quiz extends Backbone.Model {
  initialize(attributes, options = {}) {
    this.publish = this.publish.bind(this)
    this.unpublish = this.unpublish.bind(this)
    this.dueAt = this.dueAt.bind(this)
    this.unlockAt = this.unlockAt.bind(this)
    this.lockAt = this.lockAt.bind(this)
    this.name = this.name.bind(this)
    this.htmlUrl = this.htmlUrl.bind(this)
    this.defaultDates = this.defaultDates.bind(this)
    this.multipleDueDates = this.multipleDueDates.bind(this)
    this.nonBaseDates = this.nonBaseDates.bind(this)
    this.allDates = this.allDates.bind(this)
    this.singleSectionDueDate = this.singleSectionDueDate.bind(this)
    this.postToSIS = this.postToSIS.bind(this)
    this.postToSISName = this.postToSISName.bind(this)
    this.sisIntegrationSettingsEnabled = this.sisIntegrationSettingsEnabled.bind(this)
    this.maxNameLength = this.maxNameLength.bind(this)
    this.maxNameLengthRequiredForAccount = this.maxNameLengthRequiredForAccount.bind(this)
    this.dueDateRequiredForAccount = this.dueDateRequiredForAccount.bind(this)
    this.toView = this.toView.bind(this)
    this.postToSISEnabled = this.postToSISEnabled.bind(this)
    this.objectType = this.objectType.bind(this)

    super.initialize(...arguments)
    this.initAssignment()
    this.initAssignmentOverrides()
    this.initUrls()
    this.initTitleLabel()
    this.initUnpublishable()
    this.initQuestionsCount()
    this.initPointsCount()
    return this.initAllDates()
  }

  // initialize attributes
  initAssignment() {
    if (this.attributes.assignment) {
      this.set('assignment', new Assignment(this.attributes.assignment))
    }
    return this.set('post_to_sis_enabled', this.postToSISEnabled())
  }

  initAssignmentOverrides() {
    if (this.attributes.assignment_overrides) {
      const overrides = new AssignmentOverrideCollection(this.attributes.assignment_overrides)
      return this.set('assignment_overrides', overrides, {silent: true})
    }
  }

  initUrls() {
    if (this.get('html_url')) {
      this.set('base_url', this.get('html_url').replace(/quizzes\/\d+/, 'quizzes'))

      this.set('url', `${this.get('base_url')}/${this.get('id')}`)
      this.set('edit_url', `${this.get('base_url')}/${this.get('id')}/edit`)
      this.set('publish_url', `${this.get('base_url')}/publish`)
      this.set('unpublish_url', `${this.get('base_url')}/unpublish`)
      this.set(
        'toggle_post_to_sis_url',
        `${this.get('base_url')}/${this.get('id')}/toggle_post_to_sis`
      )
    }
  }

  initTitleLabel() {
    return this.set('title_label', this.get('title') || this.get('readable_type'))
  }

  initUnpublishable() {
    if (this.get('can_unpublish') === false && this.get('published')) {
      return this.set('unpublishable', false)
    }
  }

  initQuestionsCount() {
    const cnt = this.get('question_count')
    return this.set('question_count_label', I18n.t('question_count', 'Question', {count: cnt}))
  }

  initPointsCount() {
    const pts = this.get('points_possible')
    let text = ''
    if (pts && pts > 0 && !this.isUngradedSurvey()) {
      text = I18n.t('assignment_points_possible', 'pt', {count: pts})
    }
    return this.set('possible_points_label', text)
  }

  isUngradedSurvey() {
    return this.get('quiz_type') === 'survey'
  }

  initAllDates() {
    let allDates
    if ((allDates = this.get('all_dates')) != null) {
      return this.set('all_dates', new DateGroupCollection(allDates))
    }
  }

  // publishing

  publish() {
    this.set('published', true)
    return $.ajaxJSON(this.get('publish_url'), 'POST', {quizzes: [this.get('id')]})
  }

  unpublish() {
    this.set('published', false)
    return $.ajaxJSON(this.get('unpublish_url'), 'POST', {quizzes: [this.get('id')]})
  }

  disabledMessage() {
    return I18n.t(
      'cant_unpublish_when_students_submit',
      "Can't unpublish if there are student submissions"
    )
  }

  // methods needed by views

  dueAt(date) {
    if (!(arguments.length > 0)) return this.get('due_at')
    return this.set('due_at', date)
  }

  unlockAt(date) {
    if (!(arguments.length > 0)) return this.get('unlock_at')
    return this.set('unlock_at', date)
  }

  lockAt(date) {
    if (!(arguments.length > 0)) return this.get('lock_at')
    return this.set('lock_at', date)
  }

  name(newName) {
    if (!(arguments.length > 0)) return this.get('title')
    return this.set('title', newName)
  }

  htmlUrl() {
    return this.get('url')
  }

  defaultDates() {
    let group
    return (group = new DateGroup({
      due_at: this.get('due_at'),
      unlock_at: this.get('unlock_at'),
      lock_at: this.get('lock_at')
    }))
  }

  multipleDueDates() {
    const dateGroups = this.get('all_dates')
    return dateGroups && dateGroups.length > 1
  }

  nonBaseDates() {
    const dateGroups = this.get('all_dates')
    if (!dateGroups) return false
    const withouBase = _.filter(dateGroups, dateGroup => dateGroup && !dateGroup.get('base'))
    return withouBase.length > 0
  }

  allDates() {
    let result
    const groups = this.get('all_dates')
    const models = (groups && groups.models) || []
    return (result = _.map(models, group => group.toJSON()))
  }

  singleSectionDueDate() {
    return __guard__(_.find(this.allDates(), 'dueAt'), x => x.dueAt.toISOString()) || this.dueAt()
  }

  isOnlyVisibleToOverrides(overrideFlag) {
    if (!(arguments.length > 0)) return this.get('only_visible_to_overrides') || false
    return this.set('only_visible_to_overrides', overrideFlag)
  }

  postToSIS(postToSisBoolean) {
    if (!(arguments.length > 0)) return this.get('post_to_sis')
    return this.set('post_to_sis', postToSisBoolean)
  }

  postToSISName() {
    return ENV.SIS_NAME
  }

  sisIntegrationSettingsEnabled() {
    return ENV.SIS_INTEGRATION_SETTINGS_ENABLED
  }

  maxNameLength() {
    return ENV.MAX_NAME_LENGTH
  }

  maxNameLengthRequiredForAccount() {
    return ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT
  }

  dueDateRequiredForAccount() {
    return ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT
  }

  toView() {
    const fields = [
      'htmlUrl',
      'multipleDueDates',
      'nonBaseDates',
      'allDates',
      'dueAt',
      'lockAt',
      'unlockAt',
      'singleSectionDueDate'
    ]
    const hash = {id: this.get('id')}
    for (const field of fields) {
      hash[field] = this[field]()
    }
    return hash
  }

  postToSISEnabled() {
    return ENV.FLAGS && ENV.FLAGS.post_to_sis_enabled
  }

  objectType() {
    return 'Quiz'
  }
}
Quiz.prototype.resourceName = 'quizzes'

Quiz.prototype.defaults = {
  due_at: null,
  unlock_at: null,
  lock_at: null,
  unpublishable: true,
  points_possible: null,
  post_to_sis: false
}

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
