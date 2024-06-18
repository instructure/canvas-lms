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
} from '../../react/Item/types'
import {generateDateDetailsPayload} from '../assignToHelper'

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
          due_at: null,
          id: undefined,
          lock_at: null,
          noop_id: 1,
          unlock_at: null,
          title: 'Mastery Paths',
          unassign_item: false,
        },
      ] as unknown as DateDetailsOverride[],
      only_visible_to_overrides: true,
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
          lock_at: null,
          course_id: 'everyone',
          unlock_at: null,
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
          due_at: null,
          id: undefined,
          lock_at: null,
          course_id: 'everyone',
          unlock_at: null,
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
    }
    expect(generateDateDetailsPayload(cards, true, [])).toEqual(expectedPayload)
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
          course_section_id: '1',
          unlock_at: undefined,
          unassign_item: false,
        },
        {
          due_at: null,
          id: undefined,
          lock_at: null,
          student_ids: ['1'],
          unlock_at: null,
          unassign_item: true,
        },
        {
          due_at: null,
          id: undefined,
          lock_at: null,
          course_section_id: '2',
          unlock_at: null,
          unassign_item: true,
        },
      ] as unknown as DateDetailsOverride[],
      only_visible_to_overrides: true,
    }
    expect(generateDateDetailsPayload(cards, true, ['section-2', 'student-1'])).toEqual(
      expectedPayload
    )
  })

  it('only_visible_to_overrides is false if there are only module overrides', () => {
    const cards: ItemAssignToCardSpec[] = []
    const expectedPayload = <DateDetailsPayload>{
      assignment_overrides: [] as unknown as DateDetailsOverride[],
      only_visible_to_overrides: false,
    }
    expect(generateDateDetailsPayload(cards, true, [])).toEqual(expectedPayload)
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
          lock_at: null,
          course_id: 'everyone',
          unlock_at: null,
          unassign_item: false,
        },
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
    }
    expect(generateDateDetailsPayload(cards, true, [])).toEqual(expectedPayload)
  })
})
