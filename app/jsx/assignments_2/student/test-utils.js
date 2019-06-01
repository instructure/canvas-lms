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
import {CREATE_SUBMISSION_COMMENT, SUBMISSION_COMMENT_QUERY} from './assignmentData'

export function mockAssignment(overrides = {}) {
  return {
    _id: '22',
    description: '<p>description</p>',
    dueAt: '2018-07-11T18:59:59-06:00',
    lockAt: null,
    name: 'Assignment',
    pointsPossible: 10,
    muted: false,
    unlockAt: null,
    gradingType: 'points',
    allowedAttempts: null,
    allowedExtensions: [],
    assignmentGroup: {
      name: 'Assignments',
      __typename: 'AssignmentGroup'
    },
    env: {
      assignmentUrl: '/test/assignment',
      moduleUrl: '/test/module',
      currentUser: {
        display_name: 'optimistic user',
        avatar_image_url: 'http://awesome.url.thing'
      },
      modulePrereq: null,
      courseId: '3',
      __typename: 'env'
    },
    lockInfo: {
      isLocked: true,
      __typename: 'LockInfo'
    },
    modules: [],
    submissionsConnection: {
      nodes: [
        {
          _id: '3',
          commentsConnection: {
            __typename: 'CommentsConnection',
            nodes: [
              {
                __typename: 'Comment',
                _id: '1',
                attachments: [],
                comment: 'comment comment',
                updatedAt: '2019-03-05T23:09:36-07:00',
                author: {
                  __typename: 'Author',
                  avatarUrl: 'example.com',
                  shortName: 'bob builder'
                }
              }
            ]
          },
          id: '3',
          deductedPoints: 3,
          enteredGrade: '9',
          grade: '6',
          latePolicyStatus: 'late',
          state: 'submitted',
          submissionStatus: 'late',
          submittedAt: '2019-02-20T15:12:33-07:00',
          gradingStatus: 'graded',
          __typename: 'Sumbission'
        }
      ],
      __typename: 'SubmissionConnection'
    },
    __typename: 'Assignment',
    ...overrides
  }
}

export function mockComments(overrides = {}) {
  return {
    __typename: 'Submission',
    commentsConnection: {
      __typename: 'CommentsConnection',
      nodes: [
        {
          __typename: 'SubmissionComment',
          _id: '1',
          attachments: [],
          comment: 'comment comment',
          mediaObject: null,
          updatedAt: '2019-03-05T23:09:36-07:00',
          author: {
            __typename: 'User',
            avatarUrl: 'example.com',
            shortName: 'bob builder'
          }
        }
      ]
    },
    ...overrides
  }
}

export function mockMultipleAttachments() {
  return [
    {
      _id: '1',
      displayName: 'awesome-test-image1.png',
      mimeClass: 'data',
      url: 'fake_url',
      __typename: 'Attachment'
    },
    {
      _id: '2',
      displayName: 'awesome-test-image2.png',
      mimeClass: 'data',
      url: 'fake_url',
      __typename: 'Attachment'
    },
    {
      _id: '3',
      displayName: 'awesome-test-image3.png',
      mimeClass: 'data',
      url: 'fake_url',
      __typename: 'Attachment'
    }
  ]
}

export function singleMediaObject(overrides = {}) {
  return {
    __typename: 'MediaObject',
    id: '9',
    title: 'video media comment',
    mediaType: 'video/mp4',
    mediaSources: {
      __typename: 'MediaSource',
      src: 'www.blah.com',
      type: 'video/mp4'
    },
    ...overrides
  }
}

export function singleComment(overrides = {}) {
  return {
    _id: '1',
    attachments: [],
    comment: 'comment comment',
    updatedAt: '2019-03-05T23:09:36-07:00',
    author: {
      __typename: 'Author',
      avatarUrl: 'example.com',
      shortName: 'bob builder'
    },
    ...overrides
  }
}

export function singleAttachment(overrides = {}) {
  return {
    __typename: 'Attachment',
    _id: '20',
    displayName: 'lookatme.pdf',
    mimeClass: 'pdf',
    url: 'https://some-awesome/url/goes/here',
    ...overrides
  }
}

export function commentGraphqlMock(comments) {
  return [
    {
      request: {
        query: SUBMISSION_COMMENT_QUERY,
        variables: {
          submissionId: mockAssignment().submissionsConnection.nodes[0].id.toString()
        }
      },
      result: {
        data: {
          submissionComments: comments
        }
      }
    },
    {
      request: {
        query: CREATE_SUBMISSION_COMMENT,
        variables: {
          id: '3',
          comment: 'lion',
          fileIds: []
        }
      },
      result: {
        data: {
          createSubmissionComment: {
            submissionComment: {
              _id: '3',
              comment: 'lion',
              updatedAt: new Date().toISOString(),
              attachments: [],
              author: {
                avatarUrl: 'whatever',
                shortName: 'sent user',
                __typename: 'User'
              },
              mediaObject: null,
              __typename: 'SubmissionComment'
            },
            __typename: 'CreateSubmissionCommentPayload'
          }
        }
      }
    },
    {
      request: {
        query: CREATE_SUBMISSION_COMMENT,
        variables: {
          id: '3',
          comment: 'lion',
          fileIds: ['1', '2', '3']
        }
      },
      result: {
        data: {
          createSubmissionComment: {
            submissionComment: {
              _id: '3',
              comment: 'lion',
              updatedAt: new Date().toISOString(),
              attachments: mockMultipleAttachments(),
              author: {
                avatarUrl: 'whatever',
                shortName: 'sent user',
                __typename: 'User'
              },
              mediaObject: null,
              __typename: 'SubmissionComment'
            },
            __typename: 'CreateSubmissionCommentPayload'
          }
        }
      }
    }
  ]
}
