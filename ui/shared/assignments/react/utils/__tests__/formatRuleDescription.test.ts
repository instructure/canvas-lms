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
      it('returns "Student A must review Student B" when mustReview=true and reviewPermitted=true', () => {
        const rule = createRule(true, true, true)
        expect(formatFullRuleDescription(rule)).toBe('Student A must review Student B')
      })

      it('returns "Student A must not review Student B" when mustReview=true and reviewPermitted=false', () => {
        const rule = createRule(true, true, false)
        expect(formatFullRuleDescription(rule)).toBe('Student A must not review Student B')
      })

      it('returns "Student A should review Student B" when mustReview=false and reviewPermitted=true', () => {
        const rule = createRule(true, false, true)
        expect(formatFullRuleDescription(rule)).toBe('Student A should review Student B')
      })

      it('returns "Student A should not review Student B" when mustReview=false and reviewPermitted=false', () => {
        const rule = createRule(true, false, false)
        expect(formatFullRuleDescription(rule)).toBe('Student A should not review Student B')
      })
    })

    describe('when appliesToAssessor is false', () => {
      it('returns "Student B must be reviewed by Student A" when mustReview=true and reviewPermitted=true', () => {
        const rule = createRule(false, true, true)
        expect(formatFullRuleDescription(rule)).toBe('Student B must be reviewed by Student A')
      })

      it('returns "Student B must not be reviewed by Student A" when mustReview=true and reviewPermitted=false', () => {
        const rule = createRule(false, true, false)
        expect(formatFullRuleDescription(rule)).toBe('Student B must not be reviewed by Student A')
      })

      it('returns "Student B should be reviewed by Student A" when mustReview=false and reviewPermitted=true', () => {
        const rule = createRule(false, false, true)
        expect(formatFullRuleDescription(rule)).toBe('Student B should be reviewed by Student A')
      })

      it('returns "Student B should not be reviewed by Student A" when mustReview=false and reviewPermitted=false', () => {
        const rule = createRule(false, false, false)
        expect(formatFullRuleDescription(rule)).toBe(
          'Student B should not be reviewed by Student A',
        )
      })
    })
  })

  describe('formatRuleDescription', () => {
    describe('when appliesToAssessor is true', () => {
      it('returns "Must review Student B" when mustReview=true and reviewPermitted=true', () => {
        const rule = createRule(true, true, true)
        expect(formatRuleDescription(rule)).toBe('Must review Student B')
      })

      it('returns "Must not review Student B" when mustReview=true and reviewPermitted=false', () => {
        const rule = createRule(true, true, false)
        expect(formatRuleDescription(rule)).toBe('Must not review Student B')
      })

      it('returns "Should review Student B" when mustReview=false and reviewPermitted=true', () => {
        const rule = createRule(true, false, true)
        expect(formatRuleDescription(rule)).toBe('Should review Student B')
      })

      it('returns "Should not review Student B" when mustReview=false and reviewPermitted=false', () => {
        const rule = createRule(true, false, false)
        expect(formatRuleDescription(rule)).toBe('Should not review Student B')
      })
    })

    describe('when appliesToAssessor is false', () => {
      it('returns "Must be reviewed by Student A" when mustReview=true and reviewPermitted=true', () => {
        const rule = createRule(false, true, true)
        expect(formatRuleDescription(rule)).toBe('Must be reviewed by Student A')
      })

      it('returns "Must not be reviewed by Student A" when mustReview=true and reviewPermitted=false', () => {
        const rule = createRule(false, true, false)
        expect(formatRuleDescription(rule)).toBe('Must not be reviewed by Student A')
      })

      it('returns "Should be reviewed by Student A" when mustReview=false and reviewPermitted=true', () => {
        const rule = createRule(false, false, true)
        expect(formatRuleDescription(rule)).toBe('Should be reviewed by Student A')
      })

      it('returns "Should not be reviewed by Student A" when mustReview=false and reviewPermitted=false', () => {
        const rule = createRule(false, false, false)
        expect(formatRuleDescription(rule)).toBe('Should not be reviewed by Student A')
      })
    })
  })
})
