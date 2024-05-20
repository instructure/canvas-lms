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
//

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import ajax from 'ic-ajax'
import {ApolloProvider, createClient} from '@canvas/apollo'
import round from '@canvas/round'
import userSettings from '@canvas/user-settings'
import fetchAllPages from '../helpers/xhr/fetch_all_pages'
import parseLinkHeader from '../helpers/xhr/parse_link_header'
import {useScope as useI18nScope} from '@canvas/i18n'
import Ember from 'ember'
import {
  compact,
  extend,
  filter,
  flatten,
  forEach,
  includes,
  intersection,
  isNumber,
  keyBy,
  map,
  reduce,
  some,
  uniq,
} from 'lodash'
import * as tz from '@canvas/datetime'
import AssignmentDetailsDialog from '../../jquery/AssignmentDetailsDialog'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import {updateWithSubmissions, scopeToUser} from '@canvas/grading/EffectiveDueDates'
import outcomeGrid from '@canvas/outcome-gradebook-grid'
import CalculationMethodContent from '@canvas/grading/CalculationMethodContent'
import SubmissionStateMap from '@canvas/grading/SubmissionStateMap'
import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import GradingPeriodsApi from '@canvas/grading/jquery/gradingPeriodsApi'
import GradingPeriodSetsApi from '@canvas/grading/jquery/gradingPeriodSetsApi'
import ProxyUploadModal from '@canvas/proxy-submission/react/ProxyUploadModal'
import {updateFinalGradeOverride} from '@canvas/grading/FinalGradeOverrideApi'
import '@canvas/datetime/jquery'
import 'jquery-tinypubsub'

import '../components/ic_submission_download_dialog_component'

const I18n = useI18nScope('sr_gradebook')

const {get, set, setProperties} = Ember

// http://emberjs.com/guides/controllers/
// http://emberjs.com/api/classes/Ember.Controller.html
// http://emberjs.com/api/classes/Ember.ArrayController.html
// http://emberjs.com/api/classes/Ember.ObjectController.html

function studentsUniqByEnrollments(...args) {
  let hiddenNameCounter = 1
  const options = {
    initialize(array, changeMeta, instanceMeta) {
      return (instanceMeta.students = {})
    },
    addedItem(array, enrollment, changeMeta, iMeta) {
      const student = iMeta.students[enrollment.user_id] || enrollment.user
      if (student.hiddenName == null) {
        student.hiddenName = I18n.t('student_hidden_name', 'Student %{position}', {
          position: hiddenNameCounter,
        })
        hiddenNameCounter += 1
      }
      if (!student.sections) {
        student.sections = []
      }
      student.sections.push(enrollment.course_section_id)
      if (!student.role) {
        student.role = enrollment.role
      }
      student.isInactive = enrollment.enrollment_state === 'inactive'
      student.isTestStudent = enrollment.type === 'StudentViewEnrollment'
      if (iMeta.students[student.id]) {
        return array
      }
      iMeta.students[student.id] = student
      array.pushObject(student)
      return array
    },
    removedItem(array, enrollment, __, instanceMeta) {
      const student = array.findBy('id', enrollment.user_id)
      student.sections.removeObject(enrollment.course_section_id)

      if (student.sections.length === 0) {
        delete instanceMeta.students[student.id]
        array.removeObject(student)
        hiddenNameCounter -= 1
      }
      return array
    },
  }
  args.push(options)
  return Ember.arrayComputed.apply(null, args)
}

const contextUrl = get(window, 'ENV.GRADEBOOK_OPTIONS.context_url')

const ScreenreaderGradebookController = Ember.ObjectController.extend({
  init() {
    this.set('effectiveDueDates', Ember.ObjectProxy.create({content: {}}))
    this.set('proxyUploadOpen', false)
    return this.set(
      'assignmentsFromGroups',
      Ember.ArrayProxy.create({content: [], isLoaded: false})
    )
  },

  checkForCsvExport: function () {
    const currentProgress = get(window, 'ENV.GRADEBOOK_OPTIONS.gradebook_csv_progress')
    const attachment = get(window, 'ENV.GRADEBOOK_OPTIONS.attachment')

    if (
      currentProgress &&
      currentProgress.progress.workflow_state !== 'completed' &&
      currentProgress.progress.workflow_state !== 'failed'
    ) {
      const attachmentProgress = {
        progress_id: currentProgress.progress.id,
        attachment_id: attachment.attachment.id,
      }

      $('#gradebook-export').prop('disabled', true)
      $('#last-exported-gradebook').hide()
      this.pollGradebookCsvProgress(attachmentProgress)
    }
  }.on('init'),

  contextUrl,
  uploadCsvUrl: `${contextUrl}/gradebook_upload/new`,

  lastGeneratedCsvAttachmentUrl: get(window, 'ENV.GRADEBOOK_OPTIONS.attachment_url'),

  downloadOutcomeCsvUrl: `${contextUrl}/outcome_rollups.csv`,

  gradingHistoryUrl: `${contextUrl}/gradebook/history`,

  submissionsUrl: get(window, 'ENV.GRADEBOOK_OPTIONS.submissions_url'),

  has_grading_periods: get(window, 'ENV.GRADEBOOK_OPTIONS.grading_period_set') != null,

  getGradingPeriodSet() {
    const grading_period_set = get(window, 'ENV.GRADEBOOK_OPTIONS.grading_period_set')
    if (grading_period_set) {
      return GradingPeriodSetsApi.deserializeSet(grading_period_set)
    } else {
      return null
    }
  },

  gradingPeriods: (function () {
    const periods = get(window, 'ENV.GRADEBOOK_OPTIONS.active_grading_periods')
    const deserializedPeriods = GradingPeriodsApi.deserializePeriods(periods)
    const optionForAllPeriods = {
      id: '0',
      title: I18n.t('all_grading_periods', 'All Grading Periods'),
    }
    return compact([optionForAllPeriods].concat(deserializedPeriods))
  })(),

  lastGeneratedCsvLabel: (() => {
    if (get(window, 'ENV.GRADEBOOK_OPTIONS.gradebook_csv_progress')) {
      const gradebook_csv_export_date = get(
        window,
        'ENV.GRADEBOOK_OPTIONS.gradebook_csv_progress.progress.updated_at'
      )
      return I18n.t('Download Scores Generated on %{date}', {
        date: $.datetimeString(gradebook_csv_export_date),
      })
    }
  })(),

  selectedGradingPeriod: function (_key, newValue) {
    let savedGP
    const savedGradingPeriodId = userSettings.contextGet('gradebook_current_grading_period')
    if (savedGradingPeriodId) {
      savedGP = this.get('gradingPeriods').findBy('id', savedGradingPeriodId)
    }
    if (newValue) {
      userSettings.contextSet('gradebook_current_grading_period', newValue.id)
      return newValue
    } else if (savedGP != null) {
      return savedGP
    } else {
      // default to current grading period, but don't change saved setting
      return this.get('gradingPeriods').findBy(
        'id',
        ENV.GRADEBOOK_OPTIONS.current_grading_period_id
      )
    }
  }.property(),

  speedGraderUrl: function () {
    return `${contextUrl}/gradebook/speed_grader?assignment_id=${this.get('selectedAssignment.id')}`
  }.property('selectedAssignment'),

  studentUrl: function () {
    return `${contextUrl}/grades/${this.get('selectedStudent.id')}`
  }.property('selectedStudent'),

  showTotalAsPoints: (() => ENV.GRADEBOOK_OPTIONS.show_total_grade_as_points).property(),

  publishToSisEnabled: (() => ENV.GRADEBOOK_OPTIONS.publish_to_sis_enabled).property(),

  publishToSisURL: (() => ENV.GRADEBOOK_OPTIONS.publish_to_sis_url).property(),

  teacherNotes: (() => ENV.GRADEBOOK_OPTIONS.teacher_notes).property().volatile(),

  changeGradebookVersionUrl: (() =>
    `${get(window, 'ENV.GRADEBOOK_OPTIONS.change_gradebook_version_url')}`).property(),

  hideOutcomes: (() => !get(window, 'ENV.GRADEBOOK_OPTIONS.outcome_gradebook_enabled')).property(),

  showDownloadSubmissionsButton: function () {
    const hasSubmittedSubmissions = this.get('selectedAssignment.has_submitted_submissions')
    const allowList = ['online_upload', 'online_text_entry', 'online_url']
    const submissionTypes = this.get('selectedAssignment.submission_types')
    const submissionTypesOnAllowlist = intersection(submissionTypes, allowList)

    return hasSubmittedSubmissions && some(submissionTypesOnAllowlist)
  }.property('selectedAssignment'),

  hideStudentNames: false,

  showConcludedEnrollments: function () {
    if (!ENV.GRADEBOOK_OPTIONS.settings) {
      return false
    }
    return ENV.GRADEBOOK_OPTIONS.settings.show_concluded_enrollments === 'true'
  }
    .property()
    .volatile(),

  updateShowConcludedEnrollmentsSetting: function () {
    ajax.request({
      dataType: 'json',
      type: 'put',
      url: ENV.GRADEBOOK_OPTIONS.settings_update_url,
      data: {
        gradebook_settings: {
          show_concluded_enrollments: this.get('showConcludedEnrollments'),
        },
      },
    })
  }.observes('showConcludedEnrollments'),

  finalGradeOverrideEnabled: (() => ENV.GRADEBOOK_OPTIONS.final_grade_override_enabled).property(),

  allowFinalGradeOverride: function () {
    if (!ENV.GRADEBOOK_OPTIONS.course_settings) {
      return false
    }

    return ENV.GRADEBOOK_OPTIONS.course_settings.allow_final_grade_override
  }
    .property()
    .volatile(),

  updateAllowFinalGradeOverride: function () {
    ajax.request({
      dataType: 'json',
      type: 'put',
      url: `/api/v1/courses/${ENV.GRADEBOOK_OPTIONS.context_id}/settings`,
      data: {
        allow_final_grade_override: this.get('allowFinalGradeOverride'),
      },
    })
  }.observes('allowFinalGradeOverride'),

  selectedStudentFinalGradeOverrideChanged: function () {
    const student = this.get('selectedStudent')

    if (!student) {
      return
    }

    const gradingPeriodId = this.get('selectedGradingPeriod.id')
    const studentOverrides = this.overridesForStudent(student.id)

    if (!studentOverrides) {
      this.set('selectedStudentFinalGradeOverride', null)
      return
    }

    if (gradingPeriodId === '0' || gradingPeriodId == null) {
      this.set('selectedStudentFinalGradeOverride', {...studentOverrides.courseGrade})
    } else {
      this.set('selectedStudentFinalGradeOverride', {
        ...studentOverrides.gradingPeriodGrades[gradingPeriodId],
      })
    }
  }
    .observes(
      'selectedStudent',
      'selectedGradingPeriod',
      'final_grade_overrides',
      'final_grade_overrides.content'
    )
    .on('init'),

  selectedAssignmentPointsPossible: function () {
    return I18n.n(this.get('selectedAssignment.points_possible'))
  }.property('selectedAssignment'),

  selectedStudent: null,

  selectedStudentFinalGradeOverride: null,

  selectedSection: null,

  selectedAssignment: null,

  weightingScheme: null,

  ariaAnnounced: null,

  assignmentInClosedGradingPeriod: null,

  disableAssignmentGrading: null,

  actions: {
    columnUpdated(columnData, columnID) {
      return this.updateColumnData(columnData, columnID)
    },

    exportGradebookCsv() {
      $('#gradebook-export').prop('disabled', true)
      $('#last-exported-gradebook').hide()

      return $.ajaxJSON(ENV.GRADEBOOK_OPTIONS.export_gradebook_csv_url, 'POST').then(
        attachment_progress => this.pollGradebookCsvProgress(attachment_progress)
      )
    },

    gradeUpdated(submissions) {
      return this.updateSubmissionsFromExternal(submissions)
    },

    onEditFinalGradeOverride(grade) {
      const options = {}

      if (ENV.GRADEBOOK_OPTIONS.grading_standard) {
        options.gradingScheme = {
          data: ENV.GRADEBOOK_OPTIONS.grading_standard,
          pointsBased: ENV.GRADEBOOK_OPTIONS.gradingStandardPointsBased,
        }
      }

      const gradeOverrideEntry = new GradeOverrideEntry(options)
      const currentOverride = this.get('selectedStudentFinalGradeOverride') || {}
      const enteredGrade = gradeOverrideEntry.parseValue(grade)
      const existingGrade = gradeOverrideEntry.parseValue(currentOverride.percentage)

      if (!enteredGrade.valid || !gradeOverrideEntry.hasGradeChanged(existingGrade, enteredGrade)) {
        return
      }

      const gradingPeriodId = this.get('selectedGradingPeriod.id')
      const records = this.get('final_grade_overrides')
      const overrides = records.get('content.finalGradeOverrides')
      const student = this.get('selectedStudent')
      const studentOverrides = this.overridesForStudent(student.id)
      const studentEnrollment = this.get('enrollments').content.find(
        enrollment => enrollment.user_id === student.id
      )

      if (gradingPeriodId === '0' || gradingPeriodId == null) {
        studentOverrides.courseGrade.percentage = enteredGrade.grade.percentage
        updateFinalGradeOverride(studentEnrollment.id, null, enteredGrade.grade)
      } else {
        studentOverrides.gradingPeriodGrades[gradingPeriodId].percentage =
          enteredGrade.grade.percentage
        updateFinalGradeOverride(studentEnrollment.id, gradingPeriodId, enteredGrade.grade)
      }

      records.set('content', {finalGradeOverrides: overrides})
    },

    selectItem(property, item) {
      return this.announce(property, item)
    },
    openProxyUploadModal() {
      this.set('proxyUploadOpen', true)
    },
  },

  overridesForStudent(studentId) {
    const records = this.get('final_grade_overrides')

    if (!records || !records.get('isLoaded')) {
      return null
    }

    const overrides = records.get('content.finalGradeOverrides')
    const studentOverrides = overrides[studentId] || {}
    studentOverrides.courseGrade = studentOverrides.courseGrade || {}
    studentOverrides.gradingPeriodGrades = studentOverrides.gradingPeriodGrades || {}

    this.get('gradingPeriods').forEach(gp => {
      studentOverrides.gradingPeriodGrades[gp.id] =
        studentOverrides.gradingPeriodGrades[gp.id] || {}
    })

    overrides[studentId] = studentOverrides
    records.set('content.finalGradeOverrides', {...overrides})

    return studentOverrides
  },

  pollGradebookCsvProgress(attachmentProgress) {
    let pollingProgress
    const self = this
    return (pollingProgress = setInterval(
      () =>
        $.ajaxJSON(`/api/v1/progress/${attachmentProgress.progress_id}`, 'GET').then(response => {
          if (response.workflow_state === 'completed') {
            // eslint-disable-next-line promise/catch-or-return
            $.ajaxJSON(
              `/api/v1/users/${ENV.current_user_id}/files/${attachmentProgress.attachment_id}`,
              'GET'
            ).then(attachment => {
              self.updateGradebookExportOptions(pollingProgress)
              document.getElementById('gradebook-export-iframe').src = attachment.url
              return $('#last-exported-gradebook').attr('href', attachment.url)
            })
          }

          if (response.workflow_state === 'failed') {
            return self.updateGradebookExportOptions(pollingProgress)
          }
        }),
      2000
    ))
  },

  updateGradebookExportOptions: pollingProgress => {
    clearInterval(pollingProgress)
    $('#gradebook-export').prop('disabled', false)
    return $('#last-exported-gradebook').show()
  },

  announce(prop, item) {
    return Ember.run.next(() => {
      let text_to_announce
      if (prop === 'student' && this.get('hideStudentNames')) {
        text_to_announce = get(item, 'hiddenName')
      } else if (prop === 'outcome') {
        text_to_announce = get(item, 'title')
      } else {
        text_to_announce = get(item, 'name')
      }
      this.set('ariaAnnounced', text_to_announce)
    })
  },

  hideStudentNamesChanged: function () {
    this.set('ariaAnnounced', null)
  }.observes('hideStudentNames'),

  setupSubmissionCallback: function () {
    Ember.$.subscribe('submissions_updated', this.updateSubmissionsFromExternal.bind(this))
  }.on('init'),

  setupAssignmentWeightingScheme: function () {
    this.set('weightingScheme', ENV.GRADEBOOK_OPTIONS.group_weighting_scheme)
  }.on('init'),

  willDestroy() {
    Ember.$.unsubscribe('submissions_updated')
    return this._super()
  },

  updateSubmissionsFromExternal(submissions) {
    const subs_proxy = this.get('submissions')
    const selected = this.get('selectedSubmission')
    const studentsById = this.groupById(this.get('students'))
    const assignmentsById = this.groupById(this.get('assignments'))
    return submissions.forEach(submission => {
      const student = studentsById[submission.user_id]
      const submissionsForStudent = subs_proxy.findBy('user_id', submission.user_id)
      const oldSubmission = submissionsForStudent.submissions.findBy(
        'assignment_id',
        submission.assignment_id
      )

      // check for DA visibility
      if (submission.assignment_visible != null) {
        set(submission, 'hidden', !submission.assignment_visible)
        this.updateAssignmentVisibilities(
          assignmentsById[submission.assignment_id],
          submission.user_id
        )
      }

      submissionsForStudent.submissions.removeObject(oldSubmission)
      submissionsForStudent.submissions.addObject(submission)
      this.updateSubmission(submission, student)
      this.calculateStudentGrade(student)
      if (
        selected &&
        selected.assignment_id === submission.assignment_id &&
        selected.user_id === submission.user_id
      ) {
        set(this, 'selectedSubmission', submission)
      }
    })
  },

  updateAssignmentVisibilities(assignment, userId) {
    const visibilities = get(assignment, 'assignment_visibility')
    const filteredVisibilities =
      visibilities != null ? visibilities.filter(id => id !== userId) : undefined
    return set(assignment, 'assignment_visibility', filteredVisibilities)
  },

  subtotalByGradingPeriod() {
    const selectedPeriodID = this.get('selectedGradingPeriod.id')
    return selectedPeriodID && selectedPeriodID === '0' && this.periodsAreWeighted()
  },

  calculate(student) {
    const submissions = this.submissionsForStudent(student)
    const assignmentGroups = this.assignmentGroupsHash()
    const weightingScheme = this.get('weightingScheme')
    const gradingPeriodSet = this.getGradingPeriodSet()
    const effectiveDueDates = this.get('effectiveDueDates.content')
    const hasGradingPeriods = gradingPeriodSet && effectiveDueDates

    return CourseGradeCalculator.calculate(
      submissions,
      assignmentGroups,
      weightingScheme,
      ENV?.GRADEBOOK_OPTIONS?.grade_calc_ignore_unposted_anonymous_enabled,
      hasGradingPeriods ? gradingPeriodSet : undefined,
      hasGradingPeriods ? scopeToUser(effectiveDueDates, student.id) : undefined
    )
  },

  submissionsForStudent(student) {
    const allSubmissions = (() => {
      const result = []
      for (const key in student) {
        const value = student[key]
        if (key.match(/^assignment_(?!group)/)) {
          result.push(value)
        }
      }
      return result
    })()
    if (!this.get('has_grading_periods')) {
      return allSubmissions
    }
    const selectedPeriodID = this.get('selectedGradingPeriod.id')
    if (!selectedPeriodID || selectedPeriodID === '0') {
      return allSubmissions
    }

    return filter(allSubmissions, submission => {
      const studentPeriodInfo = __guard__(
        this.get('effectiveDueDates').get(submission.assignment_id),
        x => x[submission.user_id]
      )
      return studentPeriodInfo && studentPeriodInfo.grading_period_id === selectedPeriodID
    })
  },

  calculateSingleGrade(student, key, gradeFinalOrCurrent) {
    set(student, key, gradeFinalOrCurrent)
    if (gradeFinalOrCurrent != null ? gradeFinalOrCurrent.submissions : undefined) {
      return Array.from(gradeFinalOrCurrent.submissions).map(submissionData =>
        set(submissionData.submission, 'drop', submissionData.drop)
      )
    }
  },

  calculateStudentGrade(student) {
    if (student.isLoaded) {
      let grade
      let grades = this.calculate(student)

      const selectedPeriodID = this.get('selectedGradingPeriod.id')
      if (selectedPeriodID && selectedPeriodID !== '0') {
        grades = grades.gradingPeriods[selectedPeriodID]
      }

      const finalOrCurrent = this.get('includeUngradedAssignments') ? 'final' : 'current'

      if (this.subtotalByGradingPeriod()) {
        for (const gradingPeriodId in grades.gradingPeriods) {
          grade = grades.gradingPeriods[gradingPeriodId]
          this.calculateSingleGrade(
            student,
            `grading_period_${gradingPeriodId}`,
            grade[finalOrCurrent]
          )
        }
      } else {
        for (const assignmentGroupId in grades.assignmentGroups) {
          grade = grades.assignmentGroups[assignmentGroupId]
          this.calculateSingleGrade(
            student,
            `assignment_group_${assignmentGroupId}`,
            grade[finalOrCurrent]
          )
        }
      }

      grades = grades[finalOrCurrent]

      let percent = round((grades.score / grades.possible) * 100, 2)
      if (Number.isNaN(Number(percent))) {
        percent = 0
      }
      return setProperties(student, {
        total_grade: grades,
        total_percent: percent,
      })
    }
  },

  calculateAllGrades: function () {
    return this.get('students').forEach(student => this.calculateStudentGrade(student))
  }.observes(
    'includeUngradedAssignments',
    'groupsAreWeighted',
    'assignment_groups.@each.group_weight',
    'selectedGradingPeriod',
    'gradingPeriods.@each.weight'
  ),

  sectionSelectDefaultLabel: I18n.t('all_sections', 'All Sections'),
  studentSelectDefaultLabel: I18n.t('no_student', 'No Student Selected'),
  assignmentSelectDefaultLabel: I18n.t('no_assignment', 'No Assignment Selected'),
  outcomeSelectDefaultLabel: I18n.t('no_outcome', 'No Outcome Selected'),

  submissionStateMap: null,

  assignment_groups: [],
  assignment_subtotals: [],
  subtotal_by_period: false,

  fetchAssignmentGroups: function () {
    const params = {
      exclude_response_fields: ['in_closed_grading_period', 'rubric'],
      hide_zero_point_quizzes: ENV.GRADEBOOK_OPTIONS.hide_zero_point_quizzes,
    }
    const gpId = this.get('selectedGradingPeriod.id')
    if (this.get('has_grading_periods') && gpId !== '0') {
      params.grading_period_id = gpId
    }
    this.set('assignment_groups', [])
    this.get('assignmentsFromGroups').setProperties({content: [], isLoaded: false})
    return Ember.run.once(() =>
      fetchAllPages(get(window, 'ENV.GRADEBOOK_OPTIONS.assignment_groups_url'), {
        data: params,
        records: this.get('assignment_groups'),
      })
    )
  }
    .observes('selectedGradingPeriod')
    .on('init'),

  pushAssignmentGroups(subtotals) {
    this.set('subtotal_by_period', false)
    const weighted = this.get('groupsAreWeighted')
    return (() => {
      const result = []
      for (const group of Array.from(this.get('assignment_groups'))) {
        const subtotal = {
          name: group.name,
          key: `assignment_group_${group.id}`,
          weight: weighted && group.group_weight,
        }
        result.push(subtotals.push(subtotal))
      }
      return result
    })()
  },

  pushGradingPeriods(subtotals) {
    this.set('subtotal_by_period', true)
    const weighted = this.periodsAreWeighted()
    return (() => {
      const result = []
      for (const period of Array.from(this.get('gradingPeriods'))) {
        if (period.id > 0) {
          const subtotal = {
            name: period.title,
            key: `grading_period_${period.id}`,
            weight: weighted && period.weight,
          }
          result.push(subtotals.push(subtotal))
        } else {
          result.push(undefined)
        }
      }
      return result
    })()
  },

  assignmentSubtotals: function () {
    const subtotals = []
    if (this.subtotalByGradingPeriod()) {
      this.pushGradingPeriods(subtotals)
    } else {
      this.pushAssignmentGroups(subtotals)
    }
    return this.set('assignment_subtotals', subtotals)
  }
    .observes(
      'assignment_groups',
      'gradingPeriods',
      'selectedGradingPeriod',
      'students.@each',
      'selectedStudent'
    )
    .on('init'),

  students: studentsUniqByEnrollments('enrollments'),

  studentsHash() {
    const students = {}
    this.get('students').forEach(s => {
      if (s.role !== 'StudentViewEnrollment') {
        students[s.id] = s
      }
    })
    return students
  },

  processLoadingSubmissions(submissionGroups) {
    const submissions = []

    forEach(submissionGroups, submissionGroup => {
      submissions.push(...Array.from(submissionGroup.submissions || []))
    })

    this.updateEffectiveDueDatesFromSubmissions(submissions)
    const assignmentIds = uniq(map(submissions, 'assignment_id'))
    const assignmentMap = keyBy(this.get('assignmentsFromGroups.content'), 'id')
    assignmentIds.forEach(assignmentId => {
      const assignment = assignmentMap[assignmentId]
      if (assignment) {
        this.updateEffectiveDueDatesOnAssignment(assignment)
      }
    })

    return submissionGroups
  },

  fetchStudentSubmissions: function () {
    return Ember.run.once(() => {
      const notYetLoaded = this.get('students').filter(student => {
        if (get(student, 'isLoaded') || get(student, 'isLoading')) {
          return false
        }
        set(student, 'isLoading', true)
        return student
      })

      if (!notYetLoaded.length) {
        return
      }
      const studentIds = notYetLoaded.mapBy('id')

      while (studentIds.length) {
        const chunk = studentIds.splice(0, ENV.GRADEBOOK_OPTIONS.chunk_size || 20)
        fetchAllPages(ENV.GRADEBOOK_OPTIONS.submissions_url, {
          data: {student_ids: chunk},
          process: submissions => this.processLoadingSubmissions(submissions),
          records: this.get('submissions'),
        })
      }
    })
  }
    .observes('students.@each', 'selectedGradingPeriod')
    .on('init'),

  showNotesColumn: function () {
    const notes = this.get('teacherNotes')
    if (notes) {
      return !notes.hidden
    } else {
      return false
    }
  }
    .property()
    .volatile(),

  shouldCreateNotes: function () {
    return !this.get('teacherNotes') && this.get('showNotesColumn')
  }.property('teacherNotes', 'showNotesColumn', 'custom_columns.@each'),

  notesURL: function () {
    if (this.get('shouldCreateNotes')) {
      return window.ENV.GRADEBOOK_OPTIONS.custom_columns_url
    } else {
      const notesID = __guard__(this.get('teacherNotes'), x => x.id)
      return window.ENV.GRADEBOOK_OPTIONS.custom_column_url.replace(/:id/, notesID)
    }
  }.property('shouldCreateNotes', 'custom_columns.@each'),

  notesParams: function () {
    if (this.get('shouldCreateNotes')) {
      return {
        'column[title]': I18n.t('notes', 'Notes'),
        'column[position]': 1,
        'column[teacher_notes]': true,
      }
    } else {
      return {'column[hidden]': !this.get('showNotesColumn')}
    }
  }.property('shouldCreateNotes', 'showNotesColumn'),

  notesVerb: function () {
    if (this.get('shouldCreateNotes')) {
      return 'POST'
    } else {
      return 'PUT'
    }
  }.property('shouldCreateNotes'),

  updateOrCreateNotesColumn: function () {
    return ajax
      .request({
        dataType: 'json',
        type: this.get('notesVerb'),
        url: this.get('notesURL'),
        data: this.get('notesParams'),
      })
      .then(this.boundNotesSuccess)
  }.observes('showNotesColumn'),

  bindNotesSuccess: function () {
    return (this.boundNotesSuccess = this.onNotesUpdateSuccess.bind(this))
  }.on('init'),

  onNotesUpdateSuccess(col) {
    const customColumns = this.get('custom_columns')
    const method = col.hidden ? 'removeObject' : 'unshiftObject'
    const column = customColumns.findBy('id', col.id) || col
    customColumns[method](column)

    if (col.teacher_notes) {
      this.set('teacherNotes', col)
    }

    if (!col.hidden) {
      return ajax.request({
        url: ENV.GRADEBOOK_OPTIONS.reorder_custom_columns_url,
        type: 'POST',
        data: {
          order: customColumns.mapBy('id'),
        },
      })
    }
  },

  groupsAreWeighted: function () {
    return this.get('weightingScheme') === 'percent'
  }.property('weightingScheme'),

  periodsAreWeighted() {
    return !!__guard__(this.getGradingPeriodSet(), x => x.weighted)
  },

  gradesAreWeighted: function () {
    return this.get('groupsAreWeighted') || this.periodsAreWeighted()
  }.property('weightingScheme'),

  hidePointsPossibleForFinalGrade: function () {
    return !!(this.get('groupsAreWeighted') || this.subtotalByGradingPeriod())
  }.property('weightingScheme', 'selectedGradingPeriod'),

  updateShowTotalAs: function () {
    this.set('showTotalAsPoints', this.get('showTotalAsPoints'))
    return ajax.request({
      dataType: 'json',
      type: 'PUT',
      url: ENV.GRADEBOOK_OPTIONS.setting_update_url,
      data: {
        show_total_grade_as_points: this.get('showTotalAsPoints'),
      },
    })
  }.observes('showTotalAsPoints', 'gradesAreWeighted'),

  studentColumnData: {},

  updateColumnData(columnDatum, columnID) {
    const studentData = this.get('studentColumnData')
    const dataForStudent = studentData[columnDatum.user_id] || Ember.A()

    const columnForStudent = dataForStudent.findBy('column_id', columnID)
    if (columnForStudent) {
      columnForStudent.set('content', columnDatum.content)
    } else {
      dataForStudent.push(
        Ember.Object.create({
          column_id: columnID,
          content: columnDatum.content,
        })
      )
    }
    return (studentData[columnDatum.user_id] = dataForStudent)
  },

  fetchColumnData(col, url) {
    if (!url) {
      url = ENV.GRADEBOOK_OPTIONS.custom_column_data_url.replace(/:id/, col.id)
    }
    return ajax.raw(url, {dataType: 'json'}).then(result => {
      for (const datum of Array.from(result.response)) {
        this.updateColumnData(datum, col.id)
      }
      const meta = parseLinkHeader(result.jqXHR)
      if (meta.next) {
        return this.fetchColumnData(col, meta.next)
      } else {
        return setProperties(col, {
          isLoading: false,
          isLoaded: true,
        })
      }
    })
  },

  dataForStudent: function () {
    const selectedStudent = this.get('selectedStudent')
    if (selectedStudent == null) {
      return
    }
    return this.get('studentColumnData')[selectedStudent.id]
  }.property('selectedStudent', 'custom_columns.@each.isLoaded'),

  loadCustomColumnData: function () {
    if (!this.get('enrollments.isLoaded')) {
      return
    }
    return this.get('custom_columns')
      .filter(col => {
        if (get(col, 'isLoaded') || get(col, 'isLoading')) {
          return false
        }
        set(col, 'isLoading', true)
        return col
      })
      .forEach(col => this.fetchColumnData(col))
  }.observes('enrollments.isLoaded', 'custom_columns.@each'),

  studentsInSelectedSection: function () {
    const students = this.get('students')
    const currentSection = this.get('selectedSection')

    if (!currentSection) {
      return students
    }
    return students.filter(s => s.sections.contains(currentSection.id))
  }.property('students.@each', 'selectedSection'),

  groupById(array) {
    return array.reduce((obj, item) => {
      obj[get(item, 'id')] = item
      return obj
    }, {})
  },

  submissionsLoaded: function () {
    const assignments = this.get('assignmentsFromGroups')
    const assignmentsByID = this.groupById(assignments)
    const studentsByID = this.groupById(this.get('students'))
    const submissions = this.get('submissions') || []
    submissions.forEach(function (submission) {
      const student = studentsByID[submission.user_id]
      if (student) {
        submission.submissions.forEach(function (s) {
          const assignment = assignmentsByID[s.assignment_id]
          set(s, 'hidden', !this.differentiatedAssignmentVisibleToStudent(assignment, s.user_id))
          return this.updateSubmission(s, student)
        }, this)
        // fill in hidden ones
        assignments.forEach(function (a) {
          if (!this.differentiatedAssignmentVisibleToStudent(a, student.id)) {
            const sub = {
              user_id: student.id,
              assignment_id: a.id,
              hidden: true,
            }
            return this.updateSubmission(sub, student)
          }
        }, this)
        setProperties(student, {
          isLoading: false,
          isLoaded: true,
        })
        this.calculateStudentGrade(student)
      }
    }, this)
  }.observes('submissions.@each', 'assignmentsFromGroups.isLoaded'),

  updateSubmission(submission, student) {
    submission.submitted_at = tz.parse(submission.submitted_at)
    return set(student, `assignment_${submission.assignment_id}`, submission)
  },

  updateEffectiveDueDatesOnAssignment(assignment) {
    assignment.effectiveDueDates = this.get('effectiveDueDates.content')[assignment.id] || {}
    return (assignment.inClosedGradingPeriod = some(
      assignment.effectiveDueDates,
      date => date.in_closed_grading_period
    ))
  },

  updateEffectiveDueDatesFromSubmissions(submissions) {
    const effectiveDueDates = this.get('effectiveDueDates.content')
    const gradingPeriods = __guard__(this.getGradingPeriodSet(), x => x.gradingPeriods)
    updateWithSubmissions(effectiveDueDates, submissions, gradingPeriods)
    return this.set('effectiveDueDates.content', effectiveDueDates)
  },

  assignments: Ember.ArrayProxy.createWithMixins(Ember.SortableMixin, {
    content: [],
    sortProperties: ['ag_position', 'position'],
  }),

  processAssignment(as, assignmentGroups) {
    const assignmentGroup = assignmentGroups.findBy('id', as.assignment_group_id)
    set(as, 'sortable_name', as.name.toLowerCase())
    set(as, 'ag_position', assignmentGroup.position)
    set(as, 'noPointsPossibleWarning', assignmentGroup.invalid)

    this.updateEffectiveDueDatesOnAssignment(as)

    if (as.due_at) {
      const due_at = tz.parse(as.due_at)
      set(as, 'due_at', due_at)
      return set(as, 'sortable_date', +due_at / 1000)
    } else {
      return set(as, 'sortable_date', Number.MAX_VALUE)
    }
  },

  differentiatedAssignmentVisibleToStudent(assignment, student_id) {
    if (assignment == null) {
      return false
    }
    if (!assignment.only_visible_to_overrides) {
      return true
    }
    return includes(assignment.assignment_visibility, student_id)
  },

  studentsThatCanSeeAssignment(assignment) {
    const students = this.studentsHash()
    if (!(assignment != null ? assignment.only_visible_to_overrides : undefined)) {
      return students
    }
    return assignment.assignment_visibility.reduce((result, id) => {
      result[id] = students[id]
      return result
    }, {})
  },

  checkForNoPointsWarning(ag) {
    const pointsPossible = reduce(ag.assignments, (sum, a) => sum + (a.points_possible || 0), 0)
    return pointsPossible === 0
  },

  checkForInvalidGroups: function () {
    return this.get('assignment_groups').forEach(ag =>
      set(ag, 'invalid', this.checkForNoPointsWarning(ag))
    )
  }.observes('assignment_groups.@each'),

  invalidAssignmentGroups: function () {
    return this.get('assignment_groups').filterProperty('invalid', true)
  }.property('assignment_groups.@each.invalid'),

  showInvalidGroupWarning: function () {
    return (
      this.get('invalidAssignmentGroups').length > 0 && this.get('weightingScheme') === 'percent'
    )
  }.property('invalidAssignmentGroups', 'weightingScheme'),

  invalidGroupNames: function () {
    return this.get('invalidAssignmentGroups').map(group => group.name)
  }
    .property('invalidAssignmentGroups')
    .readOnly(),

  invalidGroupsWarningPhrases: function () {
    return I18n.t(
      'invalid_group_warning',
      {
        one: 'Note: Score does not include assignments from the group %{list_of_group_names} because it has no points possible.',
        other:
          'Note: Score does not include assignments from the groups %{list_of_group_names} because they have no points possible.',
      },
      {
        count: this.get('invalidGroupNames').length,
        list_of_group_names: this.get('invalidGroupNames').join(' or '),
      }
    )
  }.property('invalidGroupNames'),

  populateAssignmentsFromGroups: function () {
    if (!this.get('assignment_groups.isLoaded') || !!this.get('assignment_groups.isLoading')) {
      return
    }
    const assignmentGroups = this.get('assignment_groups')
    const assignments = flatten(assignmentGroups.mapBy('assignments'))
    const assignmentList = []
    assignments.forEach(as => {
      this.processAssignment(as, assignmentGroups)
      const shouldRemoveAssignment =
        as.published === false ||
        as.submission_types.contains(
          'not_graded' || as.submission_types.contains('attendance' && !this.get('showAttendance'))
        )
      if (shouldRemoveAssignment) {
        return assignmentGroups.findBy('id', as.assignment_group_id).assignments.removeObject(as)
      } else {
        return assignmentList.push(as)
      }
    })
    return this.get('assignmentsFromGroups').setProperties({
      content: assignmentList,
      isLoaded: true,
    })
  }.observes('assignment_groups.isLoaded', 'assignment_groups.isLoading'),

  populateAssignments: function () {
    const assignmentsFromGroups = this.get('assignmentsFromGroups.content')
    const selectedStudent = this.get('selectedStudent')
    const submissionStateMap = this.get('submissionStateMap')

    const proxy = Ember.ArrayProxy.createWithMixins(Ember.SortableMixin, {content: []})

    if (selectedStudent) {
      assignmentsFromGroups.forEach(assignment => {
        const submissionCriteria = {assignment_id: assignment.id, user_id: selectedStudent.id}
        if (
          !__guard__(
            submissionStateMap != null
              ? submissionStateMap.getSubmissionState(submissionCriteria)
              : undefined,
            x => x.hideGrade
          )
        ) {
          return proxy.addObject(assignment)
        }
      })
    } else {
      proxy.addObjects(assignmentsFromGroups)
    }

    proxy.set('sortProperties', this.get('assignments.sortProperties'))
    this.set('assignments', proxy)
  }.observes('assignmentsFromGroups.isLoaded', 'selectedStudent'),

  populateSubmissionStateMap: function () {
    const map = new SubmissionStateMap({
      hasGradingPeriods: !!this.has_grading_periods,
      selectedGradingPeriodID: this.get('selectedGradingPeriod.id') || '0',
      isAdmin: ENV.current_user_is_admin,
    })
    map.setup(this.get('students').toArray(), this.get('assignmentsFromGroups.content').toArray())
    this.set('submissionStateMap', map)
  }.observes(
    'enrollments.isLoaded',
    'assignmentsFromGroups.isLoaded',
    'submissions.content.length'
  ),

  includeUngradedAssignments: function () {
    const localValue = userSettings.contextGet('include_ungraded_assignments') || false
    if (!this.saveViewUngradedAsZeroToServer()) {
      return localValue
    }

    // Prefer the setting we got from the server, but fall back to the value in
    // userSettings if there is no server value
    const savedValue = get(window, 'ENV.GRADEBOOK_OPTIONS.settings.view_ungraded_as_zero')
    return savedValue != null ? savedValue === 'true' : localValue
  }
    .property()
    .volatile(),

  showAttendance: (() => userSettings.contextGet('show_attendance')).property().volatile(),

  updateIncludeUngradedAssignmentsSetting: function () {
    if (this.saveViewUngradedAsZeroToServer()) {
      ajax.request({
        dataType: 'json',
        type: 'put',
        url: `/api/v1/courses/${ENV.GRADEBOOK_OPTIONS.context_id}/gradebook_settings`,
        data: {
          gradebook_settings: {
            view_ungraded_as_zero: this.get('includeUngradedAssignments') ? 'true' : 'false',
          },
        },
      })
    }

    userSettings.contextSet('include_ungraded_assignments', this.get('includeUngradedAssignments'))
  }.observes('includeUngradedAssignments'),

  saveViewUngradedAsZeroToServer() {
    return !!get(window, 'ENV.GRADEBOOK_OPTIONS.save_view_ungraded_as_zero_to_server')
  },

  proxySubmissionsAllowed: function () {
    const hasPermission = get(window, 'ENV.GRADEBOOK_OPTIONS.proxy_submissions_allowed')
    const assignment = this.get('selectedAssignment')
    if (!assignment) {
      return false
    }
    const isFileUploadAssingment = assignment.submission_types?.includes('online_upload')
    return hasPermission && isFileUploadAssingment
  }.property('selectedAssignment'),

  closeProxyUploadModal() {
    this.set('proxyUploadOpen', false)
  },

  renderProxyUploadModal: function () {
    const mountPoint = document.querySelector('[data-component="IndividualProxyUploader"]')
    if (!mountPoint) {
      return
    }
    const assignment = this.get('selectedAssignment')
    if (!assignment) {
      return
    }
    const student = this.get('selectedStudent')
    if (!student) {
      return
    }
    const component = (
      <ApolloProvider client={createClient()}>
        <ProxyUploadModal
          open={this.get('proxyUploadOpen')}
          onClose={this.closeProxyUploadModal.bind(this)}
          assignment={assignment}
          student={student}
          submission={this.get('selectedSubmission')}
          reloadSubmission={sub => this.updateSubmissionValues(sub)}
        />
      </ApolloProvider>
    )

    return ReactDOM.render(component, mountPoint)
  }
    .on('init')
    .observes('selectedAssignment', 'proxyUploadOpen'),

  updateSubmissionValues(sub) {
    const selected = this.get('selectedSubmission')
    const selectedClone = {...selected, ...sub}
    return this.updateSubmissionsFromExternal([selectedClone])
  },

  submissionPreviewText: function () {
    const submission = this.get('selectedSubmission')
    if (!submission) {
      return
    }
    if (!submission.submission_type) {
      return I18n.t('Has not submitted')
    }
    if (submission.proxy_submitter) {
      return I18n.t('Submitted by %{proxy} on %{date}', {
        proxy: submission.proxy_submitter,
        date: $.datetimeString(submission.submitted_at),
      })
    }
    return I18n.t('Submitted on %{date}', {date: $.datetimeString(submission.submitted_at)})
  }.property('selectedSubmission'),

  assignmentGroupsHash() {
    const ags = {}
    if (!this.get('assignment_groups')) {
      return ags
    }
    this.get('assignment_groups').forEach(ag => (ags[ag.id] = ag))
    return ags
  },

  assignmentSortOptions: [
    {
      label: I18n.t('assignment_order_assignment_groups', 'By Assignment Group and Position'),
      value: 'assignment_group',
    },
    {
      label: I18n.t('assignment_order_alpha', 'Alphabetically'),
      value: 'alpha',
    },
    {
      label: I18n.t('assignment_order_due_date', 'By Due Date'),
      value: 'due_date',
    },
  ],

  assignmentSort: function (key, value) {
    const savedSortType = userSettings.contextGet('sort_grade_columns_by')
    const savedSortOption = this.get('assignmentSortOptions').findBy(
      'value',
      savedSortType != null ? savedSortType.sortType : undefined
    )
    if (value) {
      userSettings.contextSet('sort_grade_columns_by', {sortType: value.value})
      return value
    } else if (savedSortOption) {
      return savedSortOption
    } else {
      // default to assignment group, but don't change saved setting
      return this.get('assignmentSortOptions').findBy('value', 'assignment_group')
    }
  }.property(),

  sortAssignments: function () {
    const sort = this.get('assignmentSort')
    if (!sort) {
      return
    }
    const sort_props = (() => {
      switch (sort.value) {
        case 'assignment_group':
        case 'custom':
          return ['ag_position', 'position']
        case 'alpha':
          return ['sortable_name']
        case 'due_date':
          return ['sortable_date', 'sortable_name']
        default:
          return ['ag_position', 'position']
      }
    })()
    return this.get('assignments').set('sortProperties', sort_props)
  }
    .observes('assignmentSort')
    .on('init'),

  updateAssignmentStatusInGradingPeriod: function () {
    const assignment = this.get('selectedAssignment')

    if (!assignment) {
      this.set('assignmentInClosedGradingPeriod', null)
      this.set('disableAssignmentGrading', null)
      return
    }

    this.set('assignmentInClosedGradingPeriod', assignment.inClosedGradingPeriod)

    // Calculate whether the current user is able to grade assignments given their role and the
    // result of the calculations above
    if (ENV.current_user_is_admin) {
      this.set('disableAssignmentGrading', false)
    } else {
      this.set('disableAssignmentGrading', assignment.inClosedGradingPeriod)
    }
  }.observes('selectedAssignment'),

  selectedSubmission: function (key, selectedSubmission) {
    if (arguments.length > 1) {
      this.set('selectedStudent', this.get('students').findBy('id', selectedSubmission.user_id))
      this.set(
        'selectedAssignment',
        this.get('assignments').findBy('id', selectedSubmission.assignment_id)
      )
    } else {
      if (this.get('selectedStudent') == null || this.get('selectedAssignment') == null) {
        return null
      }
      const student = this.get('selectedStudent')
      const assignment = this.get('selectedAssignment')
      const sub = get(student, `assignment_${assignment.id}`)
      selectedSubmission = sub || {
        user_id: student.id,
        assignment_id: assignment.id,
        hidden: !this.differentiatedAssignmentVisibleToStudent(assignment, student.id),
        grade_matches_current_submission: true,
      }
    }
    const submissionState =
      (this.submissionStateMap != null
        ? this.submissionStateMap.getSubmissionState(selectedSubmission)
        : undefined) || {}
    selectedSubmission.gradeLocked = submissionState.locked
    selectedSubmission[selectedSubmission.late_policy_status] = true
    return selectedSubmission
  }.property('selectedStudent', 'selectedAssignment'),

  gradeForStudentAndAssignment: function () {
    const student = this.get('selectedStudent')
    const assignment = this.get('selectedAssignment')
    return I18n.t('Grade for %{student} - %{assignment}', {
      student: student.name,
      assignment: assignment.name,
    })
  }.property('selectedStudent', 'selectedAssignment'),

  selectedSubmissionHidden: function () {
    return this.get('selectedSubmission.hidden') || false
  }.property('selectedStudent', 'selectedAssignment'),

  anonymizeStudents: function () {
    return this.get('selectedAssignment.anonymize_students')
  }.property('selectedAssignment'),

  selectedSubmissionLate: function () {
    return (this.get('selectedSubmission.points_deducted') || 0) > 0
  }.property('selectedStudent', 'selectedAssignment'),

  selectedOutcomeResult: function () {
    if (this.get('selectedStudent') == null || this.get('selectedOutcome') == null) {
      return null
    }
    const student = this.get('selectedStudent')
    const outcome = this.get('selectedOutcome')
    const result = this.get('outcome_rollups').find(
      x => x.user_id === student.id && x.outcome_id === outcome.id
    )
    if (result) {
      result.mastery_points = round(outcome.mastery_points, 2)
    }
    return (
      result || {
        user_id: student.id,
        outcome_id: outcome.id,
      }
    )
  }.property('selectedStudent', 'selectedOutcome'),

  outcomeResultIsDefined: function () {
    return __guard__(this.get('selectedOutcomeResult'), x => x.score) != null
  }.property('selectedOutcomeResult'),

  showAssignmentPointsWarning: function () {
    return this.get('selectedAssignment.noPointsPossibleWarning') && this.get('groupsAreWeighted')
  }.property('selectedAssignment', 'groupsAreWeighted'),

  selectedStudentSections: function () {
    const student = this.get('selectedStudent')
    const sections = this.get('sections')
    if (!sections.isLoaded || student == null) {
      return null
    }
    const sectionNames = student.sections.map(id => sections.findBy('id', id).name)
    return sectionNames.join(', ')
  }.property('selectedStudent', 'sections.isLoaded'),

  assignmentDetails: function () {
    if (this.get('selectedAssignment') == null) {
      return null
    }
    const {locals} = AssignmentDetailsDialog.prototype.compute.call(
      AssignmentDetailsDialog.prototype,
      {
        students: this.studentsHash(),
        assignment: this.get('selectedAssignment'),
      }
    )
    return locals
  }.property('selectedAssignment', 'students.@each.total_grade'),

  outcomeDetails: function () {
    if (this.get('selectedOutcome') == null) {
      return null
    }
    const rollups = this.get('outcome_rollups').filterBy(
      'outcome_id',
      this.get('selectedOutcome').id
    )
    const scores = filter(map(rollups, 'score'), isNumber)
    return {
      average: outcomeGrid.Math.mean(scores),
      max: outcomeGrid.Math.max(scores),
      min: outcomeGrid.Math.min(scores),
      cnt: outcomeGrid.Math.cnt(scores),
    }
  }.property('selectedOutcome', 'outcome_rollups'),

  calculationDetails: function () {
    if (this.get('selectedOutcome') == null) {
      return null
    }
    const outcome = this.get('selectedOutcome')
    return extend(
      {
        calculation_method: outcome.calculation_method,
        calculation_int: outcome.calculation_int,
      },
      new CalculationMethodContent(outcome).present()
    )
  }.property('selectedOutcome'),

  assignmentSubmissionTypes: function () {
    const types = this.get('selectedAssignment.submission_types')
    const submissionTypes = this.get('submissionTypes')
    if (types === undefined || types.length === 0) {
      return submissionTypes.none
    } else if (types.length === 1) {
      return submissionTypes[types[0]]
    } else {
      const result = []
      types.forEach(type => result.push(submissionTypes[type]))
      return result.join(', ')
    }
  }.property('selectedAssignment'),

  submissionTypes: {
    discussion_topic: I18n.t('Discussion topic'),
    online_quiz: I18n.t('Online quiz'),
    on_paper: I18n.t('On paper'),
    none: I18n.t('None'),
    external_tool: I18n.t('External tool'),
    online_text_entry: I18n.t('Online text entry'),
    online_url: I18n.t('Online URL'),
    online_upload: I18n.t('Online upload'),
    media_recording: I18n.t('Media recording'),
  },

  assignmentIndex: function () {
    const selected = this.get('selectedAssignment')
    if (selected) {
      return this.get('assignments').indexOf(selected)
    } else {
      return -1
    }
  }.property('selectedAssignment', 'assignmentSort'),

  studentIndex: function () {
    const selected = this.get('selectedStudent')
    if (selected) {
      return this.get('studentsInSelectedSection').indexOf(selected)
    } else {
      return -1
    }
  }.property('selectedStudent', 'selectedSection'),

  outcomeIndex: function () {
    const selected = this.get('selectedOutcome')
    if (selected) {
      return this.get('outcomes').indexOf(selected)
    } else {
      return -1
    }
  }.property('selectedOutcome'),

  displayName: function () {
    if (this.get('hideStudentNames')) {
      return 'hiddenName'
    } else {
      return 'sortable_name'
    }
  }.property('hideStudentNames'),

  fetchCorrectEnrollments: function () {
    let url
    if (this.get('enrollments.isLoading')) {
      return
    }
    if (this.get('showConcludedEnrollments')) {
      url = ENV.GRADEBOOK_OPTIONS.enrollments_with_concluded_url
    } else {
      url = ENV.GRADEBOOK_OPTIONS.enrollments_url
    }

    const enrollments = this.get('enrollments')
    enrollments.clear()
    return fetchAllPages(url, {records: enrollments})
  }.observes('showConcludedEnrollments'),

  omitFromFinalGrade: function () {
    return this.get('selectedAssignment.omit_from_final_grade')
  }.property('selectedAssignment'),
})

export default ScreenreaderGradebookController

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
