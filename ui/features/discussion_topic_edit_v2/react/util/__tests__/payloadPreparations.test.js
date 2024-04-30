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

import {defaultEveryoneElseOption, defaultEveryoneOption, masteryPathsOption} from '../constants'
import {prepareUngradedDiscussionOverridesPayload} from '../payloadPreparations'

describe('prepareUngradedDiscussionOverridesPayload', () => {
  it('returns payload only for everyone', () => {
    const assignedInfoList = [
      {
        assignedList: ['everyone'],
        dueDate: '2024-04-15T00:00:00.000Z',
        availableFrom: '2024-04-10T00:00:00.000Z',
        availableUntil: '2024-04-20T00:00:00.000Z',
      },
    ]
    const payload = prepareUngradedDiscussionOverridesPayload(
      assignedInfoList,
      defaultEveryoneOption,
      defaultEveryoneElseOption,
      masteryPathsOption
    )
    expect(payload).toEqual({
      delayedPostAt: '2024-04-10T00:00:00.000Z',
      dueAt: '2024-04-15T00:00:00.000Z',
      lockAt: '2024-04-20T00:00:00.000Z',
      onlyVisibleToOverrides: false,
      ungradedDiscussionOverrides: null,
    })
  })

  it('returns payload for sections', () => {
    const assignedInfoList = [
      {
        assignedList: ['course_section_2'],
        dueDate: null,
        availableFrom: '2024-04-10T00:00:00.000Z',
        availableUntil: '2024-04-20T00:00:00.000Z',
      },
    ]
    const payload = prepareUngradedDiscussionOverridesPayload(
      assignedInfoList,
      defaultEveryoneOption,
      defaultEveryoneElseOption,
      masteryPathsOption
    )
    expect(payload).toEqual({
      delayedPostAt: null,
      dueAt: null,
      lockAt: null,
      onlyVisibleToOverrides: true,
      ungradedDiscussionOverrides: [
        {
          courseId: null,
          courseSectionId: '2',
          dueAt: null,
          groupId: null,
          lockAt: '2024-04-20T00:00:00.000Z',
          noopId: null,
          studentIds: null,
          title: null,
          unassignItem: false,
          unlockAt: '2024-04-10T00:00:00.000Z',
        },
      ],
    })
  })

  it('returns payload for section and everyone else', () => {
    const assignedInfoList = [
      {
        assignedList: ['course_section_2'],
        dueDate: null,
        availableFrom: '2024-04-10T00:00:00.000Z',
        availableUntil: '2024-04-20T00:00:00.000Z',
      },
      {
        assignedList: ['everyone'],
        dueDate: '2024-04-15T00:00:00.000Z',
        availableFrom: '2024-04-10T00:00:00.000Z',
        availableUntil: '2024-04-20T00:00:00.000Z',
      },
    ]
    const payload = prepareUngradedDiscussionOverridesPayload(
      assignedInfoList,
      defaultEveryoneOption,
      defaultEveryoneElseOption,
      masteryPathsOption
    )
    expect(payload).toEqual({
      delayedPostAt: '2024-04-10T00:00:00.000Z',
      dueAt: '2024-04-15T00:00:00.000Z',
      lockAt: '2024-04-20T00:00:00.000Z',
      onlyVisibleToOverrides: false,
      ungradedDiscussionOverrides: [
        {
          courseId: null,
          courseSectionId: '2',
          dueAt: null,
          groupId: null,
          lockAt: '2024-04-20T00:00:00.000Z',
          noopId: null,
          studentIds: null,
          title: null,
          unassignItem: false,
          unlockAt: '2024-04-10T00:00:00.000Z',
        },
      ],
    })
  })
})
