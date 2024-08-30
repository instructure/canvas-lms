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

import {
  mockCourse,
  mockAssignment,
  mockUser,
  mockSubmission,
  mockOverride,
} from '../../../test-utils'

// unpublished, graded, no-submission, due for everyone, no due date
export function noSubEveryoneAssignment(overrides) {
  const noSubEveryoneAssign = mockAssignment({
    dueAt: null,
    unlockAt: null,
    lockAt: null,
    state: 'unpublished',
    submissionTypes: ['none'],
    ...overrides,
  })
  return noSubEveryoneAssign
}

// unpublished, graded, paper submission, due for everyone, no due date
export function paperEveryoneAssignment(overrides) {
  const paperEveryoneAssign = mockAssignment({
    dueAt: null,
    unlockAt: null,
    lockAt: null,
    state: 'unpublished',
    submissionTypes: ['on_paper'],
    ...overrides,
  })
  return paperEveryoneAssign
}

// published, graded, text-entry submission, due for everyone
export function gradedEveryoneAssignment(overrides) {
  const gradedEveryoneAssign = mockAssignment({
    dueAt: '2019-02-23T23:59:59-07:00',
    unlockAt: null,
    lockAt: null,
    ...overrides,
  })
  return gradedEveryoneAssign
}

// published, graded, any submission type, due for everyone
export function gradedAnySubAssignment(overrides) {
  const gradedAnySubAssign = mockAssignment({
    unlockAt: null,
    lockAt: null,
    submissionTypes: ['online_text_entry', 'online_url', 'online_upload'],
    ...overrides,
  })
  return gradedAnySubAssign
}

// published, graded, online submission type, partial submissions
export function partialSubAssignment(overrides) {
  const partialSubAssign = mockAssignment({
    dueAt: '2019-02-28T23:59:00-07:00',
    unlockAt: null,
    lockAt: null,
    needsGradingCount: 1,
    submissions: {
      nodes: [
        mockSubmission({
          gid: '1sub',
          lid: '1',
          state: 'unsubmitted',
          submissionStatus: 'unsubmitted',
          gradingStatus: 'needs_grading',
          submittedAt: null,
          score: null,
          grade: null,
          user: mockUser({
            gid: '1user',
            lid: '1',
            name: 'First Student',
            shortName: 'FirstS1',
            sortableName: 'Student, First',
            email: 'first_student1@example.com',
          }),
        }),
        mockSubmission({
          gid: '2sub',
          lid: '2',
          state: 'submitted',
          submissionStatus: 'submitted',
          submittedAt: '2019-03-12T12:21:42Z',
          gradingStatus: 'graded',
          score: 3.5,
          grade: '3.5',
          user: mockUser({
            gid: '2user',
            lid: '2',
            name: 'Second Student',
            shortName: 'SecondS12',
            sortableName: 'Student, Second',
            email: 'second_student2@example.com',
          }),
        }),
      ],
    },
    ...overrides,
  })
  return partialSubAssign
}

// published, graded, pass/fail, any submission type, due for Section1
export function sectionAssignment(overrides) {
  const sectionAssign = mockAssignment({
    dueAt: '2019-02-28T23:59:00-07:00',
    unlockAt: null,
    lockAt: null,
    submissionTypes: ['online_text_entry', 'online_url', 'online_upload'],
    assignmentOverrides: {
      nodes: [
        mockOverride({
          title: 'CourseSection1 Override',
          dueAt: '2019-02-28T23:59:00-07:00',
          lockAt: null,
          unlockAt: null,
          set: {
            lid: '2',
            name: 'CourseSection1',
            __typename: 'Section',
          },
        }),
      ],
    },
    ...overrides,
  })
  return sectionAssign
}

// published, graded, file upload (restricted to PDF), due for everyone
export function gradedGroupAssignment(overrides) {
  const gradedGroupAssign = mockAssignment({
    dueAt: '2019-02-23T23:59:59-07:00',
    unlockAt: null,
    lockAt: null,
    allowedExtensions: ['pdf'],
    submissionTypes: ['online_upload'],
    course: mockCourse(),
    ...overrides,
  })
  return gradedGroupAssign
}

// Published, graded, any submission type, group assignment (assigned to two Groups in GroupSet1)
export function groupAssignment(overrides) {
  const groupAssign = mockAssignment({
    submissionTypes: ['online_text_entry', 'online_url', 'online_upload'],
    assignmentOverrides: {
      nodes: [
        mockOverride({
          title: 'Override_1',
          gid: '1',
          lid: '1',
          dueAt: '2019-03-14T23:59:00-07:00',
          lockAt: '2019-03-180T23:59:59-07:00',
          unlockAt: '2019-03-10T00:00:00-07:00',
          set: {
            lid: '1',
            name: 'GrpSet1 1',
            __typename: 'Group',
          },
        }),
        mockOverride({
          title: 'Override_2',
          gid: '2',
          lid: '2',
          dueAt: '2019-02-27T23:59:00-07:00',
          lockAt: '2019-03-050T23:59:59-07:00',
          unlockAt: '2019-02-23T00:00:00-07:00',
          set: {
            lid: '2',
            name: 'GrpSet1 2',
            __typename: 'Group',
          },
        }),
      ],
    },
    needsGradingCount: 2,
    submissions: {
      nodes: [
        mockSubmission({
          gid: '1',
          lid: '1',
          gradingStatus: null,
          grade: null,
          state: 'unsubmitted',
          submissionStatus: 'unsubmitted',
          submittedAt: null,
          user: mockUser({
            lid: '1',
            gid: '1',
            name: 'First Student',
            shortName: 'FirstS1',
            sortableName: 'Student, First',
            email: 'first_student1@example.com',
          }),
        }),
        mockSubmission({
          gid: '2',
          lid: '2',
          gradingStatus: null,
          grade: null,
          state: 'unsubmitted',
          submissionStatus: 'unsubmitted',
          submittedAt: null,
          user: mockUser({
            lid: '2',
            gid: '2',
            name: 'Second Student',
            shortName: 'SecondS2',
            sortableName: 'Student, Second',
            email: 'second_student2@example.com',
          }),
        }),
        mockSubmission({
          gid: '3',
          lid: '3',
          gradingStatus: 'needs_grading',
          grade: null,
          state: 'submitted',
          submissionStatus: 'submitted',
          submittedAt: '2019-03-13T15:43:31-07:00',
          user: mockUser({
            lid: '3',
            gid: '3',
            name: 'Third Student',
            shortName: 'ThirdS3',
            sortableName: 'Student, Third',
            email: 'third_student3@example.com',
          }),
        }),
        mockSubmission({
          gid: '4',
          lid: '4',
          gradingStatus: 'needs_grading',
          grade: null,
          state: 'submitted',
          submissionStatus: 'submitted',
          submittedAt: '2019-03-12T15:43:31-07:00',
          user: mockUser({
            lid: '4',
            gid: '4',
            name: 'Fourth Student',
            shortName: 'FourthS4',
            sortableName: 'Student, Fourth',
            email: 'fourth_student4@example.com',
          }),
        }),
      ],
    },
    course: mockCourse(),
    ...overrides,
  })
  return groupAssign
}

/*
  Published, any submission type,
  group assignment, graded individually
*/
export function groupIndividualSubAssignment(overrides) {
  const groupIndividualSubAssign = mockAssignment({
    lockInfo: {isLocked: false, __typename: 'LockInfo'},
    dueAt: null,
    lockAt: null,
    unlockAt: null,
    submissionTypes: ['online_text_entry', 'online_url', 'online_upload'],
    assignmentOverrides: {
      nodes: [
        mockOverride({
          title: 'Group Individual Override_1',
          dueAt: '2019-03-08T23:59:00-07:00',
          gid: '1',
          lid: '1',
          lockAt: null,
          unlockAt: null,
          set: {__typename: 'Group', lid: '1', name: 'GPSET1_1'},
        }),
        mockOverride({
          title: 'Group Individual Override_2',
          dueAt: '2019-03-01T23:59:00-07:00',
          gid: '2',
          lid: '2',
          lockAt: null,
          unlockAt: null,
          set: {__typename: 'Group', lid: '2', name: 'GPSET2_2'},
        }),
      ],
    },
    needsGradingCount: 2,
    submissions: {
      nodes: [
        mockSubmission({
          gid: '1',
          lid: '1',
          grade: null,
          gradingStatus: null,
          score: null,
          state: 'unsubmitted',
          submissionStatus: 'unsubmitted',
          submittedAt: null,
          user: mockUser({
            avatarUrl: null,
            email: 'S1@mail.com',
            gid: '1',
            lid: '1',
            name: 'S1 Student One',
            shortName: 'S1 Student One',
            sortableName: 'One, S1 Student',
          }),
        }),
        mockSubmission({
          gid: '2',
          lid: '2',
          grade: null,
          gradingStatus: null,
          score: null,
          state: 'unsubmitted',
          submissionStatus: 'unsubmitted',
          submittedAt: null,
          user: mockUser({
            avatarUrl: null,
            email: 'S2@mail.com',
            gid: '2',
            lid: '2',
            name: 'S2 Student Two',
            shortName: 'S2 Student Two',
            sortableName: 'Two, S2 Student',
          }),
        }),
        mockSubmission({
          gid: '3',
          lid: '3',
          grade: null,
          score: null,
          gradingStatus: 'needs_grading',
          state: 'submitted',
          submissionStatus: 'submitted',
          submittedAt: '2019-02-28T15:43:31-07:00',
          user: mockUser({
            avatarUrl: null,
            email: 'S3@mail.com',
            gid: '3',
            lid: '3',
            name: 'S3 Student Three',
            shortName: 'S3 Student Three',
            sortableName: 'Three, S3 Student',
          }),
        }),
        mockSubmission({
          gid: '4',
          lid: '4',
          grade: null,
          score: null,
          gradingStatus: 'needs_grading',
          state: 'submitted',
          submissionStatus: 'submitted',
          submittedAt: '2019-02-28T15:43:31-07:00',
          user: mockUser({
            avatarUrl: null,
            email: 'S4@mail.com',
            gid: '4',
            lid: '4',
            name: 'S4 Student Four',
            shortName: 'S4 Student Four',
            sortableName: 'Four, S4 Student',
          }),
        }),
      ],
    },
    course: mockCourse(),
    ...overrides,
  })
  return groupIndividualSubAssign
}

export function variedSubmissionTypes() {
  const submissions = [
    mockSubmission({
      gid: '1sub',
      lid: '1',
      state: 'graded',
      submissionStatus: 'submitted',
      gradingStatus: 'graded',
      submittedAt: '2019-03-13T12:21:42Z',
      score: 2,
      grade: '2',
      user: mockUser({
        gid: '1user',
        lid: '1',
        name: 'First Student',
        shortName: 'FirstS1',
        sortableName: 'Student, First',
        email: 'first_student1@example.com',
      }),
    }),
    mockSubmission({
      gid: '2sub',
      lid: '2',
      state: 'graded',
      submissionStatus: 'submitted',
      submittedAt: '2019-03-12T12:21:42Z',
      gradingStatus: 'graded',
      score: 3.5,
      grade: '3.5',
      user: mockUser({
        gid: '2user',
        lid: '2',
        name: 'Second Student',
        shortName: 'SecondS12',
        sortableName: 'Student, Second',
        email: 'second_student2@example.com',
      }),
    }),
    mockSubmission({
      gid: '3sub',
      lid: '3',
      state: 'graded',
      submissionStatus: 'submitted',
      gradingStatus: 'graded',
      submittedAt: '2019-03-13T12:21:42Z',
      score: 0.5,
      grade: '0.5',
      user: mockUser({
        gid: '3user',
        lid: '3',
        name: 'Third Student',
        shortName: 'ThirdS3',
        sortableName: 'Student, Third',
        email: 'third_student3@example.com',
      }),
    }),
    mockSubmission({
      gid: '4sub',
      lid: '4',
      state: 'graded',
      submissionStatus: 'submitted',
      gradingStatus: 'graded',
      submittedAt: '2019-03-13T12:21:42Z',
      score: 2.5,
      grade: '0.5S',
      user: mockUser({
        gid: '4user',
        lid: '4',
        name: 'Fourth Student',
        shortName: 'FourthS4',
        sortableName: 'Student, Fourth',
        email: 'fourth_student4@example.com',
      }),
    }),
    mockSubmission({
      gid: '5sub',
      lid: '5',
      state: 'unsubmitted',
      submissionStatus: 'unsubmitted',
      gradingStatus: null,
      submittedAt: null,
      score: null,
      grade: null,
      user: mockUser({
        gid: '5user',
        lid: '5',
        name: 'Fifth Student',
        shortName: 'FifthS5',
        sortableName: 'Student, Fifth',
        email: 'fifth_student5@example.com',
      }),
    }),
    mockSubmission({
      gid: '6sub',
      lid: '6',
      state: 'graded',
      submissionStatus: 'unsubmitted',
      submittedAt: null,
      gradingStatus: 'graded',
      score: 3.5,
      grade: '3.5',
      user: mockUser({
        gid: '6user',
        lid: '6',
        name: 'Sixth Student',
        shortName: 'SixthS6',
        sortableName: 'Student, Sixth',
        email: 'sixth_student6@example.com',
      }),
    }),
  ]
  return submissions
}
/*
  To-Do
  Published, any submission type,
  with peer reviews
*/
/*
  To-Do
  Published, any submission type,
  due for everyone
  moderated and anonymous
*/
/*
  To-Do
  Published, any submission type,
  group assignment, moderated and anonymous
*/
