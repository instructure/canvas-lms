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

import {Conversation} from './Conversation'
import {ConversationMessage} from './ConversationMessage'
import {ConversationParticipant} from './ConversationParticipant'
import {SubmissionComment} from './SubmissionComment'
import {Course} from './Course'
import {Enrollment} from './Enrollment'
import {graphql} from 'msw'
import {Group} from './Group'
import {User} from './User'
import {PageInfo} from './PageInfo'
import {CONVERSATION_ID_WHERE_CAN_REPLY_IS_FALSE} from '../util/constants'

// helper function that filters out undefined values in objects before assigning
const mswAssign = (target, ...objects) => {
  return Object.assign(
    target,
    ...objects.map(object => {
      return Object.entries(object)
        .filter(([_k, v]) => v !== undefined)
        .reduce((obj, [k, v]) => ((obj[k] = v), obj), {}) // eslint-disable-line no-sequences
    })
  )
}

export const handlers = [
  graphql.query('GetConversationsQuery', (req, res, ctx) => {
    const data = {
      legacyNode: {
        _id: '9',
        id: 'VXNlci05',
        conversationsConnection: {
          nodes: [
            {
              ...ConversationParticipant.mock(),
              conversation: Conversation.mock()
            }
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'ConversationParticipantConnection'
        },
        conversationParticipantsConnection: {
          nodes: []
        },
        __typename: 'User'
      }
    }

    if (req.variables.scope === 'sent') {
      data.legacyNode.conversationsConnection.nodes = [
        {
          ...ConversationParticipant.mock(),
          conversation: Conversation.mock()
        },
        {
          ...ConversationParticipant.mock({
            _id: '249',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjQ5',
            label: 'starred',
            workflowState: 'unread'
          }),
          conversation: Conversation.mock({
            _id: '195',
            id: 'Q29udmVyc2F0aW9uLTE5NQ==',
            subject: 'h1'
          })
        }
      ]
      data.legacyNode.conversationsConnection.nodes[1].conversation.conversationMessagesConnection.nodes =
        [
          ConversationMessage.mock({
            _id: '2693',
            id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjkz',
            createdAt: '2021-02-01T11:35:35-07:00',
            body: 'this is the second reply message'
          })
        ]
      data.legacyNode.conversationsConnection.nodes[1].conversation.conversationParticipantsConnection.nodes =
        [
          ConversationParticipant.mock({
            _id: '250',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjUw',
            user: User.mock({_id: '8', pronouns: 'They/Them', name: 'Scotty Summers'})
          }),
          ConversationParticipant.mock({
            _id: '249',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjQ5',
            label: 'starred',
            workflowState: 'unread'
          })
        ]
    } else if (req.variables.course) {
      data.legacyNode.conversationParticipantsConnection.nodes = [
        {
          ...ConversationParticipant.mock({_id: '123', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMTA='}),
          conversation: Conversation.mock({
            _id: '10',
            id: 'Q29udmVyc2F0aW9uLTEw',
            subject: 'This is a course scoped conversation'
          })
        }
      ]
      data.legacyNode.conversationsConnection.nodes[0].conversation.conversationMessagesConnection.nodes =
        [ConversationMessage.mock({body: 'Course scoped conversation message'})]
    } else {
      data.legacyNode.conversationsConnection.nodes = [
        {
          ...ConversationParticipant.mock(
            {_id: '256', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2', workflowState: 'unread'},
            {_id: '257', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU4', workflowState: 'unread'}
          ),
          conversation: Conversation.mock({
            _id: '197',
            id: 'Q29udmVyc2F0aW9uLTE5Nw==',
            subject: 'This is an inbox conversation'
          })
        }
      ]

      if (req.variables.scope === 'multipleConversations') {
        data.legacyNode.conversationsConnection.nodes = [
          {
            ...ConversationParticipant.mock(
              {_id: '256', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2', workflowState: 'unread'},
              {_id: '257', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU4', workflowState: 'unread'}
            ),
            conversation: Conversation.mock({
              _id: '197',
              id: 'Q29udmVyc2F0aW9uLTE5Nw==',
              subject: 'This is an inbox conversation'
            })
          },
          {
            ...ConversationParticipant.mock(
              {_id: '256', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2', workflowState: 'unread'},
              {_id: '257', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU4', workflowState: 'unread'}
            ),
            conversation: Conversation.mock({
              _id: '905',
              id: '905',
              subject: 'This is an inbox conversation'
            })
          },
          {
            ...ConversationParticipant.mock(
              {_id: '256', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2', workflowState: 'unread'},
              {_id: '257', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU4', workflowState: 'unread'}
            ),
            conversation: Conversation.mock({
              _id: '906',
              id: '906',
              subject: 'This is an inbox conversation'
            })
          }
        ]
      }
      data.legacyNode.conversationsConnection.nodes[0].conversation.conversationMessagesConnection.nodes =
        [
          ConversationMessage.mock({
            _id: '2697',
            id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjk3',
            createdAt: '2021-03-16T12:09:23-06:00',
            body: 'this is a message for the inbox',
            author: User.mock({_id: '1', name: 'Charles Xavier'}),
            recipients: [User.mock({_id: '1', name: 'Charels Xavier'})]
          }),
          ConversationMessage.mock({
            _id: '2800',
            id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjj0',
            createdAt: '2021-03-16T12:09:23-05:00',
            body: 'Watch out for that Magneto guy',
            author: User.mock({_id: '1', name: 'Charles Xavier'}),
            recipients: [User.mock(), User.mock({_id: '1', name: 'Charles Xavier'})]
          }),
          ConversationMessage.mock({
            _id: '2801',
            id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjj1',
            createdAt: '2021-03-16T12:09:23-04:00',
            body: 'Wolverine is not so bad when you get to know him',
            author: User.mock({_id: '1', name: 'Charles Xavier'}),
            recipients: [User.mock(), User.mock({_id: '1', name: 'Charles Xavier'})]
          })
        ]
      data.legacyNode.conversationsConnection.nodes[0].conversation.conversationParticipantsConnection.nodes =
        [
          ConversationParticipant.mock({
            _id: '255',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU1',
            user: User.mock({_id: '1', name: 'Charles Xavier'}),
            workflowState: 'unread'
          }),
          ConversationParticipant.mock({
            _id: '256',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2',
            workflowState: 'unread'
          }),
          ConversationParticipant.mock({
            _id: '257',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU4',
            user: User.mock({_id: '1', name: 'Charles Xavier'}),
            workflowState: 'unread'
          })
        ]
    }
    return res(ctx.data(data))
  }),

  graphql.query('GetConversationMessagesQuery', (req, res, ctx) => {
    if (req.variables.conversationID === CONVERSATION_ID_WHERE_CAN_REPLY_IS_FALSE) {
      return res(ctx.data({legacyNode: Conversation.mock({canReply: false})}))
    }
    return res(ctx.data({legacyNode: Conversation.mock()}))
  }),

  graphql.query('GetSubmissionComments', (req, res, ctx) => {
    const data = {
      legacyNode: {
        _id: '1',
        id: 'VXNlci06',
        commentsConnection: {
          nodes: [
            {
              _id: '1',
              id: 'U3VibWlzc2lvbkNvbW1lbnQtMQ==',
              submissionId: '3',
              createdAt: '2022-04-04T12:19:38-06:00',
              attempt: 0,
              author: User.mock(),
              assignment: {
                id: 'QXNzaWdubWVudC0x',
                _id: '1',
                name: 'test assignment',
                __typename: 'Assignment'
              },
              comment: 'my student comment',
              course: Course.mock(),
              read: true,
              __typename: 'SubmissionComment'
            }
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'SubmissionCommentConnection'
        },
        user: {
          _id: '75',
          __typename: 'User'
        },
        __typename: 'Submission'
      }
    }

    return res(ctx.data(data))
  }),

  graphql.query('ViewableSubmissionsQuery', (req, res, ctx) => {
    const data = {
      legacyNode: {
        _id: '9',
        id: 'VXNlci05',
        viewableSubmissionsConnection: {
          nodes: [
            {
              _id: '9',
              commentsConnection: {
                nodes: [
                  {
                    _id: '1',
                    id: 'U3VibWlzc2lvbkNvbW1lbnQtMQ==',
                    submissionId: '3',
                    createdAt: '2022-04-04T12:19:38-06:00',
                    attempt: 0,
                    author: User.mock(),
                    assignment: {
                      id: 'QXNzaWdubWVudC0x',
                      _id: '1',
                      name: 'test assignment',
                      __typename: 'Assignment'
                    },
                    comment: 'my student comment',
                    course: Course.mock(),
                    read: true,
                    __typename: 'SubmissionComment'
                  }
                ],
                __typename: 'SubmissionCommentConnection'
              },
              __typename: 'Submission'
            },
            {
              _id: '10',
              commentsConnection: {
                nodes: [
                  {
                    _id: '1',
                    id: 'U3VibWlzc2lvbkNvbW1lbnQtMQ==',
                    submissionId: '3',
                    createdAt: '2022-04-04T12:19:38-06:00',
                    attempt: 0,
                    author: User.mock(),
                    assignment: {
                      id: 'QXNzaWdubWVudC0x',
                      _id: '1',
                      name: 'test assignment',
                      __typename: 'Assignment'
                    },
                    comment: 'my student comment',
                    course: Course.mock(),
                    read: true,
                    __typename: 'SubmissionComment'
                  }
                ],
                __typename: 'SubmissionCommentConnection'
              },
              __typename: 'Submission'
            }
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'SubmissionConnection'
        },
        __typename: 'User'
      }
    }

    return res(ctx.data(data))
  }),

  graphql.query('GetUserCourses', (req, res, ctx) => {
    const data = {
      legacyNode: {
        id: 'VXNlci05',
        email: 'hmccoy@xavierschool.com',
        favoriteGroupsConnection: {
          nodes: [Group.mock()],
          __typename: 'GroupConnection'
        },
        favoriteCoursesConnection: {
          nodes: [Course.mock()],
          __typename: 'CourseConnection'
        },
        enrollments: [
          Enrollment.mock(),
          Enrollment.mock({
            course: Course.mock({
              _id: '196',
              contextName: 'Fighting Magneto 101',
              assetString: 'course_196'
            })
          }),
          Enrollment.mock({
            course: Course.mock({
              _id: '197',
              contextName: 'Fighting Magneto 202',
              assetString: 'course_197'
            })
          }),
          Enrollment.mock({
            course: Course.mock({
              _id: '198',
              contextName: 'Flying The Blackbird',
              assetString: 'course_198'
            })
          })
        ],
        __typename: 'User'
      }
    }
    return res(ctx.data(data))
  }),

  graphql.query('GetAddressBookRecipients', (req, res, ctx) => {
    const data = {
      legacyNode: {
        id: 'VXNlci0x',
        __typename: 'User'
      }
    }

    if (req.variables.context) {
      const recipients = {
        sendMessagesAll: true,
        contextsConnection: {
          nodes: [],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableContextConnection'
        },
        usersConnection: {
          nodes: [
            {
              _id: '1',
              id: 'TWVzc2FnZWFibGVVc2VyLTQx',
              name: 'Frederick Dukes',
              __typename: 'MessageableUser',
              commonCoursesConnection: {
                nodes: [
                  {
                    _id: '11',
                    id: 'RW5yb2xsbWVudC0xMQ==',
                    state: 'active',
                    type: 'StudentEnrollment',
                    course: {
                      name: 'Test course',
                      id: 'Q291cnNlLTE=',
                      _id: '196',
                      __typename: 'Course'
                    },
                    __typename: 'Enrollment'
                  }
                ],
                __typename: 'EnrollmentConnection'
              }
            }
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableUserConnection'
        },
        __typename: 'Recipients'
      }
      data.legacyNode.recipients = recipients
    } else if (req.variables.search === 'Fred') {
      const recipients = {
        sendMessagesAll: true,
        contextsConnection: {
          nodes: [],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableContextConnection'
        },
        usersConnection: {
          nodes: [
            {
              _id: '1',
              id: 'TWVzc2FnZWFibGVVc2VyLTQx',
              name: 'Frederick Dukes',
              __typename: 'MessageableUser',
              commonCoursesConnection: {
                nodes: [
                  {
                    _id: '11',
                    id: 'RW5yb2xsbWVudC0xMQ==',
                    state: 'active',
                    type: 'StudentEnrollment',
                    course: {
                      name: 'Test course',
                      id: 'Q291cnNlLTE=',
                      _id: '196',
                      __typename: 'Course'
                    },
                    __typename: 'Enrollment'
                  }
                ],
                __typename: 'EnrollmentConnection'
              }
            }
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableUserConnection'
        },
        __typename: 'Recipients'
      }
      data.legacyNode.recipients = recipients
    } else {
      const recipients = {
        sendMessagesAll: true,
        contextsConnection: {
          nodes: [
            {
              id: 'course_FnZW',
              name: 'Testing 101',
              __typename: 'MessageableUser'
            }
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableContextConnection'
        },
        usersConnection: {
          nodes: [
            {
              _id: '1',
              id: 'TWVzc2FnZWFibGVVc2VyLTQx',
              name: 'Frederick Dukes',
              __typename: 'MessageableUser',
              commonCoursesConnection: {
                nodes: [
                  {
                    _id: '11',
                    id: 'RW5yb2xsbWVudC0xMQ==',
                    state: 'active',
                    type: 'StudentEnrollment',
                    course: {
                      name: 'Test course',
                      id: 'Q291cnNlLTE=',
                      _id: '196',
                      __typename: 'Course'
                    },
                    __typename: 'Enrollment'
                  }
                ],
                __typename: 'EnrollmentConnection'
              }
            },
            {
              _id: '2',
              id: 'TWVzc2FnZWFibGVVc2VyLTY1',
              name: 'Trevor Fitzroy',
              __typename: 'MessageableUser',
              commonCoursesConnection: {
                nodes: [
                  {
                    _id: '11',
                    id: 'RW5yb2xsbWVudC0xMQ==',
                    state: 'active',
                    type: 'StudentEnrollment',
                    course: {
                      name: 'Test course',
                      id: 'Q291cnNlLTE=',
                      _id: '196',
                      __typename: 'Course'
                    },
                    __typename: 'Enrollment'
                  }
                ],
                __typename: 'EnrollmentConnection'
              }
            },
            {
              _id: '3',
              id: 'TWVzc2FnZWFibGVVc2VyLTMy',
              name: 'Null Forge',
              __typename: 'MessageableUser',
              commonCoursesConnection: {
                nodes: [
                  {
                    _id: '11',
                    id: 'RW5yb2xsbWVudC0xMQ==',
                    state: 'active',
                    type: 'StudentEnrollment',
                    course: {
                      name: 'Test course',
                      id: 'Q291cnNlLTE=',
                      _id: '196',
                      __typename: 'Course'
                    },
                    __typename: 'Enrollment'
                  }
                ],
                __typename: 'EnrollmentConnection'
              }
            }
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableUserConnection'
        },
        __typename: 'Recipients'
      }
      data.legacyNode.recipients = recipients
    }
    return res(ctx.data(data))
  }),

  graphql.query('ReplyConversationQuery', (req, res, ctx) => {
    const data = {
      legacyNode: {
        ...Conversation.mock()
      }
    }
    // Remove uneeded fields from response that are
    // automatically included through mocks
    delete data.legacyNode.contextId
    delete data.legacyNode.contextType
    delete data.legacyNode.conversationParticipantsConnection

    return res(ctx.data(data))
  }),

  graphql.mutation('CreateConversation', (req, res, ctx) => {
    let data
    if (!req.variables.recipients || !req.variables.recipients.length) {
      data = {
        createConversation: null,
        errors: {
          attribute: 'message',
          message: 'Invalid recipients',
          __typename: 'ValidationError'
        },
        __typename: 'CreateConversationPayload'
      }
    } else {
      data = {
        createConversation: {
          conversations: [
            {
              ...ConversationParticipant.mock(),
              conversation: Conversation.mock({subject: req.variables.subject})
            }
          ],
          errors: null,
          __typename: 'CreateConversationPayload'
        }
      }
    }

    return res(ctx.data(data))
  }),

  graphql.mutation('AddConversationMessage', (req, res, ctx) => {
    const CONV_ID_WITH_CONCLUDED_TEACHER_ERROR = '3'
    let data = {
      addConversationMessage: {
        conversationMessage: ConversationMessage.mock({body: req.variables.body}),
        errors: null,
        __typename: 'AddConversationMessagePayload'
      }
    }

    if (req.variables.conversationId === CONV_ID_WITH_CONCLUDED_TEACHER_ERROR) {
      data = {
        addConversationMessage: {
          conversationMessage: ConversationMessage.mock({body: req.variables.body}),
          errors: [
            {
              attribute: 'message',
              message:
                'The following recipients have no active enrollment in the course, ["Student 2"], unable to send messages',
              __typename: 'ValidationError'
            }
          ],
          __typename: 'AddConversationMessagePayload'
        }
      }
    }

    return res(ctx.data(data))
  }),

  graphql.mutation('CreateSubmissionComment', (req, res, ctx) => {
    const SUBMISSION_ID_THAT_RETURNS_ERROR = '440'
    const data = {
      createSubmissionComment: {
        submissionComment: SubmissionComment.mock({comment: req.variables.body}),
        errors: null,
        __typename: 'CreateSubmissionCommentPayload'
      }
    }

    if (req.variables.submissionId === SUBMISSION_ID_THAT_RETURNS_ERROR) {
      data.submissionComment = null
      data.errors = [
        {
          attribute: 'message',
          message: 'Some Generic Submission reply error',
          __typename: 'ValidationError'
        }
      ]
    }
    return res(ctx.data(data))
  }),

  graphql.mutation('UpdateConversationParticipants', (req, res, ctx) => {
    return res(
      ctx.data({
        updateConversationParticipants: {
          conversationParticipants: [
            mswAssign(
              {...ConversationParticipant.mock()},
              {
                id: req.body.variables.conversationId,
                read: req.body.variables.read
              }
            )
          ],
          errors: null,
          __typename: 'UpdateConversationParticipantsPayload'
        }
      })
    )
  })
]
