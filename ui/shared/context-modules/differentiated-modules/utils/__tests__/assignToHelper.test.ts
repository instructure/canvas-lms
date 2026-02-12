/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import type {
  DateDetailsPayload,
  ItemAssignToCardSpec,
  DateDetailsOverride,
  AssigneeOption,
  BackendDateDetailsOverride,
} from '../../react/Item/types'
import {AssignmentOverridesPayload} from '../../react/types'
import {
  generateAssignmentOverridesPayload,
  generateDateDetailsPayload,
  flattenPeerReviewDates,
  markPeerReviewDefaultDates,
  getAssignmentOverride,
  getDefaultPeerReviewDates,
  hasPeerReviewOverrideDates,
  getPeerReviewOverride,
  getAssignmentAndPeerReviewOverrides,
} from '../assignToHelper'

describe('assitnToHelper', () => {
  describe('generateAssignmentOverridesPayload', () => {
    it('returns the correct payload', () => {
      const selectedAssignees: AssigneeOption[] = [
        {
          id: 'section-1',
          value: 'Math 101',
          group: 'Sections',
        },
        {
          id: 'student-1',
          value: 'Ben',
          group: 'Students',
          sisID: 'student_1',
        },
        {
          id: 'tag-1',
          value: 'Tag 1',
          group: 'Tags',
          groupCategoryId: '1',
          groupCategoryName: 'Non Collaborative Group Category',
        },
      ]
      const expectedPayload: AssignmentOverridesPayload = {
        overrides: [
          {course_section_id: '1', id: undefined},
          {group_category_id: '1', group_id: '1', id: undefined},
          {student_ids: ['1'], id: undefined},
        ],
      }
      expect(generateAssignmentOverridesPayload(selectedAssignees)).toEqual(expectedPayload)
    })

    it('returns the correct payload when overrides exist', () => {
      const selectedAssignees: AssigneeOption[] = [
        {
          id: 'section-1',
          value: 'Math 101',
          group: 'Sections',
          overrideId: '1',
        },
        {
          id: 'student-1',
          value: 'Ben',
          group: 'Students',
          sisID: 'student_1',
          overrideId: '2',
        },
        {
          id: 'tag-1',
          value: 'Tag 1',
          group: 'Tags',
          groupCategoryId: '1',
          groupCategoryName: 'Non Collaborative Group Category',
          overrideId: '3',
        },
      ]
      const expectedPayload: AssignmentOverridesPayload = {
        overrides: [
          {course_section_id: '1', id: '1'},
          {group_category_id: '1', group_id: '1', id: '3'},
          {student_ids: ['1'], id: '2'},
        ],
      }
      expect(generateAssignmentOverridesPayload(selectedAssignees)).toEqual(expectedPayload)
    })
  })

  describe('generateDateDetailsPayload', () => {
    it('returns the correct payload when everyone due/unlock/lock dates are removed', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          key: 'everyone_card',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['everyone'] as string[],
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        due_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unlock_at: null,
        lock_at: null,
        assignment_overrides: [] as DateDetailsOverride[],
        only_visible_to_overrides: false,
      }
      expect(generateDateDetailsPayload(cards, false, [])).toEqual(expectedPayload)
    })

    it('returns a mastery paths override if a MP card was setup', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: undefined,
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['mastery_paths'] as string[],
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [
          {
            due_at: undefined,
            id: undefined,
            lock_at: undefined,
            noop_id: 1,
            unlock_at: undefined,
            title: 'Mastery Paths',
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            unassign_item: false,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
        due_at: null,
        unlock_at: null,
        lock_at: null,
      }
      expect(generateDateDetailsPayload(cards, false, [])).toEqual(expectedPayload)
    })

    it('returns a course override if allowed and an everyone card was created', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['everyone'] as string[],
          defaultOptions: ['everyone'],
          due_at: '2021-01-01T00:00:00Z',
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [
          {
            due_at: '2021-01-01T00:00:00Z',
            id: '1',
            lock_at: undefined,
            course_id: 'everyone',
            unlock_at: undefined,
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            unassign_item: false,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
      }
      expect(generateDateDetailsPayload(cards, true, [])).toEqual(expectedPayload)
    })

    it('does not include override id for a course override if not originally a course override', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['everyone'] as string[],
          defaultOptions: ['section-1'],
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [
          {
            due_at: undefined,
            id: undefined,
            lock_at: undefined,
            course_id: 'everyone',
            unlock_at: undefined,
            unassign_item: false,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
      }
      expect(generateDateDetailsPayload(cards, true, [])).toEqual(expectedPayload)
    })

    it('does not include override id for a section override if not originally a section', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['section-1'] as string[],
          defaultOptions: ['student-1'],
          due_at: '2021-01-01T00:00:00Z',
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [
          {
            due_at: '2021-01-01T00:00:00Z',
            id: undefined,
            lock_at: undefined,
            course_section_id: '1',
            unlock_at: undefined,
            unassign_item: false,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
        due_at: null,
        unlock_at: null,
        lock_at: null,
      }
      expect(generateDateDetailsPayload(cards, true, [])).toEqual(expectedPayload)
    })

    it('includes differentiation tags in payload', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['tag-1'] as string[],
          defaultOptions: ['student-1'],
          due_at: '2021-02-01T00:00:00Z',
          lock_at: '2021-05-01T00:00:00Z',
          unlock_at: '2021-01-01T00:00:00Z',
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [
          {
            due_at: '2021-02-01T00:00:00Z',
            id: undefined,
            lock_at: '2021-05-01T00:00:00Z',
            group_id: '1',
            unlock_at: '2021-01-01T00:00:00Z',
            non_collaborative: true,
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            unassign_item: false,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
        due_at: null,
        unlock_at: null,
        lock_at: null,
      }
      expect(generateDateDetailsPayload(cards, true, [])).toEqual(expectedPayload)
    })

    it('does not include differentiation tag in payload if it is default option', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['tag-1'] as string[],
          defaultOptions: ['tag-1'],
          due_at: null,
          lock_at: null,
          unlock_at: null,
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
        due_at: null,
        unlock_at: null,
        lock_at: null,
      }
      expect(generateDateDetailsPayload(cards, true, [])).toEqual(expectedPayload)
    })

    it('includes previous/new tag(s) in payload if hasModuleOverrides is false', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: undefined,
          isValid: true,
          hasAssignees: true,
          defaultOptions: ['tag-1'] as string[],
          selectedAssigneeIds: ['tag-1', 'tag-2'] as string[],
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [
          {
            id: undefined,
            lock_at: undefined,
            non_collaborative: true,
            group_id: '1',
            due_at: undefined,
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            unassign_item: false,
            unlock_at: undefined,
          },
          {
            id: undefined,
            lock_at: undefined,
            non_collaborative: true,
            group_id: '2',
            due_at: undefined,
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            unassign_item: false,
            unlock_at: undefined,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
        due_at: null,
        unlock_at: null,
        lock_at: null,
      }
      expect(generateDateDetailsPayload(cards, false, [])).toEqual(expectedPayload)
    })

    it('includes an unassigned override for any deleted module assignees', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['section-1'] as string[],
          defaultOptions: ['student-1'],
          due_at: '2021-01-01T00:00:00Z',
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [
          {
            due_at: '2021-01-01T00:00:00Z',
            id: undefined,
            lock_at: undefined,
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            course_section_id: '1',
            unlock_at: undefined,
            unassign_item: false,
          },
          {
            due_at: null,
            id: undefined,
            lock_at: null,
            reply_to_topic_due_at: null,
            required_replies_due_at: null,
            student_ids: ['1'],
            unlock_at: null,
            unassign_item: true,
          },
          {
            due_at: null,
            id: undefined,
            lock_at: null,
            reply_to_topic_due_at: null,
            required_replies_due_at: null,
            course_section_id: '2',
            unlock_at: null,
            unassign_item: true,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
        due_at: null,
        unlock_at: null,
        lock_at: null,
      }
      expect(generateDateDetailsPayload(cards, true, ['section-2', 'student-1'])).toEqual(
        expectedPayload,
      )
    })

    it('reuses existing unassigned override IDs for deleted module assignees', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['section-1'] as string[],
          defaultOptions: ['student-1'],
          due_at: '2021-01-01T00:00:00Z',
        } as ItemAssignToCardSpec,
      ]

      const existingUnassignedOverrides: DateDetailsOverride[] = [
        {
          id: '100',
          student_ids: ['1'],
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: true,
        },
        {
          id: '200',
          course_section_id: '2',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: true,
        },
      ]

      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [
          {
            due_at: '2021-01-01T00:00:00Z',
            id: undefined,
            lock_at: undefined,
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            course_section_id: '1',
            unlock_at: undefined,
            unassign_item: false,
          },
          {
            due_at: null,
            id: '100',
            lock_at: null,
            reply_to_topic_due_at: null,
            required_replies_due_at: null,
            student_ids: ['1'],
            unlock_at: null,
            unassign_item: true,
          },
          {
            due_at: null,
            id: '200',
            lock_at: null,
            reply_to_topic_due_at: null,
            required_replies_due_at: null,
            course_section_id: '2',
            unlock_at: null,
            unassign_item: true,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
        due_at: null,
        unlock_at: null,
        lock_at: null,
      }
      expect(
        generateDateDetailsPayload(
          cards,
          true,
          ['section-2', 'student-1'], // unassigned module assignees
          existingUnassignedOverrides,
        ),
      ).toEqual(expectedPayload)
    })

    it('creates new unassigned overrides when no matching existing override is found', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['section-1'] as string[],
          defaultOptions: ['student-1'],
          due_at: '2021-01-01T00:00:00Z',
        } as ItemAssignToCardSpec,
      ]

      const existingUnassignedOverrides: DateDetailsOverride[] = [
        {
          id: '100',
          student_ids: ['999'],
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: true,
        },
        {
          id: '200',
          course_section_id: '999',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: true,
        },
      ]

      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [
          {
            due_at: '2021-01-01T00:00:00Z',
            id: undefined,
            lock_at: undefined,
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            course_section_id: '1',
            unlock_at: undefined,
            unassign_item: false,
          },
          {
            due_at: null,
            id: undefined, // No matching override
            lock_at: null,
            reply_to_topic_due_at: null,
            required_replies_due_at: null,
            student_ids: ['1'],
            unlock_at: null,
            unassign_item: true,
          },
          {
            due_at: null,
            id: undefined, // No matching override
            lock_at: null,
            reply_to_topic_due_at: null,
            required_replies_due_at: null,
            course_section_id: '2',
            unlock_at: null,
            unassign_item: true,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
        due_at: null,
        unlock_at: null,
        lock_at: null,
      }
      expect(
        generateDateDetailsPayload(
          cards,
          true,
          ['section-2', 'student-1'], // unassigned module assignees
          existingUnassignedOverrides,
        ),
      ).toEqual(expectedPayload)
    })

    it('matches student unassigned overrides regardless of array order', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['section-1'] as string[],
          defaultOptions: ['student-1'],
          due_at: '2021-01-01T00:00:00Z',
        } as ItemAssignToCardSpec,
      ]

      const existingUnassignedOverrides: DateDetailsOverride[] = [
        {
          id: '100',
          student_ids: ['3', '2', '1'],
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: true,
        },
      ]

      const result = generateDateDetailsPayload(
        cards,
        true,
        ['student-1', 'student-2', 'student-3'],
        existingUnassignedOverrides,
      )

      const unassignedStudentOverride = result.assignment_overrides.find(
        o => o.unassign_item && o.student_ids,
      )
      expect(unassignedStudentOverride?.id).toBe('100') // Should match despite different order
    })

    it('only_visible_to_overrides is false if there are only module overrides', () => {
      const cards: ItemAssignToCardSpec[] = []
      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: false,
      }
      expect(generateDateDetailsPayload(cards, true, [])).toEqual(expectedPayload)
    })

    it('clears base dates when only_visible_to_overrides is true and no everyone card', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['section-1'] as string[],
          due_at: '2021-01-01T00:00:00Z',
          unlock_at: '2021-01-01T00:00:00Z',
          lock_at: '2021-01-03T00:00:00Z',
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        due_at: null,
        unlock_at: null,
        lock_at: null,
        assignment_overrides: [
          {
            due_at: '2021-01-01T00:00:00Z',
            id: undefined,
            lock_at: '2021-01-03T00:00:00Z',
            course_section_id: '1',
            unlock_at: '2021-01-01T00:00:00Z',
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            unassign_item: false,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
      }
      expect(generateDateDetailsPayload(cards, false, [])).toEqual(expectedPayload)
    })

    it('only_visible_to_overrides is true if there are module overrides and no everyone card', () => {
      const cards: ItemAssignToCardSpec[] = [
        {
          // Course override
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['everyone'] as string[],
          defaultOptions: ['everyone'],
          due_at: '2021-01-01T00:00:00Z',
        } as ItemAssignToCardSpec,
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['section-1'] as string[],
          defaultOptions: ['student-1'],
          due_at: '2021-01-01T00:00:00Z',
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [
          {
            due_at: '2021-01-01T00:00:00Z',
            id: '1',
            lock_at: undefined,
            course_id: 'everyone',
            unlock_at: undefined,
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            unassign_item: false,
          },
          {
            due_at: '2021-01-01T00:00:00Z',
            id: undefined,
            lock_at: undefined,
            course_section_id: '1',
            unlock_at: undefined,
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            unassign_item: false,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
      }
      expect(generateDateDetailsPayload(cards, true, [])).toEqual(expectedPayload)
    })

    it('returns ids for section overrides with the same default section', () => {
      // overrides should be overwritten not created if the default section is the same
      // and the override is not a module override.
      const cards: ItemAssignToCardSpec[] = [
        {
          overrideId: '1',
          isValid: true,
          hasAssignees: true,
          selectedAssigneeIds: ['section-1'] as string[],
          defaultOptions: ['section-1'],
          due_at: '2021-01-01T00:00:00Z',
        } as ItemAssignToCardSpec,
      ]
      const expectedPayload = <DateDetailsPayload>{
        assignment_overrides: [
          {
            due_at: '2021-01-01T00:00:00Z',
            id: '1',
            lock_at: undefined,
            course_section_id: '1',
            unlock_at: undefined,
            reply_to_topic_due_at: undefined,
            required_replies_due_at: undefined,
            unassign_item: false,
          },
        ] as unknown as DateDetailsOverride[],
        only_visible_to_overrides: true,
        due_at: null,
        unlock_at: null,
        lock_at: null,
      }
      expect(generateDateDetailsPayload(cards, true, [])).toEqual(expectedPayload)
    })

    describe('with PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED', () => {
      const originalENV = window.ENV

      beforeEach(() => {
        window.ENV = {
          ...originalENV,
          PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED: true,
        }
      })

      afterEach(() => {
        window.ENV = originalENV
      })

      it('includes peer review dates from everyone card in default payload with nested structure', () => {
        const cards: ItemAssignToCardSpec[] = [
          {
            key: '1',
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['everyone'],
            due_at: '2024-01-20T12:00:00Z',
            peer_review_available_from: '2024-01-15T12:00:00Z',
            peer_review_due_at: '2024-01-20T12:00:00Z',
            peer_review_available_to: '2024-01-25T12:00:00Z',
          } as ItemAssignToCardSpec,
        ]

        const payload = generateDateDetailsPayload(cards, false, [], [])

        expect(payload.peer_review).toBeDefined()
        expect(payload.peer_review?.due_at).toBe('2024-01-20T12:00:00Z')
        expect(payload.peer_review?.unlock_at).toBe('2024-01-15T12:00:00Z')
        expect(payload.peer_review?.lock_at).toBe('2024-01-25T12:00:00Z')
        expect(payload.peer_review?.peer_review_overrides).toEqual([])
      })

      it('includes peer review dates in section override as peer_review_overrides', () => {
        const cards: ItemAssignToCardSpec[] = [
          {
            overrideId: '1',
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['section-2'],
            due_at: '2024-01-20T12:00:00Z',
            peer_review_available_from: '2024-01-15T12:00:00Z',
            peer_review_due_at: '2024-01-20T12:00:00Z',
            peer_review_available_to: '2024-01-25T12:00:00Z',
          } as ItemAssignToCardSpec,
        ]

        const payload = generateDateDetailsPayload(cards, false, [], [])

        expect(payload.assignment_overrides).toHaveLength(1)
        expect(payload.assignment_overrides[0].course_section_id).toBe('2')
        expect(payload.peer_review?.peer_review_overrides).toHaveLength(1)
        expect(payload.peer_review?.peer_review_overrides?.[0].course_section_id).toBe('2')
        expect(payload.peer_review?.peer_review_overrides?.[0].unlock_at).toBe(
          '2024-01-15T12:00:00Z',
        )
        expect(payload.peer_review?.peer_review_overrides?.[0].due_at).toBe('2024-01-20T12:00:00Z')
        expect(payload.peer_review?.peer_review_overrides?.[0].lock_at).toBe('2024-01-25T12:00:00Z')
      })

      it('includes peer review dates in student override as peer_review_overrides', () => {
        const cards: ItemAssignToCardSpec[] = [
          {
            overrideId: '1',
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['student-123'],
            due_at: '2024-01-20T12:00:00Z',
            peer_review_available_from: '2024-01-15T12:00:00Z',
            peer_review_due_at: '2024-01-20T12:00:00Z',
            peer_review_available_to: '2024-01-25T12:00:00Z',
          } as ItemAssignToCardSpec,
        ]

        const payload = generateDateDetailsPayload(cards, false, [], [])

        expect(payload.assignment_overrides).toHaveLength(1)
        expect(payload.assignment_overrides[0].student_ids).toEqual(['123'])
        expect(payload.peer_review?.peer_review_overrides).toHaveLength(1)
        expect(payload.peer_review?.peer_review_overrides?.[0].student_ids).toEqual(['123'])
        expect(payload.peer_review?.peer_review_overrides?.[0].unlock_at).toBe(
          '2024-01-15T12:00:00Z',
        )
        expect(payload.peer_review?.peer_review_overrides?.[0].due_at).toBe('2024-01-20T12:00:00Z')
        expect(payload.peer_review?.peer_review_overrides?.[0].lock_at).toBe('2024-01-25T12:00:00Z')
      })

      it('includes peer review override_id when updating existing override', () => {
        const cards: ItemAssignToCardSpec[] = [
          {
            overrideId: '999',
            peer_review_override_id: '888',
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['section-2'],
            defaultOptions: ['section-2'],
            due_at: '2024-01-20T12:00:00Z',
            peer_review_due_at: '2024-01-20T12:00:00Z',
          } as ItemAssignToCardSpec,
        ]

        const payload = generateDateDetailsPayload(cards, false, [], [])

        expect(payload.assignment_overrides).toHaveLength(1)
        expect(payload.assignment_overrides[0].id).toBe('999')
        expect(payload.peer_review?.peer_review_overrides).toHaveLength(1)
        expect(payload.peer_review?.peer_review_overrides?.[0].id).toBe('888')
      })

      it('includes peer review dates in course override (Everyone else) as peer_review_overrides', () => {
        const cards: ItemAssignToCardSpec[] = [
          {
            overrideId: '1',
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['everyone'],
            defaultOptions: ['everyone'],
            due_at: '2024-01-20T12:00:00Z',
            peer_review_available_from: '2024-01-15T12:00:00Z',
            peer_review_due_at: '2024-01-20T12:00:00Z',
            peer_review_available_to: '2024-01-25T12:00:00Z',
          } as ItemAssignToCardSpec,
        ]

        const payload = generateDateDetailsPayload(cards, true, [], [])

        expect(payload.assignment_overrides).toHaveLength(1)
        expect(payload.assignment_overrides[0].course_id).toBe('everyone')
        expect(payload.peer_review?.peer_review_overrides).toHaveLength(1)
        expect(payload.peer_review?.peer_review_overrides?.[0].course_id).toBe('everyone')
        expect(payload.peer_review?.peer_review_overrides?.[0].unlock_at).toBe(
          '2024-01-15T12:00:00Z',
        )
        expect(payload.peer_review?.peer_review_overrides?.[0].due_at).toBe('2024-01-20T12:00:00Z')
        expect(payload.peer_review?.peer_review_overrides?.[0].lock_at).toBe('2024-01-25T12:00:00Z')
      })

      it('includes peer review dates in tag override (non-collaborative group) as peer_review_overrides', () => {
        const cards: ItemAssignToCardSpec[] = [
          {
            overrideId: undefined,
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['tag-456'],
            due_at: '2024-01-20T12:00:00Z',
            peer_review_available_from: '2024-01-15T12:00:00Z',
            peer_review_due_at: '2024-01-20T12:00:00Z',
            peer_review_available_to: '2024-01-25T12:00:00Z',
          } as ItemAssignToCardSpec,
        ]

        const payload = generateDateDetailsPayload(cards, false, [], [])

        expect(payload.assignment_overrides).toHaveLength(1)
        expect(payload.assignment_overrides[0].group_id).toBe('456')
        expect(payload.assignment_overrides[0].non_collaborative).toBe(true)
        expect(payload.peer_review?.peer_review_overrides).toHaveLength(1)
        expect(payload.peer_review?.peer_review_overrides?.[0].group_id).toBe('456')
        expect(payload.peer_review?.peer_review_overrides?.[0].unlock_at).toBe(
          '2024-01-15T12:00:00Z',
        )
        expect(payload.peer_review?.peer_review_overrides?.[0].due_at).toBe('2024-01-20T12:00:00Z')
        expect(payload.peer_review?.peer_review_overrides?.[0].lock_at).toBe('2024-01-25T12:00:00Z')
      })

      it('updates existing tag override with peer review dates', () => {
        const cards: ItemAssignToCardSpec[] = [
          {
            overrideId: '789',
            peer_review_override_id: '999',
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['tag-123'],
            defaultOptions: ['tag-123'],
            due_at: '2024-01-20T12:00:00Z',
            peer_review_due_at: '2024-01-21T12:00:00Z',
          } as ItemAssignToCardSpec,
        ]

        const payload = generateDateDetailsPayload(cards, false, [], [])

        expect(payload.assignment_overrides).toHaveLength(1)
        expect(payload.assignment_overrides[0].id).toBe('789')
        expect(payload.assignment_overrides[0].group_id).toBe('123')
        expect(payload.assignment_overrides[0].non_collaborative).toBe(true)
        expect(payload.peer_review?.peer_review_overrides).toHaveLength(1)
        expect(payload.peer_review?.peer_review_overrides?.[0].id).toBe('999')
        expect(payload.peer_review?.peer_review_overrides?.[0].due_at).toBe('2024-01-21T12:00:00Z')
      })

      it('handles section and tag on different cards with different peer review dates', () => {
        const cards: ItemAssignToCardSpec[] = [
          {
            overrideId: undefined,
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['section-2'],
            due_at: '2024-01-20T12:00:00Z',
            peer_review_due_at: '2024-01-22T12:00:00Z',
          } as ItemAssignToCardSpec,
          {
            overrideId: undefined,
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['tag-5'],
            due_at: '2024-01-20T12:00:00Z',
            peer_review_due_at: '2024-01-23T12:00:00Z',
          } as ItemAssignToCardSpec,
        ]

        const payload = generateDateDetailsPayload(cards, false, [], [])

        expect(payload.assignment_overrides).toHaveLength(2)
        expect(payload.peer_review?.peer_review_overrides).toHaveLength(2)

        const sectionPeerReview = payload.peer_review?.peer_review_overrides?.find(
          o => o.course_section_id === '2',
        )
        const tagPeerReview = payload.peer_review?.peer_review_overrides?.find(
          o => o.group_id === '5',
        )

        expect(sectionPeerReview?.due_at).toBe('2024-01-22T12:00:00Z')
        expect(tagPeerReview?.due_at).toBe('2024-01-23T12:00:00Z')
      })

      it('returns flattened format when keepFlattenedFormat option is true', () => {
        const cards: ItemAssignToCardSpec[] = [
          {
            key: '1',
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['section-2'],
            due_at: '2024-01-20T12:00:00Z',
            peer_review_due_at: '2024-01-20T12:00:00Z',
            peer_review_available_from: '2024-01-15T12:00:00Z',
            peer_review_available_to: '2024-01-25T12:00:00Z',
          } as ItemAssignToCardSpec,
        ]

        const payload = generateDateDetailsPayload(cards, false, [], [], {
          keepFlattenedFormat: true,
        })

        expect(payload.assignment_overrides).toHaveLength(1)
        expect(payload.assignment_overrides[0].peer_review_due_at).toBe('2024-01-20T12:00:00Z')
        expect(payload.assignment_overrides[0].peer_review_available_from).toBe(
          '2024-01-15T12:00:00Z',
        )
        expect(payload.assignment_overrides[0].peer_review_available_to).toBe(
          '2024-01-25T12:00:00Z',
        )
      })

      it('merges peer review default dates with overrides', () => {
        const cards: ItemAssignToCardSpec[] = [
          {
            key: '1',
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['everyone'],
            due_at: '2024-01-20T12:00:00Z',
            peer_review_due_at: '2024-01-20T12:00:00Z',
            peer_review_available_from: '2024-01-15T12:00:00Z',
            peer_review_available_to: '2024-01-25T12:00:00Z',
          } as ItemAssignToCardSpec,
          {
            key: '2',
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['section-2'],
            due_at: '2024-01-22T12:00:00Z',
            peer_review_due_at: '2024-01-22T12:00:00Z',
          } as ItemAssignToCardSpec,
        ]

        const payload = generateDateDetailsPayload(cards, false, [], [])

        expect(payload.peer_review?.due_at).toBe('2024-01-20T12:00:00Z')
        expect(payload.peer_review?.unlock_at).toBe('2024-01-15T12:00:00Z')
        expect(payload.peer_review?.lock_at).toBe('2024-01-25T12:00:00Z')

        expect(payload.peer_review?.peer_review_overrides).toHaveLength(1)
        expect(payload.peer_review?.peer_review_overrides?.[0].course_section_id).toBe('2')
        expect(payload.peer_review?.peer_review_overrides?.[0].due_at).toBe('2024-01-22T12:00:00Z')
      })

      it('uses extracted peer review data when no everyoneCard peer review dates exist', () => {
        const cards: ItemAssignToCardSpec[] = [
          {
            key: '1',
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['everyone'],
            due_at: '2024-01-20T12:00:00Z',
          } as ItemAssignToCardSpec,
          {
            key: '2',
            isValid: true,
            hasAssignees: true,
            selectedAssigneeIds: ['section-2'],
            due_at: '2024-01-22T12:00:00Z',
            peer_review_due_at: '2024-01-22T12:00:00Z',
          } as ItemAssignToCardSpec,
        ]

        const payload = generateDateDetailsPayload(cards, false, [], [])

        expect(payload.peer_review?.due_at).toBeNull()
        expect(payload.peer_review?.unlock_at).toBeNull()
        expect(payload.peer_review?.lock_at).toBeNull()

        expect(payload.peer_review?.peer_review_overrides).toHaveLength(1)
        expect(payload.peer_review?.peer_review_overrides?.[0].due_at).toBe('2024-01-22T12:00:00Z')
      })
    })
  })

  describe('flattenPeerReviewDates', () => {
    it('flattens peer_review_dates object into flat fields', () => {
      const input: BackendDateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '456',
          peer_review_dates: {
            id: '789',
            due_at: '2024-01-20T12:00:00Z',
            unlock_at: '2024-01-15T12:00:00Z',
            lock_at: '2024-01-25T12:00:00Z',
          },
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = flattenPeerReviewDates(input)

      expect(result[0]).toEqual({
        id: '123',
        course_section_id: '456',
        peer_review_override_id: '789',
        peer_review_due_at: '2024-01-20T12:00:00Z',
        peer_review_available_from: '2024-01-15T12:00:00Z',
        peer_review_available_to: '2024-01-25T12:00:00Z',
        due_at: null,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      })
      expect(result[0]).not.toHaveProperty('peer_review_dates')
    })

    it('passes through overrides without peer_review_dates unchanged', () => {
      const input: BackendDateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '456',
          peer_review_override_id: '789',
          peer_review_due_at: '2024-01-20T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = flattenPeerReviewDates(input)

      expect(result[0]).toEqual(input[0])
    })

    it('handles an empty array', () => {
      const result = flattenPeerReviewDates([])
      expect(result).toEqual([])
    })
  })

  describe('markPeerReviewDefaultDates', () => {
    it('marks default section override as having default dates', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '1',
          peer_review_due_at: '2024-01-20T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = markPeerReviewDefaultDates(overrides, '1')

      expect(result[0].peer_review_default_dates).toBe(true)
    })

    it('does not mark course override as having default dates', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '1',
          course_id: '456',
          peer_review_due_at: '2024-01-20T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = markPeerReviewDefaultDates(overrides, '1')

      expect(result[0].peer_review_default_dates).toBeUndefined()
    })

    it('does not mark non-default section override', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '2',
          peer_review_due_at: '2024-01-20T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = markPeerReviewDefaultDates(overrides, '1')

      expect(result[0].peer_review_default_dates).toBeUndefined()
    })

    it('does not mark student override', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          student_ids: ['456'],
          peer_review_due_at: '2024-01-20T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = markPeerReviewDefaultDates(overrides, '1')

      expect(result[0].peer_review_default_dates).toBeUndefined()
    })

    it('does not mark group override (collaborative group)', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          group_id: '789',
          peer_review_due_at: '2024-01-20T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = markPeerReviewDefaultDates(overrides, '1')

      expect(result[0].peer_review_default_dates).toBeUndefined()
    })

    it('does not mark tag override (non-collaborative group)', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          group_id: '789',
          non_collaborative: true,
          peer_review_due_at: '2024-01-20T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = markPeerReviewDefaultDates(overrides, '1')

      expect(result[0].peer_review_default_dates).toBeUndefined()
    })
  })

  describe('getAssignmentOverride', () => {
    it('removes all peer review-specific fields', () => {
      const override: DateDetailsOverride = {
        id: '123',
        course_section_id: '456',
        due_at: '2024-01-20T12:00:00Z',
        peer_review_override_id: '789',
        peer_review_available_from: '2024-01-15T12:00:00Z',
        peer_review_due_at: '2024-01-20T12:00:00Z',
        peer_review_available_to: '2024-01-25T12:00:00Z',
        peer_review_default_dates: true,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }

      const result = getAssignmentOverride(override)

      expect(result).toEqual({
        id: '123',
        course_section_id: '456',
        due_at: '2024-01-20T12:00:00Z',
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      })
      expect(result).not.toHaveProperty('peer_review_override_id')
      expect(result).not.toHaveProperty('peer_review_available_from')
      expect(result).not.toHaveProperty('peer_review_due_at')
      expect(result).not.toHaveProperty('peer_review_available_to')
      expect(result).not.toHaveProperty('peer_review_default_dates')
    })
  })

  describe('getDefaultPeerReviewDates', () => {
    it('extracts peer review dates from flat fields', () => {
      const payload: DateDetailsOverride = {
        peer_review_available_from: '2024-01-15T12:00:00Z',
        peer_review_due_at: '2024-01-20T12:00:00Z',
        peer_review_available_to: '2024-01-25T12:00:00Z',
        due_at: null,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }

      const result = getDefaultPeerReviewDates(payload)

      expect(result).toEqual({
        unlock_at: '2024-01-15T12:00:00Z',
        due_at: '2024-01-20T12:00:00Z',
        lock_at: '2024-01-25T12:00:00Z',
      })
    })

    it('handles null/undefined dates', () => {
      const payload: DateDetailsOverride = {
        peer_review_available_from: null,
        peer_review_due_at: undefined,
        peer_review_available_to: null,
        due_at: null,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }

      const result = getDefaultPeerReviewDates(payload)

      expect(result).toEqual({
        unlock_at: null,
        due_at: undefined,
        lock_at: null,
      })
    })
  })

  describe('hasPeerReviewOverrideDates', () => {
    it('returns true when peer_review_due_at is set', () => {
      const override: DateDetailsOverride = {
        peer_review_due_at: '2024-01-20T12:00:00Z',
        due_at: null,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }
      expect(hasPeerReviewOverrideDates(override)).toBe(true)
    })

    it('returns true when peer_review_available_from is set', () => {
      const override: DateDetailsOverride = {
        peer_review_available_from: '2024-01-15T12:00:00Z',
        due_at: null,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }
      expect(hasPeerReviewOverrideDates(override)).toBe(true)
    })

    it('returns true when peer_review_available_to is set', () => {
      const override: DateDetailsOverride = {
        peer_review_available_to: '2024-01-25T12:00:00Z',
        due_at: null,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }
      expect(hasPeerReviewOverrideDates(override)).toBe(true)
    })

    it('returns false when no peer review dates are set', () => {
      const override: DateDetailsOverride = {
        due_at: '2024-01-20T12:00:00Z',
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }
      expect(hasPeerReviewOverrideDates(override)).toBe(false)
    })
  })

  describe('getPeerReviewOverride', () => {
    it('creates peer review override for section', () => {
      const override: DateDetailsOverride = {
        peer_review_override_id: '789',
        course_section_id: '456',
        peer_review_due_at: '2024-01-20T12:00:00Z',
        peer_review_available_from: '2024-01-15T12:00:00Z',
        peer_review_available_to: '2024-01-25T12:00:00Z',
        due_at: null,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }

      const result = getPeerReviewOverride(override)

      expect(result).toEqual({
        id: '789',
        course_section_id: '456',
        student_ids: undefined,
        course_id: undefined,
        group_id: undefined,
        due_at: '2024-01-20T12:00:00Z',
        unlock_at: '2024-01-15T12:00:00Z',
        lock_at: '2024-01-25T12:00:00Z',
        unassign_item: false,
      })
    })

    it('creates peer review override for students', () => {
      const override: DateDetailsOverride = {
        student_ids: ['123', '456'],
        peer_review_due_at: '2024-01-20T12:00:00Z',
        peer_review_available_from: null,
        peer_review_available_to: null,
        due_at: null,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }

      const result = getPeerReviewOverride(override)

      expect(result.student_ids).toEqual(['123', '456'])
      expect(result.due_at).toBe('2024-01-20T12:00:00Z')
      expect(result.unlock_at).toBeNull()
      expect(result.lock_at).toBeNull()
    })

    it('creates peer review override for course', () => {
      const override: DateDetailsOverride = {
        course_section_id: '1',
        course_id: '456',
        peer_review_due_at: '2024-01-20T12:00:00Z',
        due_at: null,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }

      const result = getPeerReviewOverride(override)

      expect(result.course_id).toBe('456')
      expect(result.course_section_id).toBe('1')
    })

    it('creates peer review override for group (collaborative group)', () => {
      const override: DateDetailsOverride = {
        group_id: '555',
        peer_review_override_id: '777',
        peer_review_due_at: '2024-01-20T12:00:00Z',
        peer_review_available_from: '2024-01-15T12:00:00Z',
        peer_review_available_to: '2024-01-25T12:00:00Z',
        due_at: null,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }

      const result = getPeerReviewOverride(override)

      expect(result).toEqual({
        id: '777',
        course_section_id: undefined,
        student_ids: undefined,
        course_id: undefined,
        group_id: '555',
        non_collaborative: undefined,
        due_at: '2024-01-20T12:00:00Z',
        unlock_at: '2024-01-15T12:00:00Z',
        lock_at: '2024-01-25T12:00:00Z',
        unassign_item: false,
      })
    })

    it('creates peer review override for tag (non-collaborative group)', () => {
      const override: DateDetailsOverride = {
        group_id: '789',
        non_collaborative: true,
        peer_review_override_id: '888',
        peer_review_due_at: '2024-01-20T12:00:00Z',
        peer_review_available_from: '2024-01-15T12:00:00Z',
        peer_review_available_to: '2024-01-25T12:00:00Z',
        due_at: null,
        unlock_at: null,
        lock_at: null,
        reply_to_topic_due_at: null,
        required_replies_due_at: null,
        unassign_item: false,
      }

      const result = getPeerReviewOverride(override)

      expect(result).toEqual({
        id: '888',
        course_section_id: undefined,
        student_ids: undefined,
        course_id: undefined,
        group_id: '789',
        due_at: '2024-01-20T12:00:00Z',
        unlock_at: '2024-01-15T12:00:00Z',
        lock_at: '2024-01-25T12:00:00Z',
        unassign_item: false,
      })
    })
  })

  describe('getAssignmentAndPeerReviewOverrides', () => {
    it('extracts default peer review dates from default section override', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '1',
          due_at: '2024-01-20T12:00:00Z',
          peer_review_default_dates: true,
          peer_review_available_from: '2024-01-15T12:00:00Z',
          peer_review_due_at: '2024-01-20T12:00:00Z',
          peer_review_available_to: '2024-01-25T12:00:00Z',
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.assignmentOverrides).toHaveLength(1)
      expect(result.assignmentOverrides[0]).not.toHaveProperty('peer_review_due_at')
      expect(result.peerReview).toEqual({
        unlock_at: '2024-01-15T12:00:00Z',
        due_at: '2024-01-20T12:00:00Z',
        lock_at: '2024-01-25T12:00:00Z',
        peer_review_overrides: [],
      })
    })

    it('creates peer_review_overrides array for section overrides', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '2',
          peer_review_due_at: '2024-01-20T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
        {
          id: '124',
          course_section_id: '3',
          peer_review_due_at: '2024-01-21T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.assignmentOverrides).toHaveLength(2)
      expect(result.peerReview?.peer_review_overrides).toHaveLength(2)
      expect(result.peerReview?.peer_review_overrides?.[0].course_section_id).toBe('2')
      expect(result.peerReview?.peer_review_overrides?.[1].course_section_id).toBe('3')
    })

    it('creates peer review override for course override', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '1',
          course_id: '456',
          peer_review_due_at: '2024-01-20T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.peerReview?.peer_review_overrides).toHaveLength(1)
      expect(result.peerReview?.peer_review_overrides?.[0].course_id).toBe('456')
    })

    it('does not create peer review override when no dates are set', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '2',
          due_at: '2024-01-20T12:00:00Z',
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.assignmentOverrides).toHaveLength(1)
      expect(result.peerReview).toEqual({
        due_at: null,
        unlock_at: null,
        lock_at: null,
        peer_review_overrides: [],
      })
    })

    it('returns peerReview with empty overrides when no peer review data exists', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '2',
          due_at: '2024-01-20T12:00:00Z',
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.peerReview).toEqual({
        due_at: null,
        unlock_at: null,
        lock_at: null,
        peer_review_overrides: [],
      })
    })

    it('creates peer review override for student override', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          student_ids: ['456', '789'],
          peer_review_due_at: '2024-01-20T12:00:00Z',
          peer_review_available_from: '2024-01-15T12:00:00Z',
          peer_review_available_to: '2024-01-25T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.assignmentOverrides).toHaveLength(1)
      expect(result.assignmentOverrides[0]).not.toHaveProperty('peer_review_due_at')
      expect(result.peerReview?.peer_review_overrides).toHaveLength(1)
      expect(result.peerReview?.peer_review_overrides?.[0].student_ids).toEqual(['456', '789'])
      expect(result.peerReview?.peer_review_overrides?.[0].due_at).toBe('2024-01-20T12:00:00Z')
    })

    it('creates peer review override for group override (collaborative group)', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          group_id: '555',
          peer_review_due_at: '2024-01-20T12:00:00Z',
          peer_review_available_from: '2024-01-15T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.assignmentOverrides).toHaveLength(1)
      expect(result.assignmentOverrides[0]).not.toHaveProperty('peer_review_due_at')
      expect(result.peerReview?.peer_review_overrides).toHaveLength(1)
      expect(result.peerReview?.peer_review_overrides?.[0].group_id).toBe('555')
      expect(result.peerReview?.peer_review_overrides?.[0]).not.toHaveProperty('non_collaborative')
      expect(result.peerReview?.peer_review_overrides?.[0].due_at).toBe('2024-01-20T12:00:00Z')
    })

    it('creates peer review override for tag override (non-collaborative group)', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          group_id: '789',
          non_collaborative: true,
          peer_review_due_at: '2024-01-20T12:00:00Z',
          peer_review_available_to: '2024-01-25T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.assignmentOverrides).toHaveLength(1)
      expect(result.assignmentOverrides[0]).not.toHaveProperty('peer_review_due_at')
      expect(result.peerReview?.peer_review_overrides).toHaveLength(1)
      expect(result.peerReview?.peer_review_overrides?.[0].group_id).toBe('789')
      expect(result.peerReview?.peer_review_overrides?.[0]).not.toHaveProperty('non_collaborative')
      expect(result.peerReview?.peer_review_overrides?.[0].due_at).toBe('2024-01-20T12:00:00Z')
    })

    it('sets top-level dates to null when there are overrides but no everyone override', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          student_ids: ['456', '789'],
          peer_review_due_at: '2024-01-20T12:00:00Z',
          peer_review_available_from: '2024-01-15T12:00:00Z',
          peer_review_available_to: '2024-01-25T12:00:00Z',
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.peerReview?.peer_review_overrides).toHaveLength(1)
      expect(result.peerReview?.due_at).toBeNull()
      expect(result.peerReview?.unlock_at).toBeNull()
      expect(result.peerReview?.lock_at).toBeNull()
    })

    it('sends empty peer_review_overrides when existing override has all dates cleared', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '2',
          peer_review_override_id: '456',
          peer_review_due_at: null,
          peer_review_available_from: null,
          peer_review_available_to: null,
          due_at: null,
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.assignmentOverrides).toHaveLength(1)
      expect(result.peerReview).toBeDefined()
      expect(result.peerReview?.peer_review_overrides).toEqual([])
      expect(result.peerReview?.due_at).toBeNull()
      expect(result.peerReview?.unlock_at).toBeNull()
      expect(result.peerReview?.lock_at).toBeNull()
    })

    it('sends empty peer_review_overrides when multiple existing overrides have dates cleared', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '2',
          peer_review_override_id: '456',
          peer_review_due_at: null,
          peer_review_available_from: null,
          peer_review_available_to: null,
          due_at: '2024-01-20T12:00:00Z',
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
        {
          id: '124',
          student_ids: ['789'],
          peer_review_override_id: '789',
          peer_review_due_at: null,
          peer_review_available_from: null,
          peer_review_available_to: null,
          due_at: '2024-01-21T12:00:00Z',
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.assignmentOverrides).toHaveLength(2)
      expect(result.peerReview?.peer_review_overrides).toEqual([])
    })

    it('includes only overrides with dates when some are cleared and some have dates', () => {
      const overrides: DateDetailsOverride[] = [
        {
          id: '123',
          course_section_id: '2',
          peer_review_override_id: '456',
          peer_review_due_at: null,
          peer_review_available_from: null,
          peer_review_available_to: null,
          due_at: '2024-01-20T12:00:00Z',
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
        {
          id: '124',
          course_section_id: '3',
          peer_review_override_id: '789',
          peer_review_due_at: '2024-01-25T12:00:00Z',
          peer_review_available_from: null,
          peer_review_available_to: null,
          due_at: '2024-01-21T12:00:00Z',
          unlock_at: null,
          lock_at: null,
          reply_to_topic_due_at: null,
          required_replies_due_at: null,
          unassign_item: false,
        },
      ]

      const result = getAssignmentAndPeerReviewOverrides(overrides)

      expect(result.assignmentOverrides).toHaveLength(2)
      expect(result.peerReview?.peer_review_overrides).toHaveLength(1)
      expect(result.peerReview?.peer_review_overrides?.[0].course_section_id).toBe('3')
      expect(result.peerReview?.peer_review_overrides?.[0].due_at).toBe('2024-01-25T12:00:00Z')
    })
  })
})
