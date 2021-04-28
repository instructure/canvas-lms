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
import {Course} from './Course'
import {Enrollment} from './Enrollment'
import {graphql} from 'msw'
import {Group} from './Group'
import {User} from './User'

export const handlers = [
  graphql.query('GetConversationsQuery', (req, res, ctx) => {
    const data = {
      legacyNode: {
        _id: '9',
        id: 'VXNlci05',
        conversationsConnection: {
          nodes: [],
          __typename: 'ConversationParticipantConnection'
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
            subject: 'h1'
          })
        }
      ]
      data.legacyNode.conversationsConnection.nodes[1].conversation.conversationMessagesConnection.nodes = [
        ConversationMessage.mock({
          _id: '2693',
          id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjkz',
          createdAt: '2021-02-01T11:35:35-07:00',
          body: 'this is the second reply message'
        })
      ]
      data.legacyNode.conversationsConnection.nodes[1].conversation.conversationParticipantsConnection.nodes = [
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
            subject: 'This is a course scoped conversation'
          })
        }
      ]
      data.legacyNode.conversationsConnection.nodes[0].conversation.conversationMessagesConnection.nodes = [
        ConversationMessage.mock({body: 'Course scoped conversation message'})
      ]
    } else {
      data.legacyNode.conversationsConnection.nodes = [
        {
          ...ConversationParticipant.mock({_id: '256', id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2'}),
          conversation: Conversation.mock({_id: '197', subject: 'This is an inbox conversation'})
        }
      ]
      data.legacyNode.conversationsConnection.nodes[0].conversation.conversationMessagesConnection.nodes = [
        ConversationMessage.mock({
          _id: '2697',
          id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjk3',
          createdAt: '2021-03-16T12:09:23-06:00',
          body: 'this is a message for the inbox',
          author: User.mock({_id: '1', name: 'Charles Xavier'}),
          recipients: [User.mock({_id: '1', name: 'Charels Xavier'})]
        })
      ]
      data.legacyNode.conversationsConnection.nodes[0].conversation.conversationParticipantsConnection.nodes = [
        ConversationParticipant.mock({
          _id: '255',
          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU1',
          user: User.mock({_id: '1', name: 'Charles Xavier'})
        }),
        ConversationParticipant.mock({
          _id: '256',
          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU2'
        })
      ]
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
  })
]
