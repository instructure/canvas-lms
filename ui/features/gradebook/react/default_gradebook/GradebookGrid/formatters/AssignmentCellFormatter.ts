/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// xsslint safeString.method I18n.t

import {useScope as useI18nScope} from '@canvas/i18n'
import htmlEscape from '@instructure/html-escape'
import {extractDataTurnitin} from '@canvas/grading/Turnitin'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {extractSimilarityInfo, isPostable, similarityIcon} from '@canvas/grading/SubmissionHelper'
import {classNamesForAssignmentCell} from './CellStyles'
import type Gradebook from '../../Gradebook'
import type {PendingGradeInfo} from '../../gradebook.d'
import type {SubmissionData, SubmissionWithOriginalityReport} from '@canvas/grading/grading.d'
import type {GradingStandard} from '@instructure/grading-utils'
import type {Assignment, Student, Submission} from '../../../../../../api.d'

const I18n = useI18nScope('gradebook')

type Options = {
  classNames?: string[]
  dimmed?: boolean
  disabled?: boolean
  hidden?: boolean
  invalid?: boolean
  showUnpostedIndicator?: boolean
  turnitinState?: ReturnType<typeof getTurnitinState>
  similarityData?: ReturnType<typeof extractSimilarityInfo>
}

type Getters = {
  getAssignment(assignmentId: string): ReturnType<Gradebook['getAssignment']>
  getEnterGradesAsSetting(assignmentId: string): ReturnType<Gradebook['getEnterGradesAsSetting']>
  getGradingSchemeData(assignmentId: string): undefined | GradingStandard[]
  getPendingGradeInfo(submission: {
    assignmentId: string
    userId: string
  }): ReturnType<Gradebook['getPendingGradeInfo']>
  getStudent(studentId: string): ReturnType<Gradebook['student']>
  getSubmissionState(
    submission: Submission
  ): ReturnType<Gradebook['submissionStateMap']['getSubmissionState']>
  showUpdatedSimilarityScore(): boolean
}

function getTurnitinState(submission: SubmissionWithOriginalityReport) {
  const turnitin = extractDataTurnitin(submission)
  if (turnitin) {
    return htmlEscape(turnitin.state)
  }
  return null
}

function needsGrading(submission: Submission, pendingGradeInfo: PendingGradeInfo | null) {
  if (pendingGradeInfo && pendingGradeInfo.grade != null) {
    return false
  }

  if (submission.excused || !submission.submission_type) {
    return false
  }

  return (
    submission.workflow_state === 'pending_review' ||
    // the submission exists and/or has been graded
    (['submitted', 'graded'].includes(submission.workflow_state) &&
      // the score has been cleared, or the submission has been resubmitted
      (submission.score == null || submission.grade_matches_current_submission === false))
  )
}

function formatGrade(submissionData: SubmissionData, assignment: Assignment, options: Getters) {
  const formatOptions = {
    formatType: options.getEnterGradesAsSetting(assignment.id),
    gradingScheme: options.getGradingSchemeData(assignment.id),
    pointsPossible: assignment.points_possible,
    version: 'final',
  }

  return GradeFormatHelper.formatSubmissionGrade(submissionData, formatOptions)
}

function renderStartContainer(options: {
  showUnpostedIndicator?: boolean
  invalid?: boolean
  similarityData?: ReturnType<typeof extractSimilarityInfo>
}) {
  let content = ''

  if (options.showUnpostedIndicator) {
    content += '<div class="Grid__GradeCell__UnpostedGrade"></div>'
  }

  if (options.invalid) {
    content += '<div class="Grid__GradeCell__InvalidGrade"><i class="icon-warning"></i></div>'
  } else if (options.similarityData != null) {
    // xsslint safeString.function renderSimilarityIcon
    const similarityIconHtml = similarityIcon(options.similarityData.entries[0].data)
    content += `<div class="Grid__GradeCell__OriginalityScore">${similarityIconHtml}</div>`
  }

  // xsslint safeString.identifier content
  return `<div class="Grid__GradeCell__StartContainer">${content}</div>`
}

function renderTemplate(grade: string, options: Options = {}) {
  let classNames = ['Grid__GradeCell', 'gradebook-cell']
  let content: string = grade

  if (options.classNames) {
    classNames = [...classNames, ...options.classNames]
  }

  if (options.dimmed) {
    classNames.push('grayed-out')
  }

  if (options.disabled) {
    classNames.push('cannot_edit')
  }

  // This is the "old" turnitin visualization (the grade-like indicator with
  // plagiarism levels indicated by different colors); the updated version is
  // rendered in renderStartContainer if the feature flag is set
  if (options.turnitinState) {
    classNames.push('turnitin')
    // xsslint safeString.property turnitinState
    content += `<span class="gradebook-cell-turnitin ${options.turnitinState}-score" />`
  }

  // xsslint safeString.identifier content
  // xsslint safeString.function renderStartContainer
  return `<div class="${htmlEscape(classNames.join(' '))}">
    ${renderStartContainer(options)}
    <div class="Grid__GradeCell__Content">
      <span class="Grade">${content}</span>
    </div>
    <div class="Grid__GradeCell__EndContainer"></div>
  </div>`
}

export default class AssignmentCellFormatter {
  options: Getters

  customGradeStatusesEnabled: boolean

  constructor(gradebook: Gradebook) {
    this.options = {
      getAssignment(assignmentId: string) {
        return gradebook.getAssignment(assignmentId)
      },
      getEnterGradesAsSetting(assignmentId: string) {
        return gradebook.getEnterGradesAsSetting(assignmentId)
      },
      getGradingSchemeData(assignmentId: string): undefined | GradingStandard[] {
        return gradebook.getAssignmentGradingScheme(assignmentId)?.data
      },
      getPendingGradeInfo(submission: {assignmentId: string; userId: string}) {
        return gradebook.getPendingGradeInfo(submission)
      },
      getStudent(studentId: string) {
        return gradebook.student(studentId)
      },
      getSubmissionState(submission: Submission) {
        return gradebook.submissionStateMap.getSubmissionState(submission)
      },
      showUpdatedSimilarityScore() {
        return gradebook.options.show_similarity_score
      },
    }
    this.customGradeStatusesEnabled = gradebook.options.custom_grade_statuses_enabled
  }

  render = (
    _row: number,
    _cell: number,
    submission: SubmissionWithOriginalityReport,
    columnDef: {
      postAssignmentGradesTrayOpenForAssignmentId?: string
    },
    student: Student
  ) => {
    let submissionState
    if (submission) {
      submissionState = this.options.getSubmissionState(submission)
    }

    if (!student.loaded || !student.initialized || !submissionState) {
      return renderTemplate('')
    }

    if (submissionState.hideGrade) {
      return renderTemplate('', {dimmed: true})
    }

    const assignment = this.options.getAssignment(submission.assignment_id)

    const assignmentData = {
      id: assignment.id,
      pointsPossible: assignment.points_possible,
      submissionTypes: assignment.submission_types,
    }

    const submissionData: SubmissionData = {
      dropped: submission.drop,
      excused: submission.excused,
      extended: submission.late_policy_status === 'extended',
      grade: assignment.grading_type === 'pass_fail' ? submission.rawGrade : submission.grade,
      late: submission.late,
      missing: submission.missing,
      resubmitted: submission.grade_matches_current_submission === false,
      score: submission.score,
      customGradeStatusId: this.customGradeStatusesEnabled
        ? submission.custom_grade_status_id
        : null,
    }

    const pendingGradeInfo = this.options.getPendingGradeInfo({
      assignmentId: assignment.id,
      userId: student.id,
    })
    if (pendingGradeInfo) {
      submissionData.grade = pendingGradeInfo.grade
      submissionData.excused = pendingGradeInfo.excused
    }

    const showUnpostedIndicator =
      columnDef.postAssignmentGradesTrayOpenForAssignmentId && isPostable(submission)

    const options: Options = {
      classNames: classNamesForAssignmentCell(assignmentData, submissionData),
      dimmed: student.isInactive || student.isConcluded || submissionState.locked,
      disabled: student.isConcluded || submissionState.locked,
      hidden: submissionState.hideGrade,
      invalid: !!pendingGradeInfo && !pendingGradeInfo.valid,
      showUnpostedIndicator,
    }

    if (this.options.showUpdatedSimilarityScore()) {
      options.similarityData = extractSimilarityInfo(submission)
    } else {
      options.turnitinState = getTurnitinState(submission)
    }

    if (needsGrading(submission, pendingGradeInfo)) {
      const text = `<span class="screenreader-only">${I18n.t('Needs Grading')}</span>`
      const icon = '<i class="icon-not-graded icon-Line"></i>'
      return renderTemplate(`${text}${icon}`, options)
    }

    if (assignment.grading_type === 'pass_fail') {
      if (submissionData.grade === 'complete') {
        const text = `<span class="screenreader-only">${I18n.t('Complete')}</span>`
        const icon = '<i class="icon-check icon-Solid Grade--complete"></i>'
        return renderTemplate(`${text}${icon}`, options)
      }

      if (submissionData.grade === 'incomplete') {
        const text = `<span class="screenreader-only">${I18n.t('Incomplete')}</span>`
        const icon = '<i class="icon-x icon-Solid Grade--incomplete"></i>'
        return renderTemplate(`${text}${icon}`, options)
      }
    }

    let grade
    if (pendingGradeInfo) {
      grade = GradeFormatHelper.formatGradeInfo(pendingGradeInfo)
    } else {
      grade = formatGrade(submissionData, assignment, this.options)
    }

    return renderTemplate(htmlEscape(grade), options)
  }
}
