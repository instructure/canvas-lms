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

export const scoreToLetterGrade = (score, gradingStandard) => {
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
  return scoreToLetterGrade(getAssignmentPercentage(assignment), gradingStandard)
}

// **************** ASSIGNMENT GROUPS **********************************************

export const getAssignmentGroupTotalPoints = (assignmentGroup, assignments) => {
  return assignments.reduce((total, assignment) => {
    if (
      !(
        assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused' ||
        assignment?.assignmentGroup?._id !== assignmentGroup?._id
      ) &&
      assignment?.submissionsConnection?.nodes.length > 0
    ) {
      total += getAssignmentTotalPoints(assignment)
    }
    return total
  }, 0)
}

export const getAssignmentGroupEarnedPoints = (assignmentGroup, assignments) => {
  return assignments.reduce((total, assignment) => {
    if (
      !(
        assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused' ||
        assignment?.assignmentGroup?._id !== assignmentGroup?._id
      ) &&
      assignment?.submissionsConnection?.nodes.length > 0
    ) {
      total += getAssignmentEarnedPoints(assignment)
    }
    return total
  }, 0)
}

export const getAssignmentGroupPercentage = (assignmentGroup, assignments, applyGroupWeights) => {
  if (applyGroupWeights) {
    if (!getAssignmentGroupTotalPoints(assignmentGroup, assignments)) return 0
    return (
      (getAssignmentGroupEarnedPoints(assignmentGroup, assignments) /
        getAssignmentGroupTotalPoints(assignmentGroup, assignments)) *
      assignmentGroup?.groupWeight
    )
  }
  return (
    (getAssignmentGroupEarnedPoints(assignmentGroup, assignments) /
      getAssignmentGroupTotalPoints(assignmentGroup, assignments)) *
    100
  )
}

export const getAssignmentGroupLetterGrade = (assignmentGroup, assignments, gradingStandard) => {
  return scoreToLetterGrade(
    getAssignmentGroupPercentage(assignmentGroup, assignments),
    gradingStandard
  )
}

export const getAssignmentGroupWeighted = (assignmentGroups, assignments) => {
  return assignmentGroups.reduce((total, assignmentGroup) => {
    if (!getAssignmentGroupTotalPoints(assignmentGroup, assignments)) return total
    return (
      total +
      (getAssignmentGroupEarnedPoints(assignmentGroup, assignments) /
        getAssignmentGroupTotalPoints(assignmentGroup, assignments)) *
        assignmentGroup?.groupWeight
    )
  }, 0)
}

// **************** GRADING PERIODS ***********************************************

export const getGradingPeriodTotalPoints = (gradingPeriod, assignments) => {
  return assignments.reduce((total, assignment) => {
    if (
      assignment?.submissionsConnection?.nodes[0]?.gradingPeriodId === gradingPeriod?._id &&
      !(assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused')
    ) {
      total += getAssignmentTotalPoints(assignment) || 0
    }
    return total
  }, 0)
}

export const getGradingPeriodEarnedPoints = (gradingPeriod, assignments) => {
  return assignments.reduce((total, assignment) => {
    if (
      assignment?.submissionsConnection?.nodes[0]?.gradingPeriodId === gradingPeriod?._id &&
      !(assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused')
    ) {
      total += getAssignmentEarnedPoints(assignment) || 0
    }
    return total
  }, 0)
}

export const getGradingPeriodPercentage = (gradingPeriod, assignments) => {
  return (
    (getGradingPeriodEarnedPoints(gradingPeriod, assignments) /
      getGradingPeriodTotalPoints(gradingPeriod, assignments)) *
    100
  )
}

export const getGradingPeriodLetterGrade = (gradingPeriod, assignments, gradingStandard) => {
  return scoreToLetterGrade(getGradingPeriodPercentage(gradingPeriod, assignments), gradingStandard)
}

export const getGradingPeriodTotalWeighted = (gradingPeriods, assignments, assignmentGroups) => {
  return gradingPeriods.reduce((total, _gradingPeriod) => {
    return total + getAssignmentGroupWeighted(assignmentGroups, assignments)
  }, 0)
}

// **************** COURSES *******************************************************

export const getCourseTotalPoints = assignments => {
  return assignments.reduce((total, assignment) => {
    if (
      !(assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused') &&
      assignment?.submissionsConnection?.nodes.length > 0
    ) {
      total += getAssignmentTotalPoints(assignment)
    }
    return total
  }, 0)
}

export const getCourseEarnedPoints = assignments => {
  return assignments.reduce((total, assignment) => {
    if (
      !(assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused') &&
      assignment?.submissionsConnection?.nodes.length > 0
    ) {
      total += getAssignmentEarnedPoints(assignment)
    }
    return total
  }, 0)
}

export const getCoursePercentage = assignments => {
  return (getCourseEarnedPoints(assignments) / getCourseTotalPoints(assignments)) * 100
}

export const getCourseLetterGrade = (course, assignments, gradingStandard) => {
  return scoreToLetterGrade(getCoursePercentage(course, assignments), gradingStandard)
}

// **************** TOTAL *********************************************************

export const getTotal = (assignments, assignmentGroups, gradingPeriods, applyWeights) => {
  let returnTotal = 0
  if (getGradingPeriodID() === '0' && applyWeights) {
    returnTotal = gradingPeriods.reduce((total, period) => {
      return (
        total +
        getGradingPeriodTotalWeighted(
          [period],
          assignments.filter(assignment => {
            return assignment?.submissionsConnection?.nodes[0]?.gradingPeriodId === period?._id
          }),
          assignmentGroups
        ) *
          (period?.weight / 100)
      )
    }, 0)
  } else if (getGradingPeriodID() === '0') {
    returnTotal = gradingPeriods.reduce((total, gradingPeriod) => {
      if (!getGradingPeriodTotalPoints(gradingPeriod, assignments)) return total
      return (
        total +
        (getGradingPeriodEarnedPoints(gradingPeriod, assignments) /
          getGradingPeriodTotalPoints(gradingPeriod, assignments)) *
          gradingPeriod?.weight
      )
    }, 0)
  } else if (applyWeights) {
    returnTotal = getAssignmentGroupWeighted(assignmentGroups, assignments)
  } else {
    returnTotal = getCoursePercentage(assignments)
  }
  return returnTotal
}

// ********************************************************************************
