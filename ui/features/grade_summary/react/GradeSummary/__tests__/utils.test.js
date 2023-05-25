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

import {Pill} from '@instructure/ui-pill'

import {Assignment} from '../../../graphql/Assignment'
import {AssignmentGroup} from '../../../graphql/AssignmentGroup'
import {GradingStandard} from '../../../graphql/GradingStandard'
import {GradingPeriod} from '../../../graphql/GradingPeriod'
import {Submission} from '../../../graphql/Submission'
import {
  getAssignmentGroupScore,
  formatNumber,
  submissionCommentsPresent,
  getDisplayStatus,
  getNoSubmissionStatus,
  scorePercentageToLetterGrade,
  getAssignmentTotalPoints,
  getAssignmentEarnedPoints,
  getAssignmentPercentage,
  getAssignmentLetterGrade,
  getAssignmentGroupTotalPoints,
  getAssignmentGroupEarnedPoints,
  getAssignmentGroupPercentage,
  getAssignmentGroupLetterGrade,
  getGradingPeriodTotalPoints,
  getGradingPeriodEarnedPoints,
  getGradingPeriodPercentage,
} from '../utils'

const createAssignment = (score, pointsPossible) => {
  return Assignment.mock({
    pointsPossible,
    submissionsConnection: {nodes: [Submission.mock({score})]},
  })
}

const mockAssignments = (possibleScores = []) => {
  return possibleScores.length === 0
    ? [
        createAssignment(10, 10),
        createAssignment(8, 10),
        createAssignment(7, 10),
        createAssignment(6, 10),
      ]
    : possibleScores.map(score => createAssignment(10, score))
}

const getTime = past => {
  const date = new Date()
  if (past) {
    date.setDate(date.getDate() - 1)
  } else {
    date.setDate(date.getDate() + 1)
  }

  return date.toISOString()
}

describe('util', () => {
  describe('getAssignmentScorePercentage', () => {
    it('should return override score percentage if available', () => {
      const assignmentGroupWithOverrideScore = {
        gradesConnection: {
          nodes: [
            {
              overrideScore: 90,
              currentScore: 80,
            },
          ],
        },
      }
      expect(getAssignmentGroupScore(assignmentGroupWithOverrideScore)).toBe('90%')
    })

    it('should return current score percentage if override score is not available', () => {
      const assignmentGroupWithCurrentScore = {
        gradesConnection: {
          nodes: [
            {
              currentScore: 75,
            },
          ],
        },
      }
      expect(getAssignmentGroupScore(assignmentGroupWithCurrentScore)).toBe('75%')
    })

    it('should return "N/A" if no scores are available', () => {
      const assignmentGroupWithNoScores = {
        gradesConnection: {
          nodes: [{}],
        },
      }
      expect(getAssignmentGroupScore(assignmentGroupWithNoScores)).toBe('N/A')
    })
  })

  describe('formatNumber', () => {
    it('should format a positive number with two decimal places', () => {
      expect(formatNumber(1234.5678)).toBe('1,234.57')
    })

    it('should format a negative number with two decimal places', () => {
      expect(formatNumber(-9876.5432)).toBe('-9,876.54')
    })

    it('should format zero with two decimal places', () => {
      expect(formatNumber(0)).toBe('0.00')
    })

    it('should format a number with no decimal places', () => {
      expect(formatNumber(123)).toBe('123.00')
    })

    it('should format a large number with two decimal places', () => {
      expect(formatNumber(1234567890.1234)).toBe('1,234,567,890.12')
    })

    it('should return undefined if the input is undefined', () => {
      expect(formatNumber(undefined)).toBeUndefined()
    })

    it('should return undefined if the input is null', () => {
      expect(formatNumber(null)).toBeUndefined()
    })
  })

  describe('submissionCommentsPresent', () => {
    it('should return true if at least one submission has comments', () => {
      const assignment = {
        submissionsConnection: {
          nodes: [
            {
              commentsConnection: {
                nodes: [
                  {
                    id: 1,
                    text: 'Comment 1',
                  },
                ],
              },
            },
            {
              commentsConnection: {
                nodes: [],
              },
            },
          ],
        },
      }
      expect(submissionCommentsPresent(assignment)).toBe(true)
    })

    it('should return false if no submission has comments', () => {
      const assignment = {
        submissionsConnection: {
          nodes: [
            {
              commentsConnection: {
                nodes: [],
              },
            },
            {
              commentsConnection: {
                nodes: [],
              },
            },
          ],
        },
      }
      expect(submissionCommentsPresent(assignment)).toBe(false)
    })

    it('should return false if assignment is undefined', () => {
      expect(submissionCommentsPresent(undefined)).toBe(false)
    })

    it('should return false if assignment is null', () => {
      expect(submissionCommentsPresent(null)).toBe(false)
    })
  })

  describe('getDisplayStatus', () => {
    it('should return "Excused" status when gradingStatus is "excused"', () => {
      const assignment = {
        submissionsConnection: {
          nodes: [
            {
              gradingStatus: 'excused',
            },
          ],
        },
      }
      const expectedOutput = <Pill color="primary">Excused</Pill>
      expect(getDisplayStatus(assignment)).toStrictEqual(expectedOutput)
    })

    it('should return "Not Graded" status when gradingType is "not_graded"', () => {
      const assignment = {
        gradingType: 'not_graded',
      }
      const expectedOutput = <Pill color="primary">Not Graded</Pill>
      expect(getDisplayStatus(assignment)).toStrictEqual(expectedOutput)
    })

    it('should return "Not Submission" status when no submissions exist', () => {
      const assignment = {
        submissionsConnection: {
          nodes: [],
        },
        dueAt: getTime(false),
      }
      const expectedOutput = <Pill color="primary">Not Submitted</Pill>
      expect(getDisplayStatus(assignment)).toStrictEqual(expectedOutput)
    })

    it('should return "Late" status when the first submission is late', () => {
      const assignment = {
        submissionsConnection: {
          nodes: [
            {
              late: true,
            },
          ],
        },
      }
      const expectedOutput = <Pill color="warning">Late</Pill>
      expect(getDisplayStatus(assignment)).toStrictEqual(expectedOutput)
    })

    it('should return "Graded" status when gradingStatus is "graded"', () => {
      const assignment = {
        submissionsConnection: {
          nodes: [
            {
              gradingStatus: 'graded',
            },
          ],
        },
      }
      const expectedOutput = <Pill color="success">Graded</Pill>
      expect(getDisplayStatus(assignment)).toStrictEqual(expectedOutput)
    })

    it('should return "Not Graded" status for other cases', () => {
      const assignment = {}
      const expectedOutput = <Pill>Not Graded</Pill>
      expect(getDisplayStatus(assignment)).toStrictEqual(expectedOutput)
    })
  })

  describe('getNoSubmissionStatus', () => {
    it('should return "Missing" status when dueDate is in the past', () => {
      const dueDate = getTime(true)
      const expectedOutput = <Pill color="danger">Missing</Pill>
      expect(getNoSubmissionStatus(dueDate)).toStrictEqual(expectedOutput)
    })

    it('should return "Not Submitted" status when dueDate is in the future', () => {
      const dueDate = getTime(false)
      const expectedOutput = <Pill color="primary">Not Submitted</Pill>
      expect(getNoSubmissionStatus(dueDate)).toStrictEqual(expectedOutput)
    })
  })

  describe('scorePercentageToLetterGrade', () => {
    const gradingStandard = GradingStandard.mock()

    it('should return the correct letter grade for a given score', () => {
      expect(scorePercentageToLetterGrade(1000, gradingStandard)).toBe('A')
      expect(scorePercentageToLetterGrade(95, gradingStandard)).toBe('A')
      expect(scorePercentageToLetterGrade(90, gradingStandard)).toBe('A-')
      expect(scorePercentageToLetterGrade(88, gradingStandard)).toBe('B+')
      expect(scorePercentageToLetterGrade(84, gradingStandard)).toBe('B')
      expect(scorePercentageToLetterGrade(80, gradingStandard)).toBe('B-')
      expect(scorePercentageToLetterGrade(77, gradingStandard)).toBe('C+')
      expect(scorePercentageToLetterGrade(74, gradingStandard)).toBe('C')
      expect(scorePercentageToLetterGrade(70, gradingStandard)).toBe('C-')
      expect(scorePercentageToLetterGrade(67, gradingStandard)).toBe('D+')
      expect(scorePercentageToLetterGrade(64, gradingStandard)).toBe('D')
      expect(scorePercentageToLetterGrade(61, gradingStandard)).toBe('D-')
      expect(scorePercentageToLetterGrade(0, gradingStandard)).toBe('F')
    })

    it('should return null when the score does not meet any grading standard', () => {
      expect(scorePercentageToLetterGrade(null, gradingStandard)).toBeNull()
      expect(scorePercentageToLetterGrade(undefined, gradingStandard)).toBeNull()
      expect(scorePercentageToLetterGrade('not a number', gradingStandard)).toBeNull()
      expect(scorePercentageToLetterGrade('', gradingStandard)).toBeNull()
    })
  })

  describe('Assignments', () => {
    describe('getAssignmentTotalPoints', () => {
      it('should return the points possible for the assignment', () => {
        const assignment = {pointsPossible: 10}
        expect(getAssignmentTotalPoints(assignment)).toBe(10)
      })

      it('should return 0 when points possible is not provided', () => {
        const assignment = {}
        expect(getAssignmentTotalPoints(assignment)).toBe(0)
      })
    })

    describe('getAssignmentEarnedPoints', () => {
      it('should return the earned points for the assignment', () => {
        const assignment = {
          submissionsConnection: {
            nodes: [
              {
                score: '8.5',
              },
            ],
          },
        }
        expect(getAssignmentEarnedPoints(assignment)).toBe(8.5)
      })

      it('should return 0 when earned points are not provided', () => {
        const assignment = {}
        expect(getAssignmentEarnedPoints(assignment)).toBe(0)
      })
    })

    describe('getAssignmentPercentage', () => {
      it('should return the correct percentage for the assignment', () => {
        const assignment = {
          pointsPossible: 20,
          submissionsConnection: {
            nodes: [
              {
                score: '16',
              },
            ],
          },
        }
        expect(getAssignmentPercentage(assignment)).toBe(80)
      })

      it('should return 0 when total points are not provided', () => {
        const assignment = {}
        expect(getAssignmentPercentage(assignment)).toBe(0)
      })
    })

    describe('getAssignmentLetterGrade', () => {
      const gradingStandard = GradingStandard.mock()

      it('should return the correct letter grade for the assignment', () => {
        const assignment = {
          pointsPossible: 100,
          submissionsConnection: {
            nodes: [
              {
                score: '85',
              },
            ],
          },
        }
        expect(getAssignmentLetterGrade(assignment, gradingStandard)).toBe('B')
      })

      it('should return null when letter grade cannot be determined', () => {
        const assignment = {}
        expect(getAssignmentLetterGrade(assignment, gradingStandard)).toBeNull()
      })
    })
  })

  describe('Assignment Groups', () => {
    describe('getAssignmentGroupTotalPoints', () => {
      it('should return the points possible for the assignment group', () => {
        const assignmentGroup = AssignmentGroup.mock()
        const assignments = mockAssignments()
        expect(getAssignmentGroupTotalPoints(assignmentGroup, assignments)).toBe(40)
      })

      it('should return 0 when points possible is not provided', () => {
        const assignmentGroup = {}
        const assignments = []
        expect(getAssignmentGroupTotalPoints(assignmentGroup, assignments)).toBe(0)
      })

      it('should return undefined when assignments are not provided', () => {
        const assignmentGroup = {}
        expect(getAssignmentGroupTotalPoints(assignmentGroup)).toBe(undefined)
      })
    })

    describe('getAssignmentGroupEarnedPoints', () => {
      it('should return the earned points for the assignment group', () => {
        const assignmentGroup = AssignmentGroup.mock()
        const assignments = mockAssignments()
        expect(getAssignmentGroupEarnedPoints(assignmentGroup, assignments)).toBe(31)
      })

      it('should return 0 when earned points is not provided', () => {
        const assignmentGroup = {}
        const assignments = []
        expect(getAssignmentGroupEarnedPoints(assignmentGroup, assignments)).toBe(0)
      })

      it('should return undefined when assignments are not provided', () => {
        const assignmentGroup = {}
        expect(getAssignmentGroupEarnedPoints(assignmentGroup)).toBe(undefined)
      })
    })

    describe('getAssignmentGroupPercentage', () => {
      describe('when the assignment group is not weighted', () => {
        it('should return the correct percentage for the assignment group', () => {
          const assignmentGroup = AssignmentGroup.mock()
          const assignments = mockAssignments()
          expect(getAssignmentGroupPercentage(assignmentGroup, assignments, false)).toBe(77.5)
        })

        it('should return 0 when total points is not provided', () => {
          const assignmentGroup = {}
          const assignments = []
          expect(getAssignmentGroupPercentage(assignmentGroup, assignments, false)).toBe(0)
        })

        it('should return 0 when assignments are not provided', () => {
          const assignmentGroup = {}
          expect(getAssignmentGroupPercentage(assignmentGroup, undefined, false)).toBe(0)
        })
      })

      describe('when the assignment group is weighted', () => {
        it('should return the correct percentage for the assignment group', () => {
          const assignmentGroup = AssignmentGroup.mock()
          const assignments = mockAssignments()
          expect(getAssignmentGroupPercentage(assignmentGroup, assignments, true)).toBe(
            77.5 * (assignmentGroup?.groupWeight / 100)
          )
        })

        it('should return 0 when total points is not provided', () => {
          const assignmentGroup = {}
          const assignments = []
          expect(getAssignmentGroupPercentage(assignmentGroup, assignments, true)).toBe(0)
        })

        it('should return 0 when assignments are not provided', () => {
          const assignmentGroup = {}
          expect(getAssignmentGroupPercentage(assignmentGroup, undefined, true)).toBe(0)
        })
      })
    })

    describe('getAssignmentGroupLetterGrade', () => {
      const gradingStandard = GradingStandard.mock()

      it('should return the correct letter grade for the assignment group', () => {
        const assignmentGroup = AssignmentGroup.mock()
        const assignments = mockAssignments()
        expect(getAssignmentGroupLetterGrade(assignmentGroup, assignments, gradingStandard)).toBe(
          'C+'
        )
      })

      it('should return null when letter grade cannot be determined', () => {
        const assignmentGroup = {}
        const assignments = []
        expect(getAssignmentGroupLetterGrade(assignmentGroup, assignments, gradingStandard)).toBe(
          'N/A'
        )
      })
    })
  })

  describe('Grading Periods', () => {
    describe('getGradingPeriodTotalPoints', () => {
      it('should return the points possible for the grading period', () => {
        const gradingPeriod = GradingPeriod.mock()
        const assignments = mockAssignments()
        expect(getGradingPeriodTotalPoints(gradingPeriod, assignments)).toBe(40)
      })

      it('should return 0 when points possible is not provided', () => {
        const gradingPeriod = {}
        const assignments = []
        expect(getGradingPeriodTotalPoints(gradingPeriod, assignments)).toBe(0)
      })

      it('should return 0 when assignments are not provided', () => {
        const gradingPeriod = {}
        expect(getGradingPeriodTotalPoints(gradingPeriod)).toBe(0)
      })
    })

    describe('getGradingPeriodEarnedPoints', () => {
      it('should return the earned points for the grading period', () => {
        const gradingPeriod = GradingPeriod.mock()
        const assignments = mockAssignments()
        expect(getGradingPeriodEarnedPoints(gradingPeriod, assignments)).toBe(31)
      })

      it('should return 0 when earned points is not provided', () => {
        const gradingPeriod = {}
        const assignments = []
        expect(getGradingPeriodEarnedPoints(gradingPeriod, assignments)).toBe(0)
      })

      it('should return 0 when assignments are not provided', () => {
        const gradingPeriod = {}
        expect(getGradingPeriodEarnedPoints(gradingPeriod)).toBe(0)
      })
    })

    describe('getGradingPeriodPercentage', () => {
      describe('when the grading period is not weighted', () => {
        it('should return the correct percentage for the grading period', () => {
          const gradingPeriod = GradingPeriod.mock()
          const assignments = mockAssignments()
          expect(getGradingPeriodPercentage(gradingPeriod, assignments, false)).toBe(77.5)
        })

        it('should return 0 when total points is not provided', () => {
          const gradingPeriod = {}
          const assignments = []
          expect(getGradingPeriodPercentage(gradingPeriod, assignments, false)).toBe(0)
        })

        it('should return 0 when assignments are not provided', () => {
          const gradingPeriod = {}
          expect(getGradingPeriodPercentage(gradingPeriod, undefined, false)).toBe(0)
        })
      })

      describe('when the grading period is weighted', () => {
        it('should return the correct percentage for the grading period', () => {
          const gradingPeriod = GradingPeriod.mock()
          const assignments = mockAssignments()
          const assignmentGroup = AssignmentGroup.mock()
          expect(
            getGradingPeriodPercentage(gradingPeriod, assignments, [assignmentGroup], true)
          ).toBe(77.5 * 0.5)
        })

        it('should return 0 when total points is not provided', () => {
          const gradingPeriod = {}
          const assignments = []
          const assignmentGroup = AssignmentGroup.mock()
          expect(
            getGradingPeriodPercentage(gradingPeriod, assignments, [assignmentGroup], true)
          ).toBe(0)
        })

        it('should return 0 when assignments are not provided', () => {
          const gradingPeriod = {}
          expect(getGradingPeriodPercentage(gradingPeriod, undefined, undefined, true)).toBe(0)
        })
      })
    })
  })
})
