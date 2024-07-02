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
import {
  prepareUngradedDiscussionOverridesPayload,
  convertToCheckpointsData,
} from '../payloadPreparations'

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

describe('convertToCheckpointsData', () => {
  it('returns payload multiple assignee types', () => {
    const assignedInfoList = [
      {
        dueDateId: '4',
        assignedList: ['user_17', 'user_35', 'user_20'],
        replyToTopicDueDate: '2024-07-19T05:59:00.000Z',
        requiredRepliesDueDate: '2024-07-20T05:59:00.000Z',
        dueDate: null,
        availableFrom: '2024-07-16T06:00:00.000Z',
        availableUntil: '2024-07-21T05:59:00.000Z',
        unassignItem: false,
        context_module_id: null,
        context_module_name: null,
        stagedOverrideId: 'ufxVuamCDDk2',
        rowKey: '4',
      },
      {
        dueDateId: '6MYPvf68JHKH4u4kGbpav',
        assignedList: ['course_section_197'],
        replyToTopicDueDate: '2024-07-12T05:59:00.000Z',
        requiredRepliesDueDate: '2024-07-13T05:59:00.000Z',
        dueDate: null,
        availableFrom: '2024-07-09T06:00:00.000Z',
        availableUntil: '2024-07-14T05:59:00.000Z',
        unassignItem: false,
        context_module_id: null,
        context_module_name: null,
        stagedOverrideId: 'ufpeGx3umU3a',
        rowKey: '6MYPvf68JHKH4u4kGbpav',
      },
      {
        dueDateId: '6MYPvf68JHKH4u4kGbpav',
        assignedList: ['course_section_10'],
        replyToTopicDueDate: '2024-07-12T05:59:00.000Z',
        requiredRepliesDueDate: '2024-07-13T05:59:00.000Z',
        dueDate: null,
        availableFrom: '2024-07-09T06:00:00.000Z',
        availableUntil: '2024-07-14T05:59:00.000Z',
        unassignItem: false,
        context_module_id: null,
        context_module_name: null,
        stagedOverrideId: 'uLVOgmOHmLLn',
        rowKey: '6MYPvf68JHKH4u4kGbpav',
      },
    ]

    const expected_result = [
      {
        checkpoint_label: 'reply_to_topic',
        dates: [
          {
            dueAt: '2024-07-19T05:59:00.000Z',
            lockAt: '2024-07-21T05:59:00.000Z',
            setType: 'ADHOC',
            studentIds: [17, 35, 20],
            type: 'override',
            unlockAt: '2024-07-16T06:00:00.000Z',
          },
          {
            dueAt: '2024-07-12T05:59:00.000Z',
            lockAt: '2024-07-14T05:59:00.000Z',
            setId: 197,
            setType: 'CourseSection',
            type: 'override',
            unlockAt: '2024-07-09T06:00:00.000Z',
          },
          {
            dueAt: '2024-07-12T05:59:00.000Z',
            lockAt: '2024-07-14T05:59:00.000Z',
            setId: 10,
            setType: 'CourseSection',
            type: 'override',
            unlockAt: '2024-07-09T06:00:00.000Z',
          },
        ],
      },
      {
        checkpoint_label: 'reply_to_entry',
        dates: [
          {
            dueAt: '2024-07-20T05:59:00.000Z',
            lockAt: '2024-07-21T05:59:00.000Z',
            setType: 'ADHOC',
            studentIds: [17, 35, 20],
            type: 'override',
            unlockAt: '2024-07-16T06:00:00.000Z',
          },
          {
            dueAt: '2024-07-13T05:59:00.000Z',
            lockAt: '2024-07-14T05:59:00.000Z',
            setId: 197,
            setType: 'CourseSection',
            type: 'override',
            unlockAt: '2024-07-09T06:00:00.000Z',
          },
          {
            dueAt: '2024-07-13T05:59:00.000Z',
            lockAt: '2024-07-14T05:59:00.000Z',
            setId: 10,
            setType: 'CourseSection',
            type: 'override',
            unlockAt: '2024-07-09T06:00:00.000Z',
          },
        ],
      },
    ]

    const payload = convertToCheckpointsData(assignedInfoList)
    expect(payload).toEqual(expected_result)
  })

  it('returns payload for empty assign to tray', () => {
    const assignedInfoList = [
      {
        dueDateId: 'OzGie8Lw-oQntWhDdwN4U',
        assignedList: ['everyone'],
        dueDate: '',
        availableFrom: '',
        availableUntil: '',
      },
    ]

    const expected_result = [
      {
        checkpoint_label: 'reply_to_topic',
        dates: [
          {
            type: 'everyone',
            dueAt: null,
            unlockAt: null,
            lockAt: null,
          },
        ],
      },
      {
        checkpoint_label: 'reply_to_entry',
        dates: [
          {
            type: 'everyone',
            dueAt: null,
            unlockAt: null,
            lockAt: null,
          },
        ],
      },
    ]

    const payload = convertToCheckpointsData(assignedInfoList)
    expect(payload).toEqual(expected_result)
  })
})
