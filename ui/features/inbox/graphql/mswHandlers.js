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
import {graphql, HttpResponse} from 'msw'
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
        .reduce((obj, [k, v]) => ((obj[k] = v), obj), {})
    }),
  )
}

export const handlers = [
  graphql.query('GetConversationsQuery', ({variables}) => {
    const data = {
      legacyNode: {
        _id: '9',
        id: 'VXNlci05',
        conversationsConnection: {
          nodes: [
            {
              ...ConversationParticipant.mock(),
              conversation: Conversation.mock(),
            },
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'ConversationParticipantConnection',
        },
        conversationParticipantsConnection: {
          nodes: [],
        },
        __typename: 'User',
      },
    }

    if (variables.scope === 'sent') {
      data.legacyNode.conversationsConnection.nodes = [
        {
          ...ConversationParticipant.mock(),
          conversation: Conversation.mock(),
        },
        {
          ...ConversationParticipant.mock({
            _id: '249',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjQ5',
            label: 'starred',
            workflowState: 'unread',
          }),
          conversation: Conversation.mock({
            _id: '195',
            id: 'Q29udmVyc2F0aW9uLTE5NQ==',
            subject: 'h1',
          }),
        },
      ]
      data.legacyNode.conversationsConnection.nodes[1].conversation.conversationMessagesConnection.nodes =
        [
          ConversationMessage.mock({
            _id: '2693',
            id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjkz',
            createdAt: '2021-02-01T11:35:35-07:00',
            body: 'this is the second reply message',
          }),
        ]
      data.legacyNode.conversationsConnection.nodes[1].conversation.conversationParticipantsConnection.nodes =
        [
          ConversationParticipant.mock({
            _id: '250',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjUw',
            user: User.mock({
              _id: '8',
              pronouns: 'They/Them',
              name: 'Scotty Summers',
              shortName: 'Scotty Summers',
            }),
          }),
          ConversationParticipant.mock({
            _id: '249',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjQ5',
            label: 'starred',
            workflowState: 'unread',
          }),
        ]
    } else if (variables.course) {
      data.legacyNode.conversationParticipantsConnection.nodes = [
        {
          ...ConversationParticipant.mock({_id: '123', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMTA='}),
          conversation: Conversation.mock({
            _id: '10',
            id: 'Q29udmVyc2F0aW9uLTEw',
            subject: 'This is a course scoped conversation',
          }),
        },
      ]
      data.legacyNode.conversationsConnection.nodes[0].conversation.conversationMessagesConnection.nodes =
        [ConversationMessage.mock({body: 'Course scoped conversation message'})]
    } else if (variables.scope === 'null_nodes') {
      data.legacyNode.conversationsConnection.nodes[0].conversation = Conversation.mock({
        contextId: null,
        contextType: null,
        contextName: null,
        subject: null,
        conversationMessagesConnection: {nodes: []},
      })
    } else {
      data.legacyNode.conversationsConnection.nodes = [
        {
          ...ConversationParticipant.mock(
            {_id: '256', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2', workflowState: 'unread'},
            {_id: '257', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU8', workflowState: 'unread'},
          ),
          conversation: Conversation.mock({
            _id: '197',
            id: 'Q29udmVyc2F0aW9uLTE5Nw==',
            subject: 'This is an inbox conversation',
          }),
        },
      ]

      if (variables.scope === 'multipleConversations') {
        data.legacyNode.conversationsConnection.nodes = [
          {
            ...ConversationParticipant.mock(
              {_id: '256', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2', workflowState: 'unread'},
              {_id: '257', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU8', workflowState: 'unread'},
            ),
            conversation: Conversation.mock({
              _id: '197',
              id: 'Q29udmVyc2F0aW9uLTE5Nw==',
              subject: 'This is an inbox conversation',
            }),
          },
          {
            ...ConversationParticipant.mock(
              {_id: '256', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2', workflowState: 'unread'},
              {_id: '257', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU8', workflowState: 'unread'},
            ),
            conversation: Conversation.mock({
              _id: '905',
              id: '905',
              subject: 'This is an inbox conversation',
            }),
          },
          {
            ...ConversationParticipant.mock(
              {_id: '256', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2', workflowState: 'unread'},
              {_id: '257', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU8', workflowState: 'unread'},
            ),
            conversation: Conversation.mock({
              _id: '906',
              id: '906',
              subject: 'This is an inbox conversation',
            }),
          },
        ]
      }
      data.legacyNode.conversationsConnection.nodes[0].conversation.conversationMessagesConnection.nodes =
        [
          ConversationMessage.mock({
            _id: '2697',
            id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjk3',
            createdAt: '2021-03-16T12:09:23-06:00',
            body: 'this is a message for the inbox that is longer than the 90 characters that should be the max text length before truncation',
            author: User.mock({_id: '1', name: 'Charles Xavier', shortName: 'Charles Xavier'}),
            recipients: [
              User.mock({_id: '1', name: 'Charles Xavier', shortName: 'Charles Xavier'}),
            ],
          }),
          ConversationMessage.mock({
            _id: '2800',
            id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjj0',
            createdAt: '2021-03-16T12:09:23-05:00',
            body: 'Watch out for that Magneto guy',
            author: User.mock({_id: '1', name: 'Charles Xavier', shortName: 'Charles Xavier'}),
            recipients: [
              User.mock(),
              User.mock({_id: '1', name: 'Charles Xavier', shortName: 'Charles Xavier'}),
            ],
          }),
          ConversationMessage.mock({
            _id: '2801',
            id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjj1',
            createdAt: '2021-03-16T12:09:23-04:00',
            body: 'Wolverine is not so bad when you get to know him',
            author: User.mock({_id: '1', name: 'Charles Xavier', shortName: 'Charles Xavier'}),
            recipients: [
              User.mock(),
              User.mock({_id: '1', name: 'Charles Xavier', shortName: 'Charles Xavier'}),
            ],
          }),
        ]
      data.legacyNode.conversationsConnection.nodes[0].conversation.conversationParticipantsConnection.nodes =
        [
          ConversationParticipant.mock({
            _id: '255',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU1',
            user: User.mock({_id: '1', name: 'Charles Xavier', shortName: 'Charles Xavier'}),
            workflowState: 'unread',
          }),
          ConversationParticipant.mock({
            _id: '256',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2',
            workflowState: 'unread',
          }),
          ConversationParticipant.mock({
            _id: '257',
            id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU8',
            user: User.mock({_id: '1', name: 'Charles Xavier', shortName: 'Charles Xavier'}),
            workflowState: 'unread',
          }),
        ]
    }
    return HttpResponse.json({data})
  }),

  graphql.query('GetTotalRecipients', ({variables}) => {
    if (variables.context === null) {
      return HttpResponse.json({
        data: {legacyNode: {id: 'VXNlci0x', totalRecipients: 2, __typename: 'User'}},
      })
    }
    return HttpResponse.json({
      data: {legacyNode: {id: 'VXNlci0x', totalRecipients: 2, __typename: 'User'}},
    })
  }),

  graphql.query('GetUserInboxLabels', ({variables}) => {
    return HttpResponse.json({
      data: {legacyNode: {id: 'VXNlci0x', inboxLabels: ['LabelA', 'LabelB'], __typename: 'User'}},
    })
  }),

  graphql.query('GetConversationMessagesQuery', ({variables}) => {
    if (variables.conversationID === CONVERSATION_ID_WHERE_CAN_REPLY_IS_FALSE) {
      return HttpResponse.json({
        data: {legacyNode: Conversation.mock({canReply: false})},
      })
    }
    return HttpResponse.json({
      data: {legacyNode: Conversation.mock()},
    })
  }),

  graphql.query('GetSubmissionCommentsQuery', ({variables}) => {
    const data = {
      legacyNode: {
        _id: variables.submissionId || '1',
        submissionCommentsConnection: {
          nodes: [
            SubmissionComment.mock({
              _id: '1',
              comment: 'my student comment',
              htmlComment: '<p>my student comment</p>',
              author: User.mock({_id: '1', name: 'Student One'}),
              read: false
            })
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'SubmissionCommentConnection'
        },
        __typename: 'Submission'
      }
    }
    return HttpResponse.json({data})
  }),

  graphql.query('GetSubmissionComments', ({variables}) => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          _id: variables.submissionID,
          id: `Submission-${variables.submissionID}`,
          canReply: false,
          commentsConnection: {
            nodes: [
              {
                _id: '1',
                id: 'SubmissionComment-1',
                submissionId: variables.submissionID,
                createdAt: '2024-01-24T11:35:35-07:00',
                attempt: 1,
                canReply: false,
                author: {
                  _id: '1',
                  id: 'VXNlci0x',
                  name: 'Student Name',
                  shortName: 'Student',
                  pronouns: null,
                  avatarUrl: null,
                  __typename: 'User'
                },
                assignment: {
                  _id: '1',
                  id: 'QXNzaWdubWVudC0x',
                  name: 'Test Assignment',
                  htmlUrl: '/courses/1/assignments/1',
                  __typename: 'Assignment'
                },
                comment: 'my student comment',
                htmlComment: '<p>my student comment</p>',
                course: {
                  _id: '1',
                  id: 'Q291cnNlLTE=',
                  name: 'Test Course',
                  courseNickname: null,
                  contextName: 'Test Course',
                  assetString: 'course_1',
                  __typename: 'Course'
                },
                read: false,
                __typename: 'SubmissionComment'
              }
            ],
            pageInfo: {
              hasNextPage: false,
              endCursor: null,
              __typename: 'PageInfo'
            },
            __typename: 'SubmissionCommentConnection'
          },
          user: {
            _id: '1',
            __typename: 'User'
          },
          __typename: 'Submission'
        }
      }
    })
  }),

  graphql.query('GetSubmissionCommentsQuery', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          _id: '1',
          id: 'VXNlci0x',
          submissionCommentsConnection: {
            nodes: [
              {
                ...SubmissionComment.mock({
                  _id: '1',
                  comment: 'my student comment',
                  createdAt: '2024-01-24T11:35:35-07:00',
                }),
              },
            ],
            pageInfo: PageInfo.mock({hasNextPage: false}),
            __typename: 'SubmissionCommentConnection',
          },
          __typename: 'User',
        },
      },
    })
  }),

  graphql.query('ViewableSubmissionsQuery', () => {
    const data = {
      legacyNode: {
        _id: '9',
        id: 'VXNlci05',
        viewableSubmissionsConnection: {
          nodes: [
            {
              _id: '9',
              readState: null,
              commentsConnection: {
                nodes: [
                  {
                    _id: '1',
                    id: 'U3VibWlzc2lvbkNvbW1lbnQtMQ==',
                    submissionId: '3',
                    createdAt: '2022-04-04T12:19:38-06:00',
                    attempt: 0,
                    canReply: false,
                    author: User.mock(),
                    assignment: {
                      id: 'QXNzaWdubWVudC0x',
                      _id: '1',
                      name: 'test assignment',
                      __typename: 'Assignment',
                    },
                    comment: 'my student comment',
                    htmlComment: '<p>my student comment</p>',
                    course: Course.mock(),
                    read: true,
                    __typename: 'SubmissionComment',
                  },
                ],
                __typename: 'SubmissionCommentConnection',
              },
              __typename: 'Submission',
            },
            {
              _id: '10',
              readState: null,
              commentsConnection: {
                nodes: [
                  {
                    _id: '1',
                    id: 'U3VibWlzc2lvbkNvbW1lbnQtMQ==',
                    submissionId: '3',
                    createdAt: '2022-04-04T12:19:38-06:00',
                    attempt: 0,
                    canReply: false,
                    author: User.mock(),
                    assignment: {
                      id: 'QXNzaWdubWVudC0x',
                      _id: '1',
                      name: 'test assignment',
                      __typename: 'Assignment',
                    },
                    comment: 'my student comment',
                    htmlComment: '<p>my student comment</p>',
                    course: Course.mock(),
                    read: true,
                    __typename: 'SubmissionComment',
                  },
                ],
                __typename: 'SubmissionCommentConnection',
              },
              __typename: 'Submission',
            },
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'SubmissionConnection',
        },
        __typename: 'User',
      },
    }

    return HttpResponse.json({data})
  }),

  graphql.query('GetUserCourses', () => {
    const data = {
      legacyNode: {
        id: 'VXNlci05',
        email: 'hmccoy@xavierschool.com',
        favoriteGroupsConnection: {
          nodes: [
            Group.mock(),
            Group.mock({
              _id: '339',
              contextName: 'concluded_group',
              assetString: 'group_339',
              canMessage: false,
            }),
          ],
          __typename: 'GroupConnection',
        },
        favoriteCoursesConnection: {
          nodes: [Course.mock()],
          __typename: 'CourseConnection',
        },
        enrollments: [
          Enrollment.mock(),
          Enrollment.mock({
            course: Course.mock({
              _id: '196',
              contextName: 'Fighting Magneto 101',
              assetString: 'course_196',
            }),
          }),
          Enrollment.mock({
            course: Course.mock({
              _id: '197',
              contextName: 'Fighting Magneto 202',
              assetString: 'course_197',
            }),
            concluded: true,
          }),
          Enrollment.mock({
            course: Course.mock({
              _id: '198',
              contextName: 'Flying The Blackbird',
              assetString: 'course_198',
            }),
          }),
          Enrollment.mock({
            course: Course.mock({
              _id: '198',
              contextName: 'Flying The Blackbird',
              assetString: 'course_198',
            }),
          }),
          Enrollment.mock({
            course: Course.mock({
              _id: '198',
              contextName: 'Flying The Blackbird',
              assetString: 'course_198',
            }),
          }),
        ],
        __typename: 'User',
      },
    }
    return HttpResponse.json({data})
  }),

  graphql.query('GetAddressBookRecipients', ({variables}) => {
    const data = {
      legacyNode: {
        id: 'VXNlci0x',
        __typename: 'User',
      },
    }

    if (variables.context) {
      const recipients = {
        sendMessagesAll: true,
        contextsConnection: {
          nodes: [],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableContextConnection',
        },
        usersConnection: {
          nodes: [
            {
              _id: '1',
              id: 'TWVzc2FnZWFibGVVc2VyLTQx',
              name: 'Frederick Dukes',
              shortName: 'Frederick Dukes',
              pronouns: 'he/him',
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
                      __typename: 'Course',
                    },
                    __typename: 'Enrollment',
                  },
                ],
                __typename: 'EnrollmentConnection',
              },
              observerEnrollmentsConnection: null,
            },
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableUserConnection',
        },
        __typename: 'Recipients',
      }
      data.legacyNode.recipients = recipients
    } else if (variables.search === 'Fred') {
      const recipients = {
        sendMessagesAll: true,
        contextsConnection: {
          nodes: [],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableContextConnection',
        },
        usersConnection: {
          nodes: [
            {
              _id: '1',
              id: 'TWVzc2FnZWFibGVVc2VyLTQx',
              name: 'Frederick Dukes',
              shortName: 'Frederick Dukes',
              pronouns: 'he/him',
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
                      __typename: 'Course',
                    },
                    __typename: 'Enrollment',
                  },
                ],
                __typename: 'EnrollmentConnection',
              },
              observerEnrollmentsConnection: null,
            },
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableUserConnection',
        },
        __typename: 'Recipients',
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
              userCount: 3,
              __typename: 'MessageableContext',
            },
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableContextConnection',
        },
        usersConnection: {
          nodes: [
            {
              _id: '1',
              id: 'TWVzc2FnZWFibGVVc2VyLTQx',
              name: 'Frederick Dukes',
              shortName: 'Frederick Dukes',
              pronouns: 'he/him',
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
                      __typename: 'Course',
                    },
                    __typename: 'Enrollment',
                  },
                ],
                __typename: 'EnrollmentConnection',
              },
              observerEnrollmentsConnection: null,
            },
            {
              _id: '2',
              id: 'TWVzc2FnZWFibGVVc2VyLTY1',
              name: 'Trevor Fitzroy',
              shortName: 'Trevor Fitzroy',
              pronouns: 'he/him',
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
                      __typename: 'Course',
                    },
                    __typename: 'Enrollment',
                  },
                ],
                __typename: 'EnrollmentConnection',
              },
              observerEnrollmentsConnection: null,
            },
            {
              _id: '3',
              id: 'TWVzc2FnZWFibGVVc2VyLTMy',
              name: 'Null Forge',
              shortName: 'Null Forge',
              pronouns: 'he/him',
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
                      __typename: 'Course',
                    },
                    __typename: 'Enrollment',
                  },
                ],
                __typename: 'EnrollmentConnection',
              },
              observerEnrollmentsConnection: null,
            },
          ],
          pageInfo: PageInfo.mock({hasNextPage: false}),
          __typename: 'MessageableUserConnection',
        },
        __typename: 'Recipients',
      }
      data.legacyNode.recipients = recipients
    }
    return HttpResponse.json({data})
  }),

  graphql.query('GetRecipientsObservers', ({variables}) => {
    const data = {
      legacyNode: {
        id: 'VXNlci0x',
        __typename: 'User',
        recipientsObservers: null,
      },
    }

    if (variables.recipients.length > 0 && variables.contextCode) {
      data.recipientsObservers = {
        nodes: [
          {
            id: 'TWVzc2FnZWFibGVVc2VyLTM',
            name: 'observer',
            __typename: 'MessageableUser',
            _id: '3',
          },
        ],
      }
    }
    return HttpResponse.json({data})
  }),

  graphql.query('ReplyConversationQuery', () => {
    const data = {
      legacyNode: {
        ...Conversation.mock(),
      },
    }
    // Remove uneeded fields from response that are
    // automatically included through mocks
    delete data.legacyNode.contextId
    delete data.legacyNode.conversationParticipantsConnection

    return HttpResponse.json({data})
  }),

  graphql.mutation('CreateConversation', ({variables}) => {
    let data
    if (!variables.recipients || !variables.recipients.length) {
      data = {
        createConversation: null,
        errors: {
          attribute: 'message',
          message: 'Invalid recipients',
          __typename: 'ValidationError',
        },
        __typename: 'CreateConversationPayload',
      }
    } else {
      data = {
        createConversation: {
          conversations: [
            {
              ...ConversationParticipant.mock(),
              conversation: Conversation.mock({subject: variables.subject}),
            },
          ],
          errors: null,
          __typename: 'CreateConversationPayload',
        },
      }
    }

    return HttpResponse.json({data})
  }),

  graphql.mutation('AddConversationMessage', ({variables}) => {
    const CONV_ID_WITH_CONCLUDED_TEACHER_ERROR = '3'
    let data = {
      addConversationMessage: {
        conversationMessage: ConversationMessage.mock({body: variables.body}),
        errors: null,
        __typename: 'AddConversationMessagePayload',
      },
    }

    if (variables.conversationId === CONV_ID_WITH_CONCLUDED_TEACHER_ERROR) {
      data = {
        addConversationMessage: {
          conversationMessage: ConversationMessage.mock({body: variables.body}),
          errors: [
            {
              attribute: 'message',
              message:
                'The following recipients have no active enrollment in the course, ["Student 2"], unable to send messages',
              __typename: 'ValidationError',
            },
          ],
          __typename: 'AddConversationMessagePayload',
        },
      }
    }

    return HttpResponse.json({data})
  }),

  graphql.mutation('CreateSubmissionComment', ({variables}) => {
    const SUBMISSION_ID_THAT_RETURNS_ERROR = '440'
    const data = {
      createSubmissionComment: {
        submissionComment: SubmissionComment.mock({
          comment: variables.body,
          htmlComment: variables.body,
        }),
        errors: null,
        __typename: 'CreateSubmissionCommentPayload',
      },
    }

    if (variables.submissionId === SUBMISSION_ID_THAT_RETURNS_ERROR) {
      data.submissionComment = null
      data.errors = [
        {
          attribute: 'message',
          message: 'Some Generic Submission reply error',
          __typename: 'ValidationError',
        },
      ]
    }
    return HttpResponse.json({data})
  }),

  graphql.mutation('UpdateConversationParticipants', ({variables}) => {
    return HttpResponse.json({
      data: {
        updateConversationParticipants: {
          conversationParticipants: [
            mswAssign(
              {...ConversationParticipant.mock()},
              {
                id: variables.conversationId,
                read: variables.read,
              },
            ),
          ],
          errors: null,
          __typename: 'UpdateConversationParticipantsPayload',
        },
      },
    })
  }),
]

export const inboxSettingsHandlers = version => [
  graphql.query('GetMyInboxSettings', () => {
    const VERSION_THAT_RETURNS_INBOX_SETTINGS_WITH_OOO_ENABLED = 2
    const data = {
      myInboxSettings: {
        _id: '1',
        useSignature: false,
        signature: 'My signature',
        useOutOfOffice: false,
        outOfOfficeFirstDate: null,
        outOfOfficeLastDate: null,
        outOfOfficeSubject: 'OOO Subject',
        outOfOfficeMessage: 'OOO Message',
        __typename: 'InboxSettings',
      },
    }

    if (version === VERSION_THAT_RETURNS_INBOX_SETTINGS_WITH_OOO_ENABLED) {
      data.myInboxSettings.useOutOfOffice = true
    }

    return HttpResponse.json({data})
  }),

  graphql.mutation('UpdateMyInboxSettings', () => {
    const VERSION_THAT_RETURNS_INBOX_SETTINGS_MUTATION_ERROR = 1
    const data = {
      updateMyInboxSettings: {
        myInboxSettings: {
          _id: '1',
          useSignature: true,
          signature: 'My signature updated',
          useOutOfOffice: true,
          outOfOfficeFirstDate: null,
          outOfOfficeLastDate: null,
          outOfOfficeSubject: 'OOO Subject',
          outOfOfficeMessage: 'OOO Message',
          __typename: 'InboxSettings',
        },
        errors: null,
        __typename: 'UpdateMyInboxSettingsPayload',
      },
    }

    if (version === VERSION_THAT_RETURNS_INBOX_SETTINGS_MUTATION_ERROR) {
      data.updateMyInboxSettings.errors = [
        {
          attribute: 'message',
          message: 'GraphQL Error',
          __typename: 'NetworkError',
        },
      ]
    }

    return HttpResponse.json({data})
  }),
]
