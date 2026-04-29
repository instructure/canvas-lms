/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {formatFullRuleDescription, formatRuleDescription} from '../formatRuleDescription'
import {AllocationRuleType} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'

describe('formatRuleDescription', () => {
  const createRule = (
    appliesToAssessor: boolean,
    mustReview: boolean,
    reviewPermitted: boolean,
  ): AllocationRuleType => ({
    _id: '1',
    appliesToAssessor,
    mustReview,
    reviewPermitted,
    assessor: {
      _id: 'assessor-1',
      name: 'Student A',
      peerReviewStatus: {mustReviewCount: 0, completedReviewsCount: 0},
    },
    assessee: {
      _id: 'assessee-1',
      name: 'Student B',
      peerReviewStatus: {mustReviewCount: 0, completedReviewsCount: 0},
    },
  })

  describe('formatFullRuleDescription', () => {
    describe('when appliesToAssessor is true', () => {
      it('returns "Student A will review Student B (strict)" when mustReview=true and reviewPermitted=true', () => {
        const rule = createRule(true, true, true)
        expect(formatFullRuleDescription(rule)).toBe('Student A will review Student B (strict)')
      })

      it('returns "Student A will not review Student B (strict)" when mustReview=true and reviewPermitted=false', () => {
        const rule = createRule(true, true, false)
        expect(formatFullRuleDescription(rule)).toBe('Student A will not review Student B (strict)')
      })

      it('returns "Student A will review Student B (flexible)" when mustReview=false and reviewPermitted=true', () => {
        const rule = createRule(true, false, true)
        expect(formatFullRuleDescription(rule)).toBe('Student A will review Student B (flexible)')
      })

      it('returns "Student A will not review Student B (flexible)" when mustReview=false and reviewPermitted=false', () => {
        const rule = createRule(true, false, false)
        expect(formatFullRuleDescription(rule)).toBe(
          'Student A will not review Student B (flexible)',
        )
      })
    })

    describe('when appliesToAssessor is false', () => {
      it('returns "Student B will be reviewed by Student A (strict)" when mustReview=true and reviewPermitted=true', () => {
        const rule = createRule(false, true, true)
        expect(formatFullRuleDescription(rule)).toBe(
          'Student B will be reviewed by Student A (strict)',
        )
      })

      it('returns "Student B will not be reviewed by Student A (strict)" when mustReview=true and reviewPermitted=false', () => {
        const rule = createRule(false, true, false)
        expect(formatFullRuleDescription(rule)).toBe(
          'Student B will not be reviewed by Student A (strict)',
        )
      })

      it('returns "Student B will be reviewed by Student A (flexible)" when mustReview=false and reviewPermitted=true', () => {
        const rule = createRule(false, false, true)
        expect(formatFullRuleDescription(rule)).toBe(
          'Student B will be reviewed by Student A (flexible)',
        )
      })

      it('returns "Student B will not be reviewed by Student A (flexible)" when mustReview=false and reviewPermitted=false', () => {
        const rule = createRule(false, false, false)
        expect(formatFullRuleDescription(rule)).toBe(
          'Student B will not be reviewed by Student A (flexible)',
        )
      })
    })
  })

  describe('formatRuleDescription', () => {
    describe('when appliesToAssessor is true', () => {
      it('returns "will review Student B (strict)" when mustReview=true and reviewPermitted=true', () => {
        const rule = createRule(true, true, true)
        expect(formatRuleDescription(rule)).toBe('will review Student B (strict)')
      })

      it('returns "will not review Student B (strict)" when mustReview=true and reviewPermitted=false', () => {
        const rule = createRule(true, true, false)
        expect(formatRuleDescription(rule)).toBe('will not review Student B (strict)')
      })

      it('returns "will review Student B (flexible)" when mustReview=false and reviewPermitted=true', () => {
        const rule = createRule(true, false, true)
        expect(formatRuleDescription(rule)).toBe('will review Student B (flexible)')
      })

      it('returns "will not review Student B (flexible)" when mustReview=false and reviewPermitted=false', () => {
        const rule = createRule(true, false, false)
        expect(formatRuleDescription(rule)).toBe('will not review Student B (flexible)')
      })
    })

    describe('when appliesToAssessor is false', () => {
      it('returns "will be reviewed by Student A (strict)" when mustReview=true and reviewPermitted=true', () => {
        const rule = createRule(false, true, true)
        expect(formatRuleDescription(rule)).toBe('will be reviewed by Student A (strict)')
      })

      it('returns "will not be reviewed by Student A (strict)" when mustReview=true and reviewPermitted=false', () => {
        const rule = createRule(false, true, false)
        expect(formatRuleDescription(rule)).toBe('will not be reviewed by Student A (strict)')
      })

      it('returns "will be reviewed by Student A (flexible)" when mustReview=false and reviewPermitted=true', () => {
        const rule = createRule(false, false, true)
        expect(formatRuleDescription(rule)).toBe('will be reviewed by Student A (flexible)')
      })

      it('returns "will not be reviewed by Student A (flexible)" when mustReview=false and reviewPermitted=false', () => {
        const rule = createRule(false, false, false)
        expect(formatRuleDescription(rule)).toBe('will not be reviewed by Student A (flexible)')
      })
    })
  })
})
