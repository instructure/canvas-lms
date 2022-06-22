/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

export const responsiveQuerySizes = ({mobile = false, tablet = false, desktop = false} = {}) => {
  const querySizes = {}
  if (mobile) {
    querySizes.mobile = {maxWidth: '767px'}
  }
  if (tablet) {
    querySizes.tablet = {minWidth: mobile ? '768px' : '0px'}
  }
  if (desktop) {
    querySizes.desktop = {minWidth: tablet ? '1024px' : '768px'}
  }
  return querySizes
}

// Takes in data from either a VIEWABLE_SUBMISSIONS_QUERY or CONVERSATIONS_QUERY
// Outputs an inbox conversation wrapper
export const inboxConversationsWrapper = (data, isSubmissionComments = false) => {
  const inboxConversations = []
  if (data) {
    data.forEach(conversation => {
      const inboxConversation = {}
      if (isSubmissionComments) {
        const newestSubmissionComment = conversation?.commentsConnection?.nodes[0]
        inboxConversation._id = conversation?._id
        inboxConversation.subject =
          newestSubmissionComment?.course.contextName +
          ' - ' +
          newestSubmissionComment?.assignment.name
        inboxConversation.lastMessageCreatedAt = newestSubmissionComment?.createdAt
        inboxConversation.lastMessageContent = newestSubmissionComment?.comment
        inboxConversation.participantString = getParticipantsString(
          conversation?.commentsConnection.nodes,
          isSubmissionComments
        )
        inboxConversation.messages = conversation?.commentsConnection.nodes
      } else {
        inboxConversation._id = conversation?.conversation?._id
        inboxConversation.subject = conversation?.conversation?.subject
        inboxConversation.lastMessageCreatedAt =
          conversation?.conversation.conversationMessagesConnection.nodes[0].createdAt
        inboxConversation.lastMessageContent =
          conversation?.conversation.conversationMessagesConnection.nodes[0].body
        inboxConversation.workflowState = conversation?.workflowState
        inboxConversation.label = conversation?.label
        inboxConversation.messages =
          conversation?.conversation?.conversationMessagesConnection.nodes
        inboxConversation.participants =
          conversation.conversation.conversationParticipantsConnection.nodes
        inboxConversation.participantString = getParticipantsString(
          inboxConversation?.participants,
          isSubmissionComments,
          inboxConversation?.messages[inboxConversation.messages.length - 1].author.name
        )
        inboxConversation.isPrivate = conversation?.conversation?.isPrivate
      }
      inboxConversations.push(inboxConversation)
    })
  }
  return inboxConversations
}

// Takes in data from the CONVERSATION_MESSAGES_QUERY or SUBMISSION_COMMENTS_QUERY
// Outputs an an object that contains an array of wrapped inboxMessages and the contextName
export const inboxMessagesWrapper = (data, isSubmissionComments = false) => {
  const inboxMessages = []
  let contextName = ''
  let canReply = true
  const submissionCommentURL = `/courses/${data?.commentsConnection?.nodes[0]?.course._id}/assignments/${data?.commentsConnection?.nodes[0]?.assignment._id}/submissions/${data?.user?._id}`
  if (data) {
    const messages = isSubmissionComments
      ? data?.commentsConnection?.nodes
      : data?.conversationMessagesConnection?.nodes
    messages.forEach(message => {
      const inboxMessage = {}
      if (isSubmissionComments) {
        inboxMessage.id = message?.id
        inboxMessage._id = message?._id
        inboxMessage.contextName = message?.contextName
        inboxMessage.createdAt = message?.createdAt
        inboxMessage.author = message?.author
        inboxMessage.recipients = []
        inboxMessage.body = message?.comment
        inboxMessage.attachmentsConnection = null
        inboxMessage.mediaComment = null
        contextName = message?.course?.contextName
      } else {
        inboxMessage.id = message?.id
        inboxMessage._id = message?._id
        inboxMessage.contextName = message?.contextName
        inboxMessage.createdAt = message?.createdAt
        inboxMessage.author = message?.author
        inboxMessage.recipients = message?.recipients
        inboxMessage.body = message?.body
        inboxMessage.attachmentsConnection = message?.attachmentsConnection
        inboxMessage.mediaComment = message?.mediaComment
        contextName = data?.contextName
        canReply = data?.canReply
      }
      inboxMessages.push(inboxMessage)
    })
  }
  return {inboxMessages, contextName, submissionCommentURL, canReply}
}

const getSubmissionCommentsParticipantString = messages => {
  const uniqueParticipants = []
  messages.forEach(message => {
    if (!uniqueParticipants.some(x => x._id === message.author._id)) {
      uniqueParticipants.push({_id: message.author._id, authorName: message.author.name})
    }
  })
  const uniqueParticipantNames = uniqueParticipants.map(participant => participant.authorName)
  return uniqueParticipantNames.join(', ')
}
const getConversationParticipantString = (participants, conversationOwnerName) => {
  const participantString = participants
    .filter(p => p.user.name !== conversationOwnerName)
    .reduce((prev, curr) => {
      return prev + ', ' + curr.user.name
    }, '')
  return conversationOwnerName + participantString
}

const getParticipantsString = (
  participants,
  isSubmissionComments,
  conversationOwnerName = null
) => {
  return isSubmissionComments
    ? getSubmissionCommentsParticipantString(participants)
    : getConversationParticipantString(participants, conversationOwnerName)
}
