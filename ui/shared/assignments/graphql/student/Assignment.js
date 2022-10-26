/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {arrayOf, bool, number, shape, string} from 'prop-types'
import gql from 'graphql-tag'

import {AssignmentGroup} from './AssignmentGroup'
import {GroupSet} from './GroupSet'
import {LockInfo} from './LockInfo'
import {Module} from './Module'
import {Submission} from './Submission'

// TODO - Pass ENV data down in react context instead of jimmied onto the assignment

export const Assignment = {
  fragment: gql`
    fragment Assignment on Assignment {
      _id
      allowedAttempts
      allowedExtensions
      assignmentGroup {
        ...AssignmentGroup
      }
      description
      dueAt
      expectsSubmission
      gradingType
      gradeGroupStudentsIndividually
      groupCategoryId
      groupSet {
        ...GroupSet
      }
      lockAt
      lockInfo {
        ...LockInfo
      }
      modules {
        ...Module
      }
      name
      nonDigitalSubmission
      originalityReportVisibility
      pointsPossible
      submissionTypes
      unlockAt
    }
    ${AssignmentGroup.fragment}
    ${GroupSet.fragment}
    ${LockInfo.fragment}
    ${Module.fragment}
  `,

  shape: shape({
    _id: string.isRequired,
    allowedAttempts: number,
    allowedExtensions: arrayOf(string),
    assignmentGroup: AssignmentGroup.shape,
    description: string,
    dueAt: string,
    expectsSubmission: bool.isRequired,
    gradingType: string,
    gradeGroupStudentsIndividually: bool,
    groupCategoryId: number,
    groupSet: GroupSet.shape,
    lockAt: string,
    lockInfo: LockInfo.shape,
    modules: arrayOf(Module.shape),
    name: string.isRequired,
    nonDigitalSubmission: bool.isRequired,
    originalityReportVisibility: string,
    pointsPossible: number.isRequired,
    submissionTypes: arrayOf(string.isRequired),
    unlockAt: string,
  }),
}

export const AssignmentSubmissionsConnection = {
  fragment: gql`
    fragment AssignmentSubmissionsConnection on Assignment {
      submissionsConnection(
        last: 1
        filter: {states: [unsubmitted, graded, pending_review, submitted]}
      ) {
        nodes {
          ...Submission
        }
      }
    }
    ${Submission.fragment}
  `,

  shape: shape({
    submissionsConnection: shape({
      nodes: arrayOf(Submission.shape),
    }),
  }),
}

export const DefaultMocks = {
  Assignment: () => ({
    _id: '1',
    allowedAttempts: null,
    allowedExtensions: [],
    expectsSubmission: true,
    gradingType: 'points',
    nonDigitalSubmission: false,
    originalityReportVisibility: null,
    pointsPossible: 10,
    rubric: null,
    submissionsConnection: {
      nodes: [{}], // only return one submission
    },
    submissionTypes: ['online_upload'],
  }),
}

export const AssignmentMocks = {
  noSubmission: {
    expectsSubmission: false,
    nonDigitalSubmission: true,
    submissionTypes: ['none'],
  },
  onPaper: {
    expectsSubmission: false,
    nonDigitalSubmission: true,
    submissionTypes: ['on_paper'],
  },
}
