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

import {buildAssignmentOverrides, buildDefaultAssignmentOverride} from '../utils'
import {DiscussionTopic} from '../../../graphql/DiscussionTopic'
import {Assignment} from '../../../graphql/Assignment'
import {AssignmentOverride} from '../../../graphql/AssignmentOverride'

describe('buildDefaultAssignmentOverride', () => {
  it('returns default object', () => {
    const overrides = buildDefaultAssignmentOverride()
    expect(overrides).toEqual([
      {
        dueDateId: expect.any(String),
        assignedList: ['everyone'],
        dueDate: '',
        availableFrom: '',
        availableUntil: '',
      },
    ])
  })
})

describe('buildAssignmentOverrides', () => {
  it('returns default for null assignment or no ungraded overrides', () => {
    const discussion = DiscussionTopic.mock()

    const overrides = buildAssignmentOverrides(discussion)
    expect(overrides).toEqual([])
  })

  describe('for graded assignments', () => {
    it('returns overrides when onlyVisibleToOverrides is true', () => {
      const assignment = Assignment.mock({onlyVisibleToOverrides: true})
      const discussion = DiscussionTopic.mock()

      assignment.assignmentOverrides = {nodes: [AssignmentOverride.mock()]}
      discussion.assignment = assignment

      const overrides = buildAssignmentOverrides(discussion)
      expect(overrides).toEqual([
        {
          assignedList: ['course_section_1'],
          availableFrom: '2020-01-01',
          availableUntil: '2020-01-01',
          dueDate: '2020-01-01',
          dueDateId: expect.any(String),
          unassignItem: false,
        },
      ])
    })

    it('returns overrides when visibleToEveryone is false', () => {
      const assignment = Assignment.mock({visibleToEveryone: false})
      const discussion = DiscussionTopic.mock()

      assignment.assignmentOverrides = {nodes: [AssignmentOverride.mock()]}
      discussion.assignment = assignment

      const overrides = buildAssignmentOverrides(discussion)
      expect(overrides).toEqual([
        {
          assignedList: ['course_section_1'],
          availableFrom: '2020-01-01',
          availableUntil: '2020-01-01',
          dueDate: '2020-01-01',
          dueDateId: expect.any(String),
          unassignItem: false,
        },
      ])
    })

    it('returns overrides when it has course overrides', () => {
      const assignment = Assignment.mock()
      const discussion = DiscussionTopic.mock()

      assignment.assignmentOverrides = {
        nodes: [
          AssignmentOverride.mock({
            set: {
              __typename: 'Course',
              id: '1',
              name: 'Course Name',
              _id: '1',
            },
          }),
        ],
      }
      discussion.assignment = assignment

      const overrides = buildAssignmentOverrides(discussion)
      expect(overrides).toEqual([
        {
          assignedList: ['course_1'],
          availableFrom: '2020-01-01',
          availableUntil: '2020-01-01',
          dueDate: '2020-01-01',
          dueDateId: expect.any(String),
          unassignItem: false,
        },
      ])
    })

    it('returns overrides with everyone', () => {
      const assignment = Assignment.mock({
        dueAt: '2024-04-15',
        lockAt: '2024-04-12',
        unlockAt: '2024-04-16',
      })
      const discussion = DiscussionTopic.mock()
      discussion.assignment = assignment

      const overrides = buildAssignmentOverrides(discussion)
      expect(overrides).toEqual([
        {
          assignedList: ['everyone'],
          availableFrom: '2024-04-16',
          availableUntil: '2024-04-12',
          dueDate: '2024-04-15',
          dueDateId: expect.any(String),
        },
      ])
    })

    it('returns overrides with everyone else', () => {
      const assignment = Assignment.mock({
        dueAt: '2024-04-15',
        lockAt: '2024-04-12',
        unlockAt: '2024-04-16',
      })
      const discussion = DiscussionTopic.mock()

      assignment.assignmentOverrides = {nodes: [AssignmentOverride.mock()]}
      discussion.assignment = assignment

      const overrides = buildAssignmentOverrides(discussion)
      expect(overrides).toEqual([
        {
          assignedList: ['course_section_1'],
          availableFrom: '2020-01-01',
          availableUntil: '2020-01-01',
          dueDate: '2020-01-01',
          dueDateId: expect.any(String),
          unassignItem: false,
        },
        {
          assignedList: ['everyone'],
          availableFrom: '2024-04-16',
          availableUntil: '2024-04-12',
          dueDate: '2024-04-15',
          dueDateId: expect.any(String),
        },
      ])
    })
  })

  describe('for ungraded assignments', () => {
    it('returns overrides when onlyVisibleToOverrides is true', () => {
      const discussion = DiscussionTopic.mock({onlyVisibleToOverrides: true})

      discussion.ungradedDiscussionOverrides = {nodes: [AssignmentOverride.mock()]}

      const overrides = buildAssignmentOverrides(discussion)
      expect(overrides).toEqual([
        {
          assignedList: ['course_section_1'],
          availableFrom: '2020-01-01',
          availableUntil: '2020-01-01',
          dueDate: '2020-01-01',
          dueDateId: expect.any(String),
          unassignItem: false,
        },
      ])
    })

    it('returns overrides when visibleToEveryone is false', () => {
      const discussion = DiscussionTopic.mock({visibleToEveryone: false})

      discussion.ungradedDiscussionOverrides = {nodes: [AssignmentOverride.mock()]}

      const overrides = buildAssignmentOverrides(discussion)
      expect(overrides).toEqual([
        {
          assignedList: ['course_section_1'],
          availableFrom: '2020-01-01',
          availableUntil: '2020-01-01',
          dueDate: '2020-01-01',
          dueDateId: expect.any(String),
          unassignItem: false,
        },
      ])
    })

    it('returns overrides when it has course overrides', () => {
      const discussion = DiscussionTopic.mock()

      discussion.ungradedDiscussionOverrides = {
        nodes: [
          AssignmentOverride.mock({
            set: {
              __typename: 'Course',
              id: '1',
              name: 'Course Name',
              _id: '1',
            },
          }),
        ],
      }

      const overrides = buildAssignmentOverrides(discussion)
      expect(overrides).toEqual([
        {
          assignedList: ['course_1'],
          availableFrom: '2020-01-01',
          availableUntil: '2020-01-01',
          dueDate: '2020-01-01',
          dueDateId: expect.any(String),
          unassignItem: false,
        },
      ])
    })

    it('returns overrides with everyone', () => {
      const discussion = DiscussionTopic.mock({
        lockAt: '2024-04-12',
        delayedPostAt: '2024-04-15',
        visibleToEveryone: true,
      })

      const overrides = buildAssignmentOverrides(discussion)
      expect(overrides).toEqual([
        {
          assignedList: ['everyone'],
          availableFrom: '2024-04-15',
          availableUntil: '2024-04-12',
          dueDate: undefined,
          dueDateId: expect.any(String),
        },
      ])
    })

    it('returns overrides with everyone else', () => {
      const discussion = DiscussionTopic.mock({
        lockAt: '2024-04-12',
        delayedPostAt: '2024-04-15',
        visibleToEveryone: true,
      })

      discussion.ungradedDiscussionOverrides = {nodes: [AssignmentOverride.mock()]}

      const overrides = buildAssignmentOverrides(discussion)
      expect(overrides).toEqual([
        {
          assignedList: ['course_section_1'],
          availableFrom: '2020-01-01',
          availableUntil: '2020-01-01',
          dueDate: '2020-01-01',
          dueDateId: expect.any(String),
          unassignItem: false,
        },
        {
          assignedList: ['everyone'],
          availableFrom: '2024-04-15',
          availableUntil: '2024-04-12',
          dueDate: undefined,
          dueDateId: expect.any(String),
        },
      ])
    })
  })
})
