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

import {
  type DateDetailsPayload,
  type ItemAssignToCardSpec,
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
      unlock_at: null,
      lock_at: null,
      assignment_overrides: [] as DateDetailsOverride[],
      only_visible_to_overrides: false,
    }
    expect(generateDateDetailsPayload(cards)).toEqual(expectedPayload)
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
        },
      ] as unknown as DateDetailsOverride[],
      only_visible_to_overrides: true,
    }
    expect(generateDateDetailsPayload(cards)).toEqual(expectedPayload)
  })
})
