/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import AssignmentTable from './AssignmentTable'
import React from 'react'

export default {
  title: 'Examples/Student Grade Summary/AssignmentTable',
  component: AssignmentTable,
}

const defaultQueryData = {
  id: 'Q291cnNlLTE=',
  name: 'Dragon Riding',
  applyGroupWeights: true,
  assignmentsConnection: {
    nodes: [
      {
        _id: '3',
        dueAt: null,
        htmlUrl: '',
        name: 'Graded discussion for submission comments',
        pointsPossible: 1000,
        gradingPeriodId: '4',
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
        htmlUrl: '',
        name: 'Test Assignment Grading',
        pointsPossible: 100,
        gradingPeriodId: '4',
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
        htmlUrl: '',
        name: 'New Discussion =D',
        pointsPossible: 10,
        assignmentGroup: {
          _id: '3',
          name: 'Test Assignment Group',
          groupWeight: 30,
          __typename: 'AssignmentGroup',
        },
        gradingPeriodId: '4',
        submissionsConnection: {
          nodes: [
            {
              _id: '722',
              gradingStatus: 'graded',
              grade: '8',
              score: 8,
              gradingPeriodId: '4',
              hideGradeFromStudent: false,
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
        htmlUrl: '',
        name: 'Late Assignment',
        pointsPossible: 10,
        gradingPeriodId: '4',
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
        htmlUrl: '',
        name: 'Missing Assignment ',
        pointsPossible: 10,
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
        htmlUrl: '',
        name: 'Excused Assignment',
        pointsPossible: 10,
        gradingPeriodId: '4',
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
        htmlUrl: '',
        name: 'Welcome New Riders',
        pointsPossible: 10,
        gradingPeriodId: '4',
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
    __typename: 'AssignmentConnection',
  },
  assignmentGroupsConnection: {
    nodes: [
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
}

const varyingAssignmentTypes = {
  id: 'Q291cnNlLTEwMTM=',
  name: 'Varying Assignment Types',
  applyGroupWeights: false,
  assignmentsConnection: {
    nodes: [
      {
        _id: '20',
        dueAt: null,
        htmlUrl: '',
        name: 'Percentage',
        pointsPossible: 10,
        gradingPeriodId: '4',
        assignmentGroup: {
          _id: '16',
          name: 'Assignments',
          groupWeight: 0,
          __typename: 'AssignmentGroup',
        },
        submissionsConnection: {
          nodes: [
            {
              _id: '754',
              gradingStatus: 'graded',
              grade: '99%',
              score: 9.9,
              gradingPeriodId: '4',
              hideGradeFromStudent: false,
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
        _id: '21',
        dueAt: null,
        htmlUrl: '',
        name: 'Complete/Incomplete',
        pointsPossible: 10,
        gradingPeriodId: '4',
        assignmentGroup: {
          _id: '16',
          name: 'Assignments',
          groupWeight: 0,
          __typename: 'AssignmentGroup',
        },
        submissionsConnection: {
          nodes: [
            {
              _id: '755',
              gradingStatus: 'graded',
              grade: 'complete',
              score: 10,
              gradingPeriodId: '4',
              hideGradeFromStudent: false,
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
        _id: '22',
        dueAt: null,
        htmlUrl: '',
        name: 'Points',
        pointsPossible: 10,
        gradingPeriodId: '4',
        assignmentGroup: {
          _id: '16',
          name: 'Assignments',
          groupWeight: 0,
          __typename: 'AssignmentGroup',
        },
        submissionsConnection: {
          nodes: [
            {
              _id: '756',
              gradingStatus: 'graded',
              grade: '8',
              score: 8,
              gradingPeriodId: '4',
              hideGradeFromStudent: false,
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
        _id: '23',
        dueAt: null,
        htmlUrl: '',
        name: 'Letter Grade',
        pointsPossible: 10,
        gradingPeriodId: '4',
        assignmentGroup: {
          _id: '16',
          name: 'Assignments',
          groupWeight: 0,
          __typename: 'AssignmentGroup',
        },
        submissionsConnection: {
          nodes: [
            {
              _id: '757',
              gradingStatus: 'graded',
              grade: 'B+',
              score: 8.9,
              gradingPeriodId: '4',
              hideGradeFromStudent: false,
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
        _id: '24',
        dueAt: null,
        htmlUrl: '',
        name: 'GPA Scale',
        pointsPossible: 10,
        gradingPeriodId: '4',
        assignmentGroup: {
          _id: '16',
          name: 'Assignments',
          groupWeight: 0,
          __typename: 'AssignmentGroup',
        },
        submissionsConnection: {
          nodes: [
            {
              _id: '758',
              gradingStatus: 'graded',
              grade: 'B',
              score: 8.6,
              gradingPeriodId: '4',
              hideGradeFromStudent: false,
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
        _id: '25',
        dueAt: null,
        htmlUrl: '',
        name: 'Not Graded',
        pointsPossible: null,
        gradingPeriodId: '4',
        assignmentGroup: {
          _id: '16',
          name: 'Assignments',
          groupWeight: 0,
          __typename: 'AssignmentGroup',
        },
        submissionsConnection: {
          nodes: [],
          __typename: 'SubmissionConnection',
        },
        __typename: 'Assignment',
      },
      {
        _id: '26',
        dueAt: null,
        htmlUrl: '',
        name: 'Manual post',
        pointsPossible: 10,
        gradingPeriodId: '4',
        assignmentGroup: {
          _id: '16',
          name: 'Assignments',
          groupWeight: 0,
          __typename: 'AssignmentGroup',
        },
        submissionsConnection: {
          nodes: [
            {
              _id: '767',
              gradingStatus: 'graded',
              grade: '7',
              score: 7,
              gradingPeriodId: '4',
              hideGradeFromStudent: false,
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
        _id: '16',
        name: 'Assignments',
        groupWeight: 0,
        gradesConnection: {
          nodes: [
            {
              currentGrade: null,
              currentScore: 87.33,
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
}

const Template = args => <AssignmentTable {...args} />

export const Default = Template.bind({})
Default.args = {
  queryData: defaultQueryData,
  layout: 'fixed',
  setShowTray: () => {},
  setSelectedSubmission: () => {},
}

export const Mobile = Template.bind({})
Mobile.args = {
  queryData: defaultQueryData,
  layout: 'stacked',
  setShowTray: () => {},
  setSelectedSubmission: () => {},
}

export const VaryingAssignmentTypes = Template.bind({})
VaryingAssignmentTypes.args = {
  queryData: varyingAssignmentTypes,
  layout: 'fixed',
  setShowTray: () => {},
  setSelectedSubmission: () => {},
}
