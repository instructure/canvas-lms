/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import {ASSIGNMENT_SORT_OPTIONS} from './constants'
import {IconCheckLine, IconXLine} from '@instructure/ui-icons'
import {Pill} from '@instructure/ui-pill'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('grade_summary')

export const getGradingPeriodID = () => {
  return window?.location?.search
    ?.split('?')[1]
    ?.split('&')
    ?.filter(param => param.includes('grading_period_id'))[0]
    ?.split('=')[1]
}

export const filteredAssignments = data => {
  return (
    data?.assignmentsConnection?.nodes.filter(assignment => {
      return !assignment?.submissionsConnection?.nodes[0]?.hideGradeFromStudent
    }) || []
  )
}

export const sortAssignments = (sortBy, assignments) => {
  if (sortBy === ASSIGNMENT_SORT_OPTIONS.NAME) {
    assignments = [...assignments]?.sort((a, b) => a?.name?.localeCompare(b?.name))
  } else if (sortBy === ASSIGNMENT_SORT_OPTIONS.DUE_DATE) {
    const assignmentsWithDueDates = assignments
      ?.filter(a => a?.dueAt)
      ?.sort((a, b) => a?.dueAt?.localeCompare(b?.dueAt))
    const assignmentsWithoutDueDates = assignments?.filter(a => !a?.dueAt)
    assignments = [...assignmentsWithDueDates, ...assignmentsWithoutDueDates]
  } else if (sortBy === ASSIGNMENT_SORT_OPTIONS.ASSIGNMENT_GROUP) {
    assignments = [...assignments]?.sort((a, b) =>
      a?.assignmentGroup?.name?.localeCompare(b?.assignmentGroup?.name)
    )
  }
  return assignments
}

export const getAssignmentGroupScore = assignmentGroup => {
  if (assignmentGroup?.gradesConnection.nodes[0].overrideScore)
    return `${assignmentGroup?.gradesConnection.nodes[0].overrideScore}%`
  else if (assignmentGroup?.gradesConnection.nodes[0].currentScore)
    return `${assignmentGroup?.gradesConnection.nodes[0].currentScore}%`
  else return I18n.t('N/A')
}

export const formatNumber = number => {
  return number?.toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })
}

export const submissionCommentsPresent = assignment => {
  return (
    assignment?.submissionsConnection.nodes.filter(submission => {
      return submission?.commentsConnection?.nodes?.length > 0
    }).length > 0
  )
}

export const getDisplayStatus = assignment => {
  if (assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused') {
    return <Pill>{I18n.t('Excused')}</Pill>
  } else if (assignment?.gradingType === 'not_graded') {
    return <Pill>{I18n.t('Not Graded')}</Pill>
  } else if (assignment?.submissionsConnection?.nodes?.length === 0) {
    return getNoSubmissionStatus(assignment?.dueAt)
  } else if (assignment?.submissionsConnection?.nodes[0]?.late) {
    return <Pill color="warning">{I18n.t('Late')}</Pill>
  } else if (assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'graded') {
    return <Pill color="success">{I18n.t('Graded')}</Pill>
  } else {
    return <Pill>{I18n.t('Not Graded')}</Pill>
  }
}

export const getNoSubmissionStatus = dueDate => {
  const assignmentDueDate = new Date(dueDate)
  const currentDate = new Date()
  if (dueDate && assignmentDueDate < currentDate) {
    return <Pill color="danger">{I18n.t('Missing')}</Pill>
  } else {
    return <Pill>{I18n.t('Not Submitted')}</Pill>
  }
}

export const getDisplayScore = (assignment, gradingStandard) => {
  if (
    assignment?.submissionsConnection?.nodes?.length === 0 ||
    assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'needs_grading' ||
    assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused'
  ) {
    return '-'
  } else if (
    ENV.restrict_quantitative_data &&
    (assignment?.gradingType === 'gpa_scale' ||
      assignment?.gradingType === 'percent' ||
      assignment?.gradingType === 'points')
  ) {
    return getAssignmentLetterGrade(assignment, gradingStandard)
  } else if (
    assignment?.gradingType === 'letter_grade' ||
    assignment?.gradingType === 'gpa_scale'
  ) {
    return getAssignmentLetterGrade(assignment, gradingStandard)
  } else if (assignment?.gradingType === 'percentage') {
    return `${getAssignmentPercentage(assignment)}%`
  } else if (assignment?.gradingType === 'pass_fail') {
    return assignment?.submissionsConnection?.nodes[0]?.score ? <IconCheckLine /> : <IconXLine />
  } else {
    const earned = getAssignmentEarnedPoints(assignment)
    const total = getAssignmentTotalPoints(assignment)
    return `${earned || '-'}/${total || '-'}`
  }
}

export const scorePercentageToLetterGrade = (score, gradingStandard) => {
  if (score === null || score === undefined) return null
  if (!Number.isFinite(score)) return null

  let letter = null
  gradingStandard?.data?.forEach(gradeLevel => {
    if (score / 100 >= gradeLevel.baseValue && !letter) {
      letter = gradeLevel.letterGrade
    }
  })
  return letter
}

// **************** ASSIGNMENTS ***************************************************

export const getAssignmentTotalPoints = assignment => {
  return assignment?.pointsPossible || 0
}

export const getAssignmentEarnedPoints = assignment => {
  return parseFloat(assignment?.submissionsConnection?.nodes[0]?.score) || 0
}

export const getAssignmentPercentage = assignment => {
  if (!getAssignmentTotalPoints(assignment)) return 0
  return (getAssignmentEarnedPoints(assignment) / getAssignmentTotalPoints(assignment) || 1) * 100
}

export const getAssignmentLetterGrade = (assignment, gradingStandard) => {
  if (
    assignment?.submissionsConnection?.nodes === undefined ||
    assignment?.submissionsConnection?.nodes.length === 0
  )
    return null

  return scorePercentageToLetterGrade(getAssignmentPercentage(assignment), gradingStandard)
}

// **************** ASSIGNMENT GROUPS **********************************************

export const getAssignmentGroupTotalPoints = (assignmentGroup, assignments) => {
  return assignments?.reduce((total, assignment) => {
    if (
      assignment?.submissionsConnection?.nodes.length > 0 &&
      assignment?.submissionsConnection?.nodes[0]?.gradingStatus !== 'excused' &&
      assignment?.submissionsConnection?.nodes[0]?.gradingStatus !== 'needs_grading' &&
      assignment?.assignmentGroup?._id === assignmentGroup?._id
    ) {
      total += getAssignmentTotalPoints(assignment)
    }
    return total
  }, 0)
}

export const getAssignmentGroupEarnedPoints = (assignmentGroup, assignments) => {
  return assignments?.reduce((total, assignment) => {
    if (
      assignment?.submissionsConnection?.nodes.length > 0 &&
      assignment?.submissionsConnection?.nodes[0]?.gradingStatus !== 'excused' &&
      assignment?.submissionsConnection?.nodes[0]?.gradingStatus !== 'needs_grading' &&
      assignment?.assignmentGroup?._id === assignmentGroup?._id
    ) {
      total += getAssignmentEarnedPoints(assignment)
    }
    return total
  }, 0)
}

export const getAssignmentGroupPercentage = (assignmentGroup, assignments, applyGroupWeights) => {
  if (!getAssignmentGroupTotalPoints(assignmentGroup, assignments)) return 0
  if (applyGroupWeights) {
    return (
      (((getAssignmentGroupEarnedPoints(assignmentGroup, assignments) /
        getAssignmentGroupTotalPoints(assignmentGroup, assignments)) *
        assignmentGroup?.groupWeight) /
        100) *
      100
    )
  }

  return (
    (getAssignmentGroupEarnedPoints(assignmentGroup, assignments) /
      getAssignmentGroupTotalPoints(assignmentGroup, assignments)) *
    100
  )
}

export const getAssignmentGroupLetterGrade = (assignmentGroup, assignments, gradingStandard) => {
  return assignments?.length !== 0
    ? scorePercentageToLetterGrade(
        getAssignmentGroupPercentage(assignmentGroup, assignments, false),
        gradingStandard
      )
    : 'N/A'
}

// **************** GRADING PERIODS ***********************************************

export const getGradingPeriodTotalPoints = (gradingPeriod, assignments) => {
  return (
    assignments?.reduce((total, assignment) => {
      if (
        assignment?.submissionsConnection?.nodes[0]?.gradingPeriodId === gradingPeriod?._id &&
        !(assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused')
      ) {
        total += getAssignmentTotalPoints(assignment) || 0
      }
      return total
    }, 0) || 0
  )
}

export const getGradingPeriodEarnedPoints = (gradingPeriod, assignments) => {
  return (
    assignments?.reduce((total, assignment) => {
      if (
        assignment?.submissionsConnection?.nodes[0]?.gradingPeriodId === gradingPeriod?._id &&
        !(assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused')
      ) {
        total += getAssignmentEarnedPoints(assignment) || 0
      }
      return total
    }, 0) || 0
  )
}

export const getGradingPeriodPercentage = (
  gradingPeriod,
  assignments,
  assignmentGroups,
  applyGroupWeights
) => {
  return applyGroupWeights
    ? assignmentGroups?.reduce((groupTotal, assignmentGroup) => {
        return (
          groupTotal + getAssignmentGroupPercentage(assignmentGroup, assignments, applyGroupWeights)
        )
      }, 0) || 0
    : (getGradingPeriodEarnedPoints(gradingPeriod, assignments) /
        getGradingPeriodTotalPoints(gradingPeriod, assignments)) *
        100 || 0
}

// **************** COURSES *******************************************************

export const getCourseTotalPoints = assignments => {
  return (
    assignments?.reduce((total, assignment) => {
      if (
        !(assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused') &&
        assignment?.submissionsConnection?.nodes.length > 0
      ) {
        total += getAssignmentTotalPoints(assignment)
      }
      return total
    }, 0) || 0
  )
}

export const getCourseEarnedPoints = (assignments = []) => {
  return (
    assignments?.reduce((total, assignment) => {
      if (
        !(assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused') &&
        assignment?.submissionsConnection?.nodes.length > 0
      ) {
        total += getAssignmentEarnedPoints(assignment)
      }
      return total
    }, 0) || 0
  )
}

export const getCoursePercentage = (assignments = []) => {
  if (!getCourseTotalPoints(assignments)) return 0
  return (getCourseEarnedPoints(assignments) / getCourseTotalPoints(assignments)) * 100
}

// **************** TOTAL *********************************************************

export const getTotal = (assignments, assignmentGroups, gradingPeriods, applyWeights) => {
  let returnTotal = 0
  if (getGradingPeriodID() === '0' && applyWeights) {
    returnTotal =
      gradingPeriods?.reduce((total, period) => {
        return (
          total +
          getGradingPeriodPercentage(
            period,
            assignments?.filter(assignment => {
              return assignment?.submissionsConnection?.nodes[0]?.gradingPeriodId === period?._id
            }),
            assignmentGroups,
            applyWeights
          ) *
            (period?.weight / 100)
        )
      }, 0) || 0
  } else if (getGradingPeriodID() === '0') {
    returnTotal =
      gradingPeriods?.reduce((total, gradingPeriod) => {
        if (!getGradingPeriodTotalPoints(gradingPeriod, assignments)) return total
        return (
          total +
          (getGradingPeriodEarnedPoints(gradingPeriod, assignments) /
            getGradingPeriodTotalPoints(gradingPeriod, assignments)) *
            gradingPeriod?.weight
        )
      }, 0) || 0
  } else if (applyWeights) {
    returnTotal =
      assignmentGroups?.reduce((total, assignmentGroup) => {
        return total + getAssignmentGroupPercentage(assignmentGroup, assignments, applyWeights)
      }, 0) || 0
  } else {
    returnTotal = getCoursePercentage(assignments)
  }
  return returnTotal
}

// ********************************************************************************
