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
import {map, find, filter} from 'lodash'
import Backbone from '@canvas/backbone'
import Assignment from '@canvas/assignments/backbone/models/Assignment'
import DateGroup from '@canvas/date-group/backbone/models/DateGroup'
import AssignmentOverrideCollection from '@canvas/assignments/backbone/collections/AssignmentOverrideCollection'
import DateGroupCollection from '@canvas/date-group/backbone/collections/DateGroupCollection'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import PandaPubPoller from '@canvas/panda-pub-poller'

const I18n = useI18nScope('modelsQuiz')

export default class Quiz extends Backbone.Model {
  initialize() {
    this.publish = this.publish.bind(this)
    this.unpublish = this.unpublish.bind(this)
    this.dueAt = this.dueAt.bind(this)
    this.unlockAt = this.unlockAt.bind(this)
    this.lockAt = this.lockAt.bind(this)
    this.name = this.name.bind(this)
    this.htmlUrl = this.htmlUrl.bind(this)
    this.buildUrl = this.buildUrl.bind(this)
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
    this.isDuplicating = this.isDuplicating.bind(this)
    this.isMigrating = this.isMigrating.bind(this)
    this.isImporting = this.isImporting.bind(this)
    this.importantDates = this.importantDates.bind(this)
    this.isCloningAlignment = this.isCloningAlignment.bind(this)

    super.initialize(...arguments)
    this.initId()
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
  initId() {
    this.id = this.isQuizzesNext() ? `assignment_${this.get('id')}` : this.get('id')
  }

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
      this.set('base_url', this.get('html_url').replace(/(quizzes|assignments)\/\d+/, '$1'))
      this.set('url', this.url())
      this.set('edit_url', this.edit_url())
      this.set('build_url', this.build_url())
      this.set('publish_url', this.publish_url())
      this.set('deletion_url', this.deletion_url())
      this.set('unpublish_url', this.unpublish_url())
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
    if (cnt) {
      this.set('question_count_label', I18n.t('question_count', 'Question', {count: cnt}))
    }
  }

  initPointsCount() {
    const pts = this.get('points_possible')
    let text = ''
    if (pts && pts > 0 && !this.isUngradedSurvey()) {
      text = Number.isInteger(pts)
        ? I18n.t('assignment_points_possible', 'pt', {count: pts})
        : I18n.t('%{points} pts', {points: I18n.n(pts)})
    }
    return this.set('possible_points_label', text)
  }

  isQuizzesNext() {
    return this.get('quiz_type') === 'quizzes.next'
  }

  isUngradedSurvey() {
    return this.get('quiz_type') === 'survey'
  }

  isMasterCourseChildContent() {
    const migration_id = this.get('migration_id')
    return migration_id && migration_id.indexOf('mastercourse_') === 0
  }

  publish_url() {
    if (this.isQuizzesNext()) {
      return `${this.get('base_url')}/publish/quiz`
    }
    return `${this.get('base_url')}/publish`
  }

  unpublish_url() {
    if (this.isQuizzesNext()) {
      return `${this.get('base_url')}/unpublish/quiz`
    }
    return `${this.get('base_url')}/unpublish`
  }

  url() {
    if (this.isQuizzesNext() && ENV.PERMISSIONS?.manage) {
      return this.edit_url()
    }
    return this.build_url()
  }

  build_url() {
    return `${this.get('base_url')}/${this.get('id')}`
  }

  edit_url() {
    const query_string = this.isQuizzesNext() ? '?quiz_lti' : ''
    return `${this.get('base_url')}/${this.get('id')}/edit${query_string}`
  }

  deletion_url() {
    if (this.isQuizzesNext()) {
      return `${this.get('base_url')}/${this.get('id')}`
    }

    return this.get('url')
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

  importantDates(important) {
    if (!(arguments.length > 0)) return this.get('important_dates')
    return this.set('important_dates', important)
  }

  isDuplicating() {
    return this.get('workflow_state') === 'duplicating'
  }

  isCloningAlignment() {
    return this.get('workflow_state') === 'outcome_alignment_cloning'
  }

  isMigrating() {
    return this.get('workflow_state') === 'migrating'
  }

  isImporting() {
    return this.get('workflow_state') === 'importing'
  }

  name(newName) {
    if (!(arguments.length > 0)) return this.get('title')
    return this.set('title', newName)
  }

  htmlUrl() {
    return this.get('url')
  }

  buildUrl() {
    return this.get('build_url')
  }

  destroy(options) {
    const opts = {
      url: this.get('deletion_url'),
      ...options,
    }
    Backbone.Model.prototype.destroy.call(this, opts)
  }

  defaultDates() {
    return new DateGroup({
      due_at: this.get('due_at'),
      unlock_at: this.get('unlock_at'),
      lock_at: this.get('lock_at'),
    })
  }

  // caller is original assignments
  duplicate(callback) {
    const course_id = this.get('course_id')
    const assignment_id = this.get('id')
    return $.ajaxJSON(
      `/api/v1/courses/${course_id}/assignments/${assignment_id}/duplicate`,
      'POST',
      {quizzes: [assignment_id], result_type: 'Quiz'},
      callback
    )
  }

  // caller is failed assignments
  duplicate_failed(callback) {
    const target_course_id = this.get('course_id')
    const target_assignment_id = this.get('id')
    const original_course_id = this.get('original_course_id')
    const original_assignment_id = this.get('original_assignment_id')
    let query_string = `?target_assignment_id=${target_assignment_id}`
    if (original_course_id !== target_course_id) {
      // when it's a course copy failure
      query_string += `&target_course_id=${target_course_id}`
    }
    $.ajaxJSON(
      `/api/v1/courses/${original_course_id}/assignments/${original_assignment_id}/duplicate${query_string}`,
      'POST',
      {},
      callback
    )
  }

  alignment_clone_failed(callback) {
    const target_course_id = this.get('course_id')
    const target_assignment_id = this.get('id')
    const original_course_id = this.get('original_course_id')
    const original_assignment_id = this.get('original_assignment_id')
    let query_string = `?target_assignment_id=${target_assignment_id}`
    if (original_course_id !== target_course_id) {
      // when it's a course copy failure
      query_string += `&target_course_id=${target_course_id}`
    }
    $.ajaxJSON(
      `/api/v1/courses/${original_course_id}/assignments/${original_assignment_id}/retry_alignment_clone${query_string}`,
      'POST',
      {},
      callback
    )
  }

  // caller is failed migrated assignment
  retry_migration(callback) {
    const course_id = this.get('course_id')
    const original_quiz_id = this.get('original_quiz_id')
    $.ajaxJSON(
      `/api/v1/courses/${course_id}/content_exports?export_type=quizzes2&quiz_id=${original_quiz_id}&include[]=migrated_quiz`,
      'POST',
      {},
      callback
    )
  }

  pollUntilFinishedLoading(interval) {
    if (this.isDuplicating()) {
      this.pollUntilFinished(interval, this.isDuplicating)
    }
    if (this.isMigrating()) {
      this.pollUntilFinished(interval, this.isMigrating)
    }
    if (this.isCloningAlignment()) {
      this.pollUntilFinished(interval, this.isCloningAlignment)
    }
    if (this.isImporting()) {
      this.pollUntilFinished(interval, this.isImporting)
    }
  }

  pollUntilFinished(interval, isProcessing) {
    const course_id = this.get('course_id')
    const id = this.get('id')
    const poller = new PandaPubPoller(interval, interval * 5, done => {
      this.fetch({
        url: `/api/v1/courses/${course_id}/assignments/${id}?result_type=Quiz`,
      }).always(() => {
        done()
        if (!isProcessing()) {
          return poller.stop()
        }
      })
    })
    poller.start()
  }

  multipleDueDates() {
    const dateGroups = this.get('all_dates')
    return dateGroups && dateGroups.length > 1
  }

  nonBaseDates() {
    const dateGroups = this.get('all_dates')
    if (!dateGroups) return false
    const withouBase = filter(dateGroups, dateGroup => dateGroup && !dateGroup.get('base'))
    return withouBase.length > 0
  }

  allDates() {
    const groups = this.get('all_dates')
    const models = (groups && groups.models) || []
    return map(models, group => group.toJSON())
  }

  singleSectionDueDate() {
    return __guard__(find(this.allDates(), 'dueAt'), x => x.dueAt.toISOString()) || this.dueAt()
  }

  isOnlyVisibleToOverrides(overrideFlag) {
    if (!(arguments.length > 0)) {
      if (ENV.FEATURES?.differentiated_modules && this.get('visible_to_everyone') != null) {
        return !this.get('visible_to_everyone')
      }
      return this.get('only_visible_to_overrides') || false
    }
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
      'buildUrl',
      'multipleDueDates',
      'nonBaseDates',
      'allDates',
      'dueAt',
      'lockAt',
      'unlockAt',
      'singleSectionDueDate',
      'importantDates',
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
  post_to_sis: false,
  require_lockdown_browser: false,
}

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
