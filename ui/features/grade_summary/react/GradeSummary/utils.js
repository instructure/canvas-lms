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
import {ASSIGNMENT_SORT_OPTIONS, ASSIGNMENT_NOT_APPLICABLE, ASSIGNMENT_STATUS} from './constants'
import {IconCheckLine, IconXLine} from '@instructure/ui-icons'
import {Pill} from '@instructure/ui-pill'

import gradingHelpers from '@canvas/grading/AssignmentGroupGradeCalculator'

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

export const getAssignmentPositionInModuleItems = (assignmentId, moduleItems) => {
  return (
    moduleItems?.findIndex(moduleItem => {
      return moduleItem?.content?._id === assignmentId
    }) + 1
  )
}

export const getAssignmentSortKey = assignment => {
  const assignmentId = assignment?._id
  const firstModule = assignment?.modules[0]

  return (
    firstModule?.position * 100000 +
    getAssignmentPositionInModuleItems(assignmentId, firstModule?.moduleItems)
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
  } else if (sortBy === ASSIGNMENT_SORT_OPTIONS.MODULE) {
    const assignmentsWithModules = assignments
      ?.filter(a => a?.modules?.length > 0)
      ?.sort((a, b) => getAssignmentSortKey(a) - getAssignmentSortKey(b))
    const assignmentsWithoutModules = assignments?.filter(a => a?.modules?.length === 0)

    assignments = [...assignmentsWithModules, ...assignmentsWithoutModules]
  }
  return assignments
}

export const getAssignmentGroupScore = assignmentGroup => {
  if (assignmentGroup?.gradesConnection.nodes[0].overrideScore)
    return `${assignmentGroup?.gradesConnection.nodes[0].overrideScore}%`
  else if (assignmentGroup?.gradesConnection.nodes[0].currentScore)
    return `${assignmentGroup?.gradesConnection.nodes[0].currentScore}%`
  else return ASSIGNMENT_NOT_APPLICABLE
}

export const formatNumber = number => {
  if (typeof number === 'string') {
    number = parseFloat(number)
  }

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

export const getAssignmentStatus = assignment => {
  if (assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'excused') {
    return ASSIGNMENT_STATUS.EXCUSED
  } else if (assignment?.dropped) {
    return ASSIGNMENT_STATUS.DROPPED
  } else if (assignment?.gradingType === 'not_graded') {
    return ASSIGNMENT_STATUS.NOT_GRADED
  } else if (assignment?.submissionsConnection?.nodes?.length === 0) {
    return getAssignmentNoSubmissionStatus(assignment?.dueAt)
  } else if (assignment?.submissionsConnection?.nodes[0]?.late) {
    return ASSIGNMENT_STATUS.LATE
  } else if (assignment?.submissionsConnection?.nodes[0]?.gradingStatus === 'graded') {
    return ASSIGNMENT_STATUS.GRADED
  } else {
    return ASSIGNMENT_STATUS.NOT_GRADED
  }
}

export const getAssignmentNoSubmissionStatus = dueDate => {
  const assignmentDueDate = new Date(dueDate)
  const currentDate = new Date()
  if (dueDate && assignmentDueDate < currentDate) {
    return ASSIGNMENT_STATUS.MISSING
  } else {
    return ASSIGNMENT_STATUS.NOT_SUBMITTED
  }
}

export const getDisplayStatus = assignment => {
  const status = getAssignmentStatus(assignment)
  return <Pill color={status.color}>{status.label}</Pill>
}

export const getDisplayScore = (assignment, gradingStandard) => {
  if (ENV.restrict_quantitative_data && assignment?.pointsPossible === 0)
    return getZeroPointAssignmentDisplayScore(
      getAssignmentEarnedPoints(assignment),
      assignment?.submissionsConnection?.nodes[0]?.gradingStatus,
      gradingStandard
    )

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
  }
  const earned = getAssignmentEarnedPoints(assignment)
  const total = getAssignmentTotalPoints(assignment)
  return `${earned || '0'}/${total || '0'}`
}

export const getZeroPointAssignmentDisplayScore = (score, gradingStatus, gradingStandard) => {
  if (gradingStatus !== 'graded') return '-'
  if (score === 0) {
    return <IconCheckLine />
  } else if (score >= 0) {
    return scorePercentageToLetterGrade(100, gradingStandard)
  } else if (score <= 0) {
    return `${score}/0`
  }
}

export const scorePercentageToLetterGrade = (score, gradingStandard) => {
  if (score === null || score === undefined) return null
  if (!Number.isFinite(Number.parseFloat(score))) return null
  if (score === ASSIGNMENT_NOT_APPLICABLE) return score

  let letter = null
  gradingStandard?.data?.forEach(gradeLevel => {
    if (Number.parseFloat(score) / 100 >= gradeLevel.baseValue && !letter) {
      letter = gradeLevel.letterGrade
    }
  })
  return letter
}

// **************************** DROP ASSIGNMENT FROM ASSIGNMENT GROUP ****************************

export const convertSubmissionToDroppableSubmission = (assignment, submission) => {
  return {
    score: submission?.score,
    grade: submission?.grade,
    total: assignment?.pointsPossible,
    assignment_id: assignment?._id,
    workflow_state: submission?.gradingStatus,
    excused: submission?.late,
    id: submission?._id,
    submission: {assignment_id: assignment?._id},
  }
}

export const camelCaseToSnakeCase = str => {
  return str.replace(/([A-Z])/g, (_match, letter) => `_${letter.toLowerCase()}`).replace(/^_/, '')
}

export const convertAssignmentGroupRules = assignmentGroup => {
  if (
    !assignmentGroup?.rules ||
    (assignmentGroup?.rules?.dropLowest === null &&
      assignmentGroup?.rules?.dropHighest === null &&
      assignmentGroup?.rules?.neverDrop === null)
  )
    return null
  const rules = {}
  Object.keys(assignmentGroup?.rules).forEach(key => {
    rules[camelCaseToSnakeCase(key)] = assignmentGroup.rules[key]
  })

  if (rules.never_drop !== null) {
    rules.never_drop = rules.never_drop.map(assignment => assignment._id)
  }
  return rules
}

export const filterDroppedAssignments = (
  assignments = [],
  assignmentGroup,
  returnDropped = false
) => {
  if (!assignments || !assignments.length) return []

  assignments = assignments?.filter(assignment => {
    return (
      assignment?.gradingType !== 'not_graded' &&
      assignment?.submissionsConnection?.nodes[0]?.score !== null
    )
  })

  const relevantSubmissions = assignments.map(assignment => {
    return convertSubmissionToDroppableSubmission(
      assignment,
      assignment?.submissionsConnection?.nodes[0]
    )
  })

  const rules = convertAssignmentGroupRules(assignmentGroup)
  if (rules === null) return returnDropped ? [] : assignments

  const assignmentsIdsToKeep = gradingHelpers
    .dropAssignments(relevantSubmissions, rules)
    .map(submission => submission?.submission?.assignment_id)

  return assignments.filter(assignment => {
    return returnDropped
      ? !assignmentsIdsToKeep.includes(assignment._id)
      : assignmentsIdsToKeep.includes(assignment._id)
  })
}

export const listDroppedAssignments = (queryData, byGradingPeriod) => {
  const processAssignmentGroup = (data, checkAssignment) => {
    return data?.assignmentGroupsConnection?.nodes
      ?.map(assignmentGroup => {
        const assignments = filterDroppedAssignments(
          filteredAssignments(data).filter(assignment => {
            return checkAssignment(assignment, assignmentGroup)
          }),
          assignmentGroup,
          true
        )
        return assignments
      })
      .flat()
  }

  return byGradingPeriod
    ? [
        ...new Set(
          queryData?.gradingPeriodsConnection?.nodes
            .map(gradingPeriod => {
              return processAssignmentGroup(queryData, (assignment, assignmentGroup) => {
                return (
                  assignment?.gradingPeriodId === gradingPeriod?._id &&
                  assignment?.assignmentGroup?._id === assignmentGroup?._id
                )
              })
            })
            .flat()
        ),
      ]
    : [
        ...new Set(
          processAssignmentGroup(queryData, (assignment, assignmentGroup) => {
            return assignment?.assignmentGroup?._id === assignmentGroup?._id
          })
        ),
      ]
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

const removeNonGroupAssignments = (assignments, assignmentGroup) => {
  return assignments?.filter(assignment => {
    return assignment?.assignmentGroup?._id === assignmentGroup?._id
  })
}

export const getAssignmentGroupTotalPoints = (assignmentGroup, assignments) => {
  return filterDroppedAssignments(
    removeNonGroupAssignments(assignments, assignmentGroup),
    assignmentGroup
  )?.reduce((total, assignment) => {
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
  return filterDroppedAssignments(
    removeNonGroupAssignments(assignments, assignmentGroup),
    assignmentGroup
  ).reduce((total, assignment) => {
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
  if (
    getAssignmentGroupTotalPoints(assignmentGroup, assignments) === 0 ||
    !assignments ||
    assignments?.length === 0
  )
    return ASSIGNMENT_NOT_APPLICABLE

  const earned = getAssignmentGroupEarnedPoints(assignmentGroup, assignments)
  const total = getAssignmentGroupTotalPoints(assignmentGroup, assignments)

  if (applyGroupWeights) {
    return ((((earned / total) * assignmentGroup?.groupWeight) / 100) * 100).toString()
  }

  return `${(earned / total) * 100}`
}

export const getAssignmentGroupPercentageWithPartialWeight = (
  assignmentGroups = [],
  assignments = []
) => {
  if (assignmentGroups?.length === 0 || assignments?.length === 0) return ASSIGNMENT_NOT_APPLICABLE
  return (
    calculateTotalPercentageWithPartialWeight(
      assignmentGroups,
      group => getAssignmentGroupPercentage(group, assignments, false),
      group => group?.groupWeight || 0
    ) || '0'
  )
}

export const getAssignmentGroupLetterGrade = (assignmentGroup, assignments, gradingStandard) => {
  if (assignments?.length === 0) return ASSIGNMENT_NOT_APPLICABLE

  const percentage = getAssignmentGroupPercentage(assignmentGroup, assignments, false)

  return percentage === ASSIGNMENT_NOT_APPLICABLE
    ? percentage
    : scorePercentageToLetterGrade(percentage, gradingStandard)
}

// **************** GRADING PERIODS ***********************************************

export const getGradingPeriodTotalPoints = (gradingPeriod, assignments) => {
  return (
    assignments?.reduce((total, assignment) => {
      if (
        assignment?.gradingPeriodId === gradingPeriod?._id &&
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
        assignment?.gradingPeriodId === gradingPeriod?._id &&
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
  if (!assignments || assignments?.length === 0) return ASSIGNMENT_NOT_APPLICABLE

  assignments = assignments?.filter(assignment => {
    return assignment?.gradingPeriodId === gradingPeriod?._id
  })

  if (applyGroupWeights) {
    return getAssignmentGroupPercentageWithPartialWeight(assignmentGroups, assignments)
  }

  const [gradingPeriodEarnedPoints, gradingPeriodTotalPoints] = assignmentGroups?.reduce(
    ([earnedPoints, totalPoints], assignmentGroup) => {
      const earnedPointsValue = getAssignmentGroupEarnedPoints(assignmentGroup, assignments, false)
      const totalPointsValue = getAssignmentGroupTotalPoints(assignmentGroup, assignments, false)

      if (earnedPointsValue !== ASSIGNMENT_NOT_APPLICABLE) {
        earnedPoints += parseFloat(earnedPointsValue)
      }

      if (totalPointsValue !== ASSIGNMENT_NOT_APPLICABLE) {
        totalPoints += parseFloat(totalPointsValue)
      }

      return [earnedPoints, totalPoints]
    },
    [0, 0]
  )

  if (gradingPeriodTotalPoints === 0 && gradingPeriodEarnedPoints === 0)
    return ASSIGNMENT_NOT_APPLICABLE

  return (
    `${(gradingPeriodEarnedPoints / gradingPeriodTotalPoints) * 100}` || ASSIGNMENT_NOT_APPLICABLE
  )
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

export const calculateTotalPercentageWithPartialWeight = (
  items,
  getItemPercentage,
  getItemWeight
) => {
  const filteredItems = items?.filter(item => {
    return getItemWeight(item) && getItemPercentage(item) !== 'N/A'
  })

  let returnTotal =
    filteredItems?.reduce((total, item) => {
      const itemPercentage = getItemPercentage(item)
      const itemWeight = getItemWeight(item)
      return `${Number.parseFloat(total) + itemPercentage * (itemWeight / 100)}`
    }, '0') || '0'

  if (returnTotal === '0') return ASSIGNMENT_NOT_APPLICABLE

  const availableWeightsSum = filteredItems?.reduce((total, item) => {
    const itemWeight = getItemWeight(item)
    return total + itemWeight
  }, 0)

  if (availableWeightsSum < 100) {
    returnTotal = `${Number.parseFloat(returnTotal) * (1 / (availableWeightsSum / 100))}`
  }

  return returnTotal
}

export const getTotal = (assignments, assignmentGroups, gradingPeriods, applyWeights) => {
  if (!assignments || assignments?.length === 0) return ASSIGNMENT_NOT_APPLICABLE

  const validGradingPeriodsCount =
    gradingPeriods?.filter(period => {
      return period?.weight && period?.weight > 0
    }) || []

  let returnTotal = 0
  if (getGradingPeriodID() === '0' && validGradingPeriodsCount.length > 0) {
    returnTotal = calculateTotalPercentageWithPartialWeight(
      gradingPeriods,
      period =>
        getGradingPeriodPercentage(
          period,
          assignments?.filter(assignment => {
            return assignment?.gradingPeriodId === period?._id
          }),
          assignmentGroups,
          validGradingPeriodsCount.length === gradingPeriods.length ? applyWeights : false
        ),
      period => period?.weight || 0
    )
  } else if (applyWeights) {
    returnTotal = getAssignmentGroupPercentageWithPartialWeight(assignmentGroups, assignments)
  } else {
    const {possiblePoints, earnedPoints} = assignmentGroups?.reduce(
      (coursePoints, assignmentGroup) => {
        const groupTotalPoints = getAssignmentGroupTotalPoints(assignmentGroup, assignments)
        const groupEarnedPoints = getAssignmentGroupEarnedPoints(assignmentGroup, assignments)

        if (groupTotalPoints !== ASSIGNMENT_NOT_APPLICABLE) {
          coursePoints.possiblePoints += Number.parseFloat(groupTotalPoints)
        }

        if (groupEarnedPoints !== ASSIGNMENT_NOT_APPLICABLE) {
          coursePoints.earnedPoints += Number.parseFloat(groupEarnedPoints)
        }

        return coursePoints
      },
      {possiblePoints: 0, earnedPoints: 0}
    )

    returnTotal = `${(earnedPoints / possiblePoints) * 100}`
  }
  return returnTotal === '0' ? ASSIGNMENT_NOT_APPLICABLE : returnTotal
}

// ********************************************************************************
