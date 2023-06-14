/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

export const nullGradingPeriod = {
  Assignments: [
    {
      _id: '3',
      dueAt: null,
      htmlUrl: 'http://localhost:3000/courses/1/assignments/3',
      name: 'Graded discussion for submission comments',
      pointsPossible: 1000,
      gradingType: 'points',
      assignmentGroup: {
        _id: '3',
        name: 'Test Assignment Group',
        groupWeight: 30,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '12',
            gradingStatus: 'graded',
            grade: '567',
            score: 567,
            gradingPeriodId: '4',
            hideGradeFromStudent: false,
            readState: 'read',
            late: false,
            updatedAt: '2023-05-05T13:29:01-06:00',
            commentsConnection: {
              nodes: [
                {
                  comment: 'What am I supposed to do with this ron?',
                  createdAt: '2022-04-19T10:32:29-06:00',
                  author: {
                    name: 'Drake Harper',
                    shortName: 'Drake Harper',
                    __typename: 'User',
                  },
                  __typename: 'SubmissionComment',
                },
                {
                  comment:
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus tempor nunc non arcu placerat, at mollis massa suscipit. Nullam tincidunt bibendum turpis vitae consectetur. Proin posuere placerat elit, id mollis erat blandit porta. Aliquam laoreet dui sit amet ultricies pharetra. Aliquam euismod, ex at faucibus viverra, mauris velit ullamcorper massa, ut ultricies orci orci eu lorem. Pellentesque quis lectus nisl. Suspendisse sem dolor, facilisis eu velit et, varius tempus massa. Sed luctus imperdiet metus at tempor. Suspendisse tincidunt neque eu velit luctus gravida. Suspendisse sed aliquet nisi. Curabitur sagittis consequat euismod. Cras aliquam nulla vel dolor semper placerat. Nunc in dolor enim.',
                  createdAt: '2022-04-19T10:51:32-06:00',
                  author: {
                    name: 'Ron Weasley',
                    shortName: 'Ron Weasley',
                    __typename: 'User',
                  },
                  __typename: 'SubmissionComment',
                },
              ],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
    {
      _id: '8',
      dueAt: null,
      htmlUrl: 'http://localhost:3000/courses/1/assignments/8',
      name: 'Test Assignment Grading',
      pointsPossible: 100,
      gradingType: 'points',
      assignmentGroup: {
        _id: '3',
        name: 'Test Assignment Group',
        groupWeight: 30,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '37',
            gradingStatus: 'graded',
            grade: null,
            score: null,
            gradingPeriodId: '4',
            hideGradeFromStudent: true,
            readState: 'read',
            late: false,
            updatedAt: '2023-05-10T11:22:20-06:00',
            commentsConnection: {
              nodes: [],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
    {
      _id: '9',
      dueAt: '2022-08-18T23:59:59-06:00',
      htmlUrl: 'http://localhost:3000/courses/1/assignments/9',
      name: 'Graded Discussion to Test Anonymous State',
      pointsPossible: 1,
      gradingType: 'points',
      assignmentGroup: {
        _id: '3',
        name: 'Test Assignment Group',
        groupWeight: 30,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '55',
            gradingStatus: 'graded',
            grade: '3',
            score: 3,
            gradingPeriodId: '3',
            hideGradeFromStudent: false,
            readState: 'read',
            late: false,
            updatedAt: '2023-05-08T21:48:48-06:00',
            commentsConnection: {
              nodes: [],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
    {
      _id: '11',
      dueAt: null,
      htmlUrl: 'http://localhost:3000/courses/1/assignments/11',
      name: 'New Discussion =D',
      pointsPossible: 10,
      gradingType: 'points',
      assignmentGroup: {
        _id: '3',
        name: 'Test Assignment Group',
        groupWeight: 30,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '722',
            gradingStatus: 'graded',
            grade: '8',
            score: 8,
            gradingPeriodId: '4',
            hideGradeFromStudent: false,
            readState: 'read',
            late: false,
            updatedAt: '2023-05-05T13:29:01-06:00',
            commentsConnection: {
              nodes: [],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
    {
      _id: '13',
      dueAt: '2023-04-21T23:59:59-06:00',
      htmlUrl: 'http://localhost:3000/courses/1/assignments/13',
      name: 'Late Assignment',
      pointsPossible: 10,
      gradingType: 'points',
      assignmentGroup: {
        _id: '3',
        name: 'Test Assignment Group',
        groupWeight: 30,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '735',
            gradingStatus: 'graded',
            grade: '8',
            score: 8,
            gradingPeriodId: '4',
            hideGradeFromStudent: false,
            readState: 'read',
            late: true,
            updatedAt: '2023-05-05T13:29:01-06:00',
            commentsConnection: {
              nodes: [],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
    {
      _id: '14',
      dueAt: '2023-04-21T23:59:59-06:00',
      htmlUrl: 'http://localhost:3000/courses/1/assignments/14',
      name: 'Missing Assignment ',
      pointsPossible: 10,
      gradingType: 'points',
      assignmentGroup: {
        _id: '3',
        name: 'Test Assignment Group',
        groupWeight: 30,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
    {
      _id: '15',
      dueAt: '2023-04-21T23:59:59-06:00',
      htmlUrl: 'http://localhost:3000/courses/1/assignments/15',
      name: 'Excused Assignment',
      pointsPossible: 10,
      gradingType: 'points',
      assignmentGroup: {
        _id: '3',
        name: 'Test Assignment Group',
        groupWeight: 30,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '749',
            gradingStatus: 'excused',
            grade: null,
            score: null,
            gradingPeriodId: '4',
            hideGradeFromStudent: false,
            readState: 'read',
            late: false,
            updatedAt: '2023-05-05T13:29:01-06:00',
            commentsConnection: {
              nodes: [],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
    {
      _id: '28',
      dueAt: null,
      htmlUrl: 'http://localhost:3000/courses/1/assignments/28',
      name: 'Ruby 1',
      pointsPossible: 10,
      gradingType: 'points',
      assignmentGroup: {
        _id: '3',
        name: 'Test Assignment Group',
        groupWeight: 30,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '773',
            gradingStatus: 'needs_grading',
            grade: null,
            score: null,
            gradingPeriodId: '4',
            hideGradeFromStudent: false,
            readState: 'read',
            late: false,
            updatedAt: '2023-05-16T14:10:46-06:00',
            commentsConnection: {
              nodes: [],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
    {
      _id: '1',
      dueAt: '2022-01-28T23:59:59-07:00',
      htmlUrl: 'http://localhost:3000/courses/1/assignments/1',
      name: 'Graded discussion',
      pointsPossible: 1000,
      gradingType: 'points',
      assignmentGroup: {
        _id: '1',
        name: 'Assignments',
        groupWeight: 70,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '2',
            gradingStatus: 'graded',
            grade: '678.45',
            score: 678.45,
            gradingPeriodId: '3',
            hideGradeFromStudent: false,
            readState: 'read',
            late: false,
            updatedAt: '2023-05-05T13:28:11-06:00',
            commentsConnection: {
              nodes: [],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
    {
      _id: '4',
      dueAt: null,
      htmlUrl: 'http://localhost:3000/courses/1/assignments/4',
      name: 'Welcome New Riders',
      pointsPossible: 10,
      gradingType: 'points',
      assignmentGroup: {
        _id: '1',
        name: 'Assignments',
        groupWeight: 70,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '17',
            gradingStatus: 'graded',
            grade: '9',
            score: 9,
            gradingPeriodId: '4',
            hideGradeFromStudent: false,
            readState: 'read',
            late: false,
            updatedAt: '2023-05-05T13:29:01-06:00',
            commentsConnection: {
              nodes: [
                {
                  comment: 'Welcome Ron, happy to have you',
                  createdAt: '2022-04-19T11:22:13-06:00',
                  author: {
                    name: 'Drake Harper',
                    shortName: 'Drake Harper',
                    __typename: 'User',
                  },
                  __typename: 'SubmissionComment',
                },
              ],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
  ],
  AssignmentGroup: [
    {
      _id: '3',
      name: 'Test Assignment Group',
      groupWeight: 30,
      gradesConnection: {
        nodes: [
          {
            currentGrade: 'F',
            currentScore: 57.39,
            overrideGrade: null,
            overrideScore: null,
            __typename: 'Grades',
          },
        ],
        __typename: 'GradesConnection',
      },
      __typename: 'AssignmentGroup',
    },
    {
      _id: '1',
      name: 'Assignments',
      groupWeight: 70,
      gradesConnection: {
        nodes: [
          {
            currentGrade: 'D+',
            currentScore: 68.06,
            overrideGrade: null,
            overrideScore: null,
            __typename: 'Grades',
          },
        ],
        __typename: 'GradesConnection',
      },
      __typename: 'AssignmentGroup',
    },
  ],
  GradingPeriods: [
    {
      _id: '3',
      title: 'U',
      weight: null,
      __typename: 'GradingPeriod',
    },
    {
      _id: '4',
      title: 'V',
      weight: null,
      __typename: 'GradingPeriod',
    },
  ],
}

export const mockDroppedAssignmentData = {
  queryData: {
    id: 'Q291cnNlLTE=',
    name: 'Dragon Riding',
    applyGroupWeights: true,
    assignmentsConnection: {
      nodes: [
        {
          _id: '3',
          dueAt: null,
          htmlUrl: 'http://localhost:3000/courses/1/assignments/3',
          name: 'Graded discussion for submission comments',
          pointsPossible: 1000,
          gradingType: 'points',
          assignmentGroup: {
            _id: '21',
            name: 'Test Assignment Group 2',
            groupWeight: 10,
            __typename: 'AssignmentGroup',
          },
          submissionsConnection: {
            nodes: [
              {
                _id: '12',
                gradingStatus: 'graded',
                grade: '567',
                score: 567,
                gradingPeriodId: '4',
                hideGradeFromStudent: false,
                readState: 'read',
                late: false,
                updatedAt: '2023-05-05T13:29:01-06:00',
                commentsConnection: {
                  nodes: [
                    {
                      comment: 'What am I supposed to do with this ron?',
                      createdAt: '2022-04-19T10:32:29-06:00',
                      author: {
                        name: 'Drake Harper',
                        shortName: 'Drake Harper',
                        __typename: 'User',
                      },
                      __typename: 'SubmissionComment',
                    },
                    {
                      comment:
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus tempor nunc non arcu placerat, at mollis massa suscipit. Nullam tincidunt bibendum turpis vitae consectetur. Proin posuere placerat elit, id mollis erat blandit porta. Aliquam laoreet dui sit amet ultricies pharetra. Aliquam euismod, ex at faucibus viverra, mauris velit ullamcorper massa, ut ultricies orci orci eu lorem. Pellentesque quis lectus nisl. Suspendisse sem dolor, facilisis eu velit et, varius tempus massa. Sed luctus imperdiet metus at tempor. Suspendisse tincidunt neque eu velit luctus gravida. Suspendisse sed aliquet nisi. Curabitur sagittis consequat euismod. Cras aliquam nulla vel dolor semper placerat. Nunc in dolor enim.',
                      createdAt: '2022-04-19T10:51:32-06:00',
                      author: {
                        name: 'Ron Weasley',
                        shortName: 'Ron Weasley',
                        __typename: 'User',
                      },
                      __typename: 'SubmissionComment',
                    },
                  ],
                  __typename: 'SubmissionCommentConnection',
                },
                __typename: 'Submission',
              },
            ],
            __typename: 'SubmissionConnection',
          },
          __typename: 'Assignment',
        },
        {
          _id: '8',
          dueAt: null,
          htmlUrl: 'http://localhost:3000/courses/1/assignments/8',
          name: 'Test Assignment Grading',
          pointsPossible: 100,
          gradingType: 'points',
          assignmentGroup: {
            _id: '3',
            name: 'Test Assignment Group',
            groupWeight: 20,
            __typename: 'AssignmentGroup',
          },
          submissionsConnection: {
            nodes: [
              {
                _id: '37',
                gradingStatus: 'graded',
                grade: '68',
                score: 68,
                gradingPeriodId: '4',
                hideGradeFromStudent: false,
                readState: 'read',
                late: false,
                updatedAt: '2023-06-12T12:40:26-06:00',
                commentsConnection: {
                  nodes: [],
                  __typename: 'SubmissionCommentConnection',
                },
                __typename: 'Submission',
              },
            ],
            __typename: 'SubmissionConnection',
          },
          __typename: 'Assignment',
        },
        {
          _id: '9',
          dueAt: '2022-08-18T23:59:59-06:00',
          htmlUrl: 'http://localhost:3000/courses/1/assignments/9',
          name: 'Graded Discussion to Test Anonymous State',
          pointsPossible: 1,
          gradingType: 'points',
          assignmentGroup: {
            _id: '3',
            name: 'Test Assignment Group',
            groupWeight: 20,
            __typename: 'AssignmentGroup',
          },
          submissionsConnection: {
            nodes: [
              {
                _id: '55',
                gradingStatus: 'graded',
                grade: '3',
                score: 3,
                gradingPeriodId: '3',
                hideGradeFromStudent: false,
                readState: 'read',
                late: false,
                updatedAt: '2023-05-08T21:48:48-06:00',
                commentsConnection: {
                  nodes: [],
                  __typename: 'SubmissionCommentConnection',
                },
                __typename: 'Submission',
              },
            ],
            __typename: 'SubmissionConnection',
          },
          __typename: 'Assignment',
        },
        {
          _id: '11',
          dueAt: null,
          htmlUrl: 'http://localhost:3000/courses/1/assignments/11',
          name: 'New Discussion =D',
          pointsPossible: 10,
          gradingType: 'points',
          assignmentGroup: {
            _id: '3',
            name: 'Test Assignment Group',
            groupWeight: 20,
            __typename: 'AssignmentGroup',
          },
          submissionsConnection: {
            nodes: [
              {
                _id: '722',
                gradingStatus: 'graded',
                grade: '8',
                score: 8,
                gradingPeriodId: '4',
                hideGradeFromStudent: false,
                readState: 'read',
                late: true,
                updatedAt: '2023-06-13T23:08:10-06:00',
                commentsConnection: {
                  nodes: [],
                  __typename: 'SubmissionCommentConnection',
                },
                __typename: 'Submission',
              },
            ],
            __typename: 'SubmissionConnection',
          },
          __typename: 'Assignment',
        },
        {
          _id: '13',
          dueAt: '2023-04-21T23:59:59-06:00',
          htmlUrl: 'http://localhost:3000/courses/1/assignments/13',
          name: 'Late Assignment',
          pointsPossible: 10,
          gradingType: 'points',
          assignmentGroup: {
            _id: '3',
            name: 'Test Assignment Group',
            groupWeight: 20,
            __typename: 'AssignmentGroup',
          },
          submissionsConnection: {
            nodes: [
              {
                _id: '735',
                gradingStatus: 'graded',
                grade: '8',
                score: 8,
                gradingPeriodId: '4',
                hideGradeFromStudent: false,
                readState: 'read',
                late: true,
                updatedAt: '2023-06-13T23:07:48-06:00',
                commentsConnection: {
                  nodes: [],
                  __typename: 'SubmissionCommentConnection',
                },
                __typename: 'Submission',
              },
            ],
            __typename: 'SubmissionConnection',
          },
          __typename: 'Assignment',
        },
        {
          _id: '14',
          dueAt: '2023-04-21T23:59:59-06:00',
          htmlUrl: 'http://localhost:3000/courses/1/assignments/14',
          name: 'Missing Assignment ',
          pointsPossible: 10,
          gradingType: 'points',
          assignmentGroup: {
            _id: '3',
            name: 'Test Assignment Group',
            groupWeight: 20,
            __typename: 'AssignmentGroup',
          },
          submissionsConnection: {
            nodes: [
              {
                _id: '785',
                gradingStatus: 'graded',
                grade: '8',
                score: 8,
                gradingPeriodId: '4',
                hideGradeFromStudent: false,
                readState: 'read',
                late: false,
                updatedAt: '2023-06-07T15:51:40-06:00',
                commentsConnection: {
                  nodes: [],
                  __typename: 'SubmissionCommentConnection',
                },
                __typename: 'Submission',
              },
            ],
            __typename: 'SubmissionConnection',
          },
          __typename: 'Assignment',
        },
        {
          _id: '15',
          dueAt: '2023-04-21T23:59:59-06:00',
          htmlUrl: 'http://localhost:3000/courses/1/assignments/15',
          name: 'Excused Assignment',
          pointsPossible: 10,
          gradingType: 'points',
          assignmentGroup: {
            _id: '3',
            name: 'Test Assignment Group',
            groupWeight: 20,
            __typename: 'AssignmentGroup',
          },
          submissionsConnection: {
            nodes: [
              {
                _id: '749',
                gradingStatus: 'graded',
                grade: '11',
                score: 11,
                gradingPeriodId: '4',
                hideGradeFromStudent: false,
                readState: 'read',
                late: false,
                updatedAt: '2023-06-13T23:08:51-06:00',
                commentsConnection: {
                  nodes: [],
                  __typename: 'SubmissionCommentConnection',
                },
                __typename: 'Submission',
              },
            ],
            __typename: 'SubmissionConnection',
          },
          __typename: 'Assignment',
        },
        {
          _id: '28',
          dueAt: null,
          htmlUrl: 'http://localhost:3000/courses/1/assignments/28',
          name: 'Ruby 1',
          pointsPossible: 50,
          gradingType: 'points',
          assignmentGroup: {
            _id: '3',
            name: 'Test Assignment Group',
            groupWeight: 20,
            __typename: 'AssignmentGroup',
          },
          submissionsConnection: {
            nodes: [
              {
                _id: '773',
                gradingStatus: 'needs_grading',
                grade: null,
                score: null,
                gradingPeriodId: '4',
                hideGradeFromStudent: false,
                readState: 'read',
                late: false,
                updatedAt: '2023-05-16T14:10:46-06:00',
                commentsConnection: {
                  nodes: [],
                  __typename: 'SubmissionCommentConnection',
                },
                __typename: 'Submission',
              },
            ],
            __typename: 'SubmissionConnection',
          },
          __typename: 'Assignment',
        },
        {
          _id: '1',
          dueAt: '2022-01-28T23:59:59-07:00',
          htmlUrl: 'http://localhost:3000/courses/1/assignments/1',
          name: 'Graded discussion',
          pointsPossible: 1000,
          gradingType: 'points',
          assignmentGroup: {
            _id: '1',
            name: 'Assignments',
            groupWeight: 70,
            __typename: 'AssignmentGroup',
          },
          submissionsConnection: {
            nodes: [
              {
                _id: '2',
                gradingStatus: 'graded',
                grade: '678.45',
                score: 678.45,
                gradingPeriodId: '3',
                hideGradeFromStudent: false,
                readState: 'read',
                late: false,
                updatedAt: '2023-05-05T13:28:11-06:00',
                commentsConnection: {
                  nodes: [],
                  __typename: 'SubmissionCommentConnection',
                },
                __typename: 'Submission',
              },
            ],
            __typename: 'SubmissionConnection',
          },
          __typename: 'Assignment',
        },
        {
          _id: '4',
          dueAt: null,
          htmlUrl: 'http://localhost:3000/courses/1/assignments/4',
          name: 'Welcome New Riders',
          pointsPossible: 10,
          gradingType: 'points',
          assignmentGroup: {
            _id: '1',
            name: 'Assignments',
            groupWeight: 70,
            __typename: 'AssignmentGroup',
          },
          submissionsConnection: {
            nodes: [
              {
                _id: '784',
                gradingStatus: 'graded',
                grade: '10',
                score: 10,
                gradingPeriodId: '4',
                hideGradeFromStudent: false,
                readState: 'read',
                late: false,
                updatedAt: '2023-06-07T15:36:34-06:00',
                commentsConnection: {
                  nodes: [],
                  __typename: 'SubmissionCommentConnection',
                },
                __typename: 'Submission',
              },
            ],
            __typename: 'SubmissionConnection',
          },
          __typename: 'Assignment',
        },
      ],
      __typename: 'AssignmentConnection',
    },
    assignmentGroupsConnection: {
      nodes: [
        {
          _id: '21',
          name: 'Test Assignment Group 2',
          groupWeight: 10,
          rules: {
            dropHighest: null,
            dropLowest: null,
            neverDrop: null,
            __typename: 'AssignmentGroupRules',
          },
          gradesConnection: {
            nodes: [
              {
                currentGrade: 'F',
                currentScore: 56.7,
                overrideGrade: null,
                overrideScore: null,
                __typename: 'Grades',
              },
            ],
            __typename: 'GradesConnection',
          },
          __typename: 'AssignmentGroup',
        },
        {
          _id: '3',
          name: 'Test Assignment Group',
          groupWeight: 20,
          rules: {
            dropHighest: 1,
            dropLowest: 2,
            neverDrop: [
              {
                _id: '8',
                name: 'Test Assignment Grading',
                __typename: 'Assignment',
              },
            ],
            __typename: 'AssignmentGroupRules',
          },
          gradesConnection: {
            nodes: [
              {
                currentGrade: 'C-',
                currentScore: 71.17,
                overrideGrade: null,
                overrideScore: null,
                __typename: 'Grades',
              },
            ],
            __typename: 'GradesConnection',
          },
          __typename: 'AssignmentGroup',
        },
        {
          _id: '1',
          name: 'Assignments',
          groupWeight: 70,
          rules: {
            dropHighest: null,
            dropLowest: null,
            neverDrop: null,
            __typename: 'AssignmentGroupRules',
          },
          gradesConnection: {
            nodes: [
              {
                currentGrade: 'D+',
                currentScore: 68.16,
                overrideGrade: null,
                overrideScore: null,
                __typename: 'Grades',
              },
            ],
            __typename: 'GradesConnection',
          },
          __typename: 'AssignmentGroup',
        },
      ],
      __typename: 'AssignmentGroupConnection',
    },
    gradingStandard: {
      data: [
        {
          letterGrade: 'A',
          baseValue: 0.94,
          __typename: 'GradingStandardItem',
        },
        {
          letterGrade: 'A-',
          baseValue: 0.9,
          __typename: 'GradingStandardItem',
        },
        {
          letterGrade: 'B+',
          baseValue: 0.87,
          __typename: 'GradingStandardItem',
        },
        {
          letterGrade: 'B',
          baseValue: 0.84,
          __typename: 'GradingStandardItem',
        },
        {
          letterGrade: 'B-',
          baseValue: 0.8,
          __typename: 'GradingStandardItem',
        },
        {
          letterGrade: 'C+',
          baseValue: 0.77,
          __typename: 'GradingStandardItem',
        },
        {
          letterGrade: 'C',
          baseValue: 0.74,
          __typename: 'GradingStandardItem',
        },
        {
          letterGrade: 'C-',
          baseValue: 0.7,
          __typename: 'GradingStandardItem',
        },
        {
          letterGrade: 'D+',
          baseValue: 0.67,
          __typename: 'GradingStandardItem',
        },
        {
          letterGrade: 'D',
          baseValue: 0.64,
          __typename: 'GradingStandardItem',
        },
        {
          letterGrade: 'D-',
          baseValue: 0.61,
          __typename: 'GradingStandardItem',
        },
        {
          letterGrade: 'F',
          baseValue: 0,
          __typename: 'GradingStandardItem',
        },
      ],
      title: 'Default Grading Scheme',
      __typename: 'GradingStandard',
    },
    gradingPeriodsConnection: {
      nodes: [
        {
          _id: '3',
          title: 'U',
          weight: 70,
          __typename: 'GradingPeriod',
        },
        {
          _id: '4',
          title: 'V',
          weight: 30,
          __typename: 'GradingPeriod',
        },
      ],
      __typename: 'GradingPeriodConnection',
    },
    __typename: 'Course',
  },
  expectedDroppedAssignments: [
    {
      _id: '13',
      dueAt: '2023-04-21T23:59:59-06:00',
      htmlUrl: 'http://localhost:3000/courses/1/assignments/13',
      name: 'Late Assignment',
      pointsPossible: 10,
      gradingType: 'points',
      assignmentGroup: {
        _id: '3',
        name: 'Test Assignment Group',
        groupWeight: 20,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '735',
            gradingStatus: 'graded',
            grade: '8',
            score: 8,
            gradingPeriodId: '4',
            hideGradeFromStudent: false,
            readState: 'read',
            late: true,
            updatedAt: '2023-06-13T23:07:48-06:00',
            commentsConnection: {
              nodes: [],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
    {
      _id: '14',
      dueAt: '2023-04-21T23:59:59-06:00',
      htmlUrl: 'http://localhost:3000/courses/1/assignments/14',
      name: 'Missing Assignment ',
      pointsPossible: 10,
      gradingType: 'points',
      assignmentGroup: {
        _id: '3',
        name: 'Test Assignment Group',
        groupWeight: 20,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '785',
            gradingStatus: 'graded',
            grade: '8',
            score: 8,
            gradingPeriodId: '4',
            hideGradeFromStudent: false,
            readState: 'read',
            late: false,
            updatedAt: '2023-06-07T15:51:40-06:00',
            commentsConnection: {
              nodes: [],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
    {
      _id: '15',
      dueAt: '2023-04-21T23:59:59-06:00',
      htmlUrl: 'http://localhost:3000/courses/1/assignments/15',
      name: 'Excused Assignment',
      pointsPossible: 10,
      gradingType: 'points',
      assignmentGroup: {
        _id: '3',
        name: 'Test Assignment Group',
        groupWeight: 20,
        __typename: 'AssignmentGroup',
      },
      submissionsConnection: {
        nodes: [
          {
            _id: '749',
            gradingStatus: 'graded',
            grade: '11',
            score: 11,
            gradingPeriodId: '4',
            hideGradeFromStudent: false,
            readState: 'read',
            late: false,
            updatedAt: '2023-06-13T23:08:51-06:00',
            commentsConnection: {
              nodes: [],
              __typename: 'SubmissionCommentConnection',
            },
            __typename: 'Submission',
          },
        ],
        __typename: 'SubmissionConnection',
      },
      __typename: 'Assignment',
    },
  ],
}
