/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {mockAssignment, mockOverride} from '../../../test-utils'

export const basicAssignment = mockAssignment({
  lid: 'assignment-lid',
  name: 'assignment name',
  pointsPossible: 5,
  dueAt: '2018-11-28T13:00-05:00',
  lockAt: '2018-11-29T13:00-05:00',
  unlockAt: '2018-11-27T13:00-05:00',
  description: 'assignment description',
  state: 'published',
  course: 'course-lid',
  modules: [{lid: '1', name: 'module 1'}, {lid: '2', name: 'module 2'}],
  assignmentGroup: {lid: '1', name: 'assignment group'},
  lockInfo: {
    isLocked: false
  },
  submissionTypes: [],
  allowedExtensions: [],
  allowedAttempts: null,
  assignmentOverrides: {
    nodes: []
  }
})

// unpublished, graded, no-submission, due for everyone, no due date
export const noSubEveryoneAssignment = mockAssignment({
  ...basicAssignment,
  allowedAttempts: -1,
  pointsPossible: 15.0,
  gradingType: 'points',
  dueAt: null,
  state: 'unpublished',
  submissionTypes: ['none']
})

// unpublished, graded, paper submission, due for everyone, no due date
export const paperEveryoneAssignment = mockAssignment({
  ...basicAssignment,
  allowedAttempts: -1,
  pointsPossible: 15.0,
  gradingType: 'points',
  dueAt: null,
  state: 'unpublished',
  submissionTypes: ['on_paper']
})

// published, graded, text-entry submission, due for everyone
export const gradedEveryoneAssignment = mockAssignment({
  ...basicAssignment,
  allowedAttempts: -1,
  pointsPossible: 15.0,
  gradingType: 'points',
  dueAt: null,
  state: 'published',
  submissionTypes: ['online_text_entry']
})

// published, graded, any submission type, due for everyone
export const gradedAnySubAssignment = mockAssignment({
  ...basicAssignment,
  allowedAttempts: -1,
  pointsPossible: 15.0,
  gradingType: 'points',
  dueAt: null,
  state: 'published',
  submissionTypes: ['online_text_entry', 'online_url', 'online_upload']
})

// published, graded, pass/fail, any submission type, due for Section1
export const sectionAssignment = mockAssignment({
  ...basicAssignment,
  allowedAttempts: -1,
  pointsPossible: 15.0,
  gradingType: 'pass_fail',
  dueAt: null,
  state: 'published',
  submissionTypes: ['online_text_entry', 'online_url', 'online_upload'],
  assignmentOverrides: {
    nodes: [
      mockOverride({
        setType: 'CourseSection',
        setId: 2,
        workflowState: 'active',
        dueAtOverridden: true,
        dueAt: '2018-12-06 06:59:59',
        unlockAtOverridden: true,
        unlockAt: null,
        lockAtOverridden: true,
        lockAt: null
      })
    ]
  }
})

// published, graded, file upload (restricted to PDF), due for everyone
export const gradedGroupAssignment = mockAssignment({
  ...basicAssignment,
  allowedAttempts: -1,
  pointsPossible: 15.0,
  gradingType: 'points',
  dueAt: null,
  allowedExtensions: ['pdf'],
  state: 'published',
  submissionTypes: ['online_upload']
})

// Published, graded, any submission type, group assignment (assigned to two Groups in GroupSet1)
export const groupAssignment = mockAssignment({
  ...basicAssignment,
  allowedAttempts: -1,
  pointsPossible: 15.0,
  gradingType: 'points',
  dueAt: null,
  state: 'published',
  submissionTypes: ['online_text_entry', 'online_url', 'online_upload'],
  assignmentOverrides: {
    nodes: [
      mockOverride({
        setType: 'Group',
        setId: 2,
        workflowState: 'active',
        dueAtOverridden: true,
        dueAt: '2019-12-01 06:59:59',
        unlockAtOverridden: true,
        unlockAt: null,
        lockAtOverridden: true,
        lockAt: null
      }),
      mockOverride({
        setType: 'Group',
        setId: 2,
        workflowState: 'active',
        dueAtOverridden: true,
        dueAt: '2019-15-01 06:59:59',
        unlockAtOverridden: true,
        unlockAt: null,
        lockAtOverridden: true,
        lockAt: null
      })
    ]
  }
})

// Published, graded individually, any submission type, group assignment (assigned to two different GroupSets)
export const groupSetAssignment = mockAssignment({
  ...basicAssignment,
  allowedAttempts: -1,
  pointsPossible: 15.0,
  gradingType: 'points',
  dueAt: null,
  state: 'published',
  submissionTypes: ['online_text_entry', 'online_url', 'online_upload'],
  assignmentOverrides: {
    nodes: [
      mockOverride({
        setType: 'Group',
        setId: 1,
        workflowState: 'active',
        dueAtOverridden: true,
        dueAt: '2019-12-01 06:59:59',
        unlockAtOverridden: true,
        unlockAt: null,
        lockAtOverridden: true,
        lockAt: null
      }),
      mockOverride({
        setType: 'Group',
        setId: 2,
        workflowState: 'active',
        dueAtOverridden: true,
        dueAt: '2019-15-01 06:59:59',
        unlockAtOverridden: true,
        unlockAt: null,
        lockAtOverridden: true,
        lockAt: null
      })
    ]
  }
})
