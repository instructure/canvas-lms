/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import gql from 'graphql-tag'

import {Conversation} from './Conversation'
import {ConversationMessage} from './ConversationMessage'
import {ConversationParticipant} from './ConversationParticipant'
import {Enrollment} from './Enrollment'
import {Course} from './Course'
import {Group} from './Group'
import {SubmissionComment} from './SubmissionComment'
import {PageInfo} from './PageInfo'

export const ADDRESS_BOOK_RECIPIENTS = gql`
  query GetAddressBookRecipients(
    $userID: ID!
    $context: String
    $search: String
    $afterUser: String
    $afterContext: String
    $courseContextCode: String!
  ) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        id
        recipients(context: $context, search: $search) {
          sendMessagesAll
          contextsConnection(first: 20, after: $afterContext) {
            nodes {
              id
              name
            }
            pageInfo {
              ...PageInfo
            }
          }
          usersConnection(first: 20, after: $afterUser) {
            nodes {
              _id
              id
              name
              shortName
              observerEnrollmentsConnection(contextCode: $courseContextCode) {
                nodes {
                  associatedUser {
                    _id
                    name
                  }
                }
              }
            }
            pageInfo {
              ...PageInfo
            }
          }
        }
      }
    }
  }
  ${PageInfo.fragment}
`

// This query is used for the compose modal
export const ADDRESS_BOOK_RECIPIENTS_WITH_COMMON_COURSES = gql`
  query GetAddressBookRecipients(
    $userID: ID!
    $context: String
    $search: String
    $afterUser: String
    $afterContext: String
    $courseContextCode: String!
  ) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        id
        recipients(context: $context, search: $search) {
          sendMessagesAll
          contextsConnection(first: 20, after: $afterContext) {
            nodes {
              id
              name
              userCount
            }
            pageInfo {
              ...PageInfo
            }
          }
          usersConnection(first: 20, after: $afterUser) {
            nodes {
              _id
              id
              name
              shortName
              commonCoursesConnection {
                nodes {
                  _id
                  id
                  state
                  type
                  course {
                    name
                    id
                    _id
                  }
                }
              }
              observerEnrollmentsConnection(contextCode: $courseContextCode) {
                nodes {
                  associatedUser {
                    _id
                    name
                  }
                }
              }
            }
            pageInfo {
              ...PageInfo
            }
          }
        }
      }
    }
  }
  ${PageInfo.fragment}
`

export const TOTAL_RECIPIENTS = gql`
  query GetTotalRecipients($userID: ID!, $context: String) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        id
        totalRecipients(context: $context)
      }
    }
  }
`

export const USER_INBOX_LABELS_QUERY = gql`
  query GetUserInboxLabels($userID: ID!) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        id
        inboxLabels
      }
    }
  }
`

export const CONVERSATIONS_QUERY = gql`
  query GetConversationsQuery(
    $userID: ID!
    $filter: [String!]
    $scope: String = ""
    $afterConversation: String
  ) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        _id
        id
        conversationsConnection(
          scope: $scope # e.g. archived
          filter: $filter # e.g. [user_1, course_1]
          first: 20
          after: $afterConversation
        ) {
          nodes {
            ...ConversationParticipant
            conversation {
              ...Conversation
              conversationMessagesConnection(first: 1) {
                nodes {
                  ...ConversationMessage
                }
              }
              conversationMessagesCount
            }
          }
          pageInfo {
            ...PageInfo
          }
        }
      }
    }
  }
  ${ConversationParticipant.fragment}
  ${Conversation.fragment}
  ${ConversationMessage.fragment}
  ${PageInfo.fragment}
`

export const CONVERSATION_MESSAGES_QUERY = gql`
  query GetConversationMessagesQuery($conversationID: ID!, $afterMessage: String) {
    legacyNode(_id: $conversationID, type: Conversation) {
      ... on Conversation {
        ...Conversation
        canReply
        conversationMessagesConnection(first: 20, after: $afterMessage) {
          nodes {
            ...ConversationMessage
          }
          pageInfo {
            ...PageInfo
          }
        }
        contextName
      }
    }
  }
  ${Conversation.fragment}
  ${ConversationMessage.fragment}
  ${PageInfo.fragment}
`

export const COURSES_QUERY = gql`
  query GetUserCourses($userID: ID!) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        id
        email
        favoriteGroupsConnection {
          nodes {
            ...Group
          }
        }
        favoriteCoursesConnection {
          nodes {
            ...Course
          }
        }
        enrollments {
          ...Enrollment
        }
      }
    }
  }
  ${Enrollment.fragment}
  ${Course.fragment}
  ${Group.fragment}
`

export const REPLY_CONVERSATION_QUERY = gql`
  query ReplyConversationQuery(
    $conversationID: ID!
    $participants: [ID!]
    $createdBefore: DateTime
    $first: Int
  ) {
    legacyNode(_id: $conversationID, type: Conversation) {
      ... on Conversation {
        id
        _id
        contextName
        contextAssetString
        contextType
        subject
        conversationMessagesConnection(
          participants: $participants
          createdBefore: $createdBefore
          first: $first
        ) {
          nodes {
            ...ConversationMessage
          }
        }
      }
    }
  }
  ${ConversationMessage.fragment}
`
export const VIEWABLE_SUBMISSIONS_QUERY = gql`
  query ViewableSubmissionsQuery(
    $userID: ID!
    $sort: SubmissionCommentsSortOrderType
    $allComments: Boolean = true
    $afterSubmission: String
    $filter: [String!]
  ) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        _id
        id
        viewableSubmissionsConnection(first: 20, after: $afterSubmission, filter: $filter) {
          nodes {
            _id
            readState
            commentsConnection(sortOrder: $sort, filter: {allComments: $allComments}) {
              nodes {
                ...SubmissionComment
              }
            }
          }
          pageInfo {
            ...PageInfo
          }
        }
      }
    }
  }
  ${SubmissionComment.fragment}
  ${PageInfo.fragment}
`

export const SUBMISSION_COMMENTS_QUERY = gql`
  query GetSubmissionComments(
    $submissionID: ID!
    $sort: SubmissionCommentsSortOrderType
    $allComments: Boolean = true
    $afterComment: String
  ) {
    legacyNode(_id: $submissionID, type: Submission) {
      ... on Submission {
        _id
        id
        commentsConnection(
          sortOrder: $sort
          filter: {allComments: $allComments}
          first: 20
          after: $afterComment
        ) {
          nodes {
            ...SubmissionComment
          }
          pageInfo {
            ...PageInfo
          }
        }
        user {
          _id
        }
      }
    }
  }
  ${SubmissionComment.fragment}
  ${PageInfo.fragment}
`

export const RECIPIENTS_OBSERVERS_QUERY = gql`
  query GetRecipientsObservers($userID: ID!, $contextCode: String!, $recipientIds: [String!]!) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        id
        recipientsObservers(contextCode: $contextCode, recipientIds: $recipientIds) {
          nodes {
            id
            name
            _id
          }
        }
      }
    }
  }
`
