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

import {
  ADD_CONVERSATION_MESSAGE,
  CREATE_CONVERSATION,
  CREATE_SUBMISSION_COMMENT,
} from '../../../graphql/Mutations'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import ComposeModalContainer from './ComposeModalContainer'
import {Conversation} from '../../../graphql/Conversation'
import {ConversationMessage} from '../../../graphql/ConversationMessage'
import {
  CONVERSATION_MESSAGES_QUERY,
  COURSES_QUERY,
  REPLY_CONVERSATION_QUERY,
  SUBMISSION_COMMENTS_QUERY,
  VIEWABLE_SUBMISSIONS_QUERY,
} from '../../../graphql/Queries'
import {useScope as useI18nScope} from '@canvas/i18n'
import ModalSpinner from './ModalSpinner'
import PropTypes from 'prop-types'
import React, {useContext, useState, useEffect} from 'react'
import {useMutation, useQuery} from 'react-apollo'
import {ConversationContext} from '../../../util/constants'

const I18n = useI18nScope('conversations_2')

const ComposeModalManager = props => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const [sendingMessage, setSendingMessage] = useState(false)
  const {isSubmissionCommentsType} = useContext(ConversationContext)
  const [modalError, setModalError] = useState(null)

  // no-cache policy is required here to decouple the composeModalManager course query from the
  // MessageListActionContainer course query. Otherwise the filtered courses get cached to both
  const coursesQuery = useQuery(COURSES_QUERY, {
    variables: {
      userID: ENV.current_user_id?.toString(),
    },
    fetchPolicy: 'no-cache',
    skip: props.isReply || props.isReplyAll || props.isForward,
  })

  const getReplyRecipients = () => {
    if (isSubmissionCommentsType) return

    const lastAuthor = props.conversationMessage
      ? props.conversationMessage?.author
      : props.conversation?.messages[0]?.author

    if (
      lastAuthor &&
      lastAuthor?._id &&
      props.isReply &&
      lastAuthor?._id.toString() !== ENV.current_user_id.toString()
    ) {
      return [lastAuthor]
    } else {
      const recipients = props.conversationMessage
        ? props.conversationMessage?.recipients
        : props.conversation?.messages[0]?.recipients
      return recipients || []
    }
  }

  const getReplyRecipientIDs = () => {
    return getReplyRecipients()?.map(r => r._id.toString())
  }

  const replyConversationQuery = useQuery(REPLY_CONVERSATION_QUERY, {
    variables: {
      conversationID: props.conversation?._id,
      participants: getReplyRecipientIDs(),
      ...(props.conversationMessage && {createdBefore: props.conversationMessage?.createdAt}),
      first: props.isForward && props.conversationMessage ? 1 : null,
    },
    notifyOnNetworkStatusChange: true,
    skip: !(props.isReply || props.isReplyAll || props.isForward) || isSubmissionCommentsType,
  })

  const updateConversationsCache = (cache, result) => {
    let legacyNode
    try {
      const queryResult = JSON.parse(
        JSON.stringify(cache.readQuery(props.conversationsQueryOption))
      )
      legacyNode = queryResult.legacyNode
    } catch (e) {
      // readQuery throws an exception if the query isn't already in the cache
      // If its not in the cache we don't want to do anything
      return
    }

    if (props.isReply || props.isReplyAll || props.isForward) {
      const conversation = legacyNode.conversationsConnection.nodes.find(
        c => c.conversation._id === props.conversation._id
      ).conversation

      conversation.conversationMessagesConnection.nodes.unshift(
        result.data.addConversationMessage.conversationMessage
      )
      conversation.conversationMessagesCount++
    } else {
      legacyNode.conversationsConnection.nodes.unshift(
        ...result.data.createConversation.conversations
      )
    }

    cache.writeQuery({
      ...props.conversationsQueryOption,
      data: {legacyNode},
    })
  }

  const updateReplyConversationsCache = (cache, result) => {
    if (props.isReply || props.isReplyAll || props.isForward) {
      const replyQueryResult = JSON.parse(
        JSON.stringify(
          cache.readQuery({
            query: REPLY_CONVERSATION_QUERY,
            variables: {
              conversationID: props.conversation?._id,
              participants: getReplyRecipientIDs(),
              ...(props.conversationMessage && {
                createdBefore: props.conversationMessage?.createdAt,
              }),
            },
          })
        )
      )

      replyQueryResult.legacyNode.conversationMessagesConnection.nodes.unshift(
        result.data.addConversationMessage.conversationMessage
      )

      cache.writeQuery({
        query: REPLY_CONVERSATION_QUERY,
        variables: {
          conversationID: props.conversation?._id,
          participants: getReplyRecipientIDs(),
          ...(props.conversationMessage && {createdBefore: props.conversationMessage?.createdAt}),
        },
        data: {legacyNode: replyQueryResult.legacyNode},
      })
    }
  }

  const updateConversationMessagesCache = (cache, result) => {
    if (props?.conversation) {
      const querytoUpdate = {
        query: CONVERSATION_MESSAGES_QUERY,
        variables: {
          conversationID: props.conversation._id,
        },
      }
      const data = JSON.parse(JSON.stringify(cache.readQuery(querytoUpdate)))

      data.legacyNode.conversationMessagesConnection.nodes = [
        result.data.addConversationMessage.conversationMessage,
        ...data.legacyNode.conversationMessagesConnection.nodes,
      ]

      cache.writeQuery({...querytoUpdate, data})
    }
  }

  const updateSubmissionCommentsCache = (cache, result) => {
    if (props?.conversation) {
      const queryToUpdate = {
        query: SUBMISSION_COMMENTS_QUERY,
        variables: {
          submissionID: props.conversation._id,
          sort: 'desc',
        },
      }
      const data = JSON.parse(JSON.stringify(cache.readQuery(queryToUpdate)))

      data.legacyNode.commentsConnection.nodes.unshift(
        result.data.createSubmissionComment.submissionComment
      )
      cache.writeQuery({...queryToUpdate, data})
    }

    const queryToUpdate = {
      query: VIEWABLE_SUBMISSIONS_QUERY,
      variables: {
        userID: ENV.current_user_id?.toString(),
        sort: 'desc',
      },
    }
    const data = JSON.parse(JSON.stringify(cache.readQuery(queryToUpdate)))
    const submissionToUpdate = data.legacyNode.viewableSubmissionsConnection.nodes.find(
      c => c._id === props.conversation._id
    )
    submissionToUpdate.commentsConnection.nodes.unshift(
      result.data.createSubmissionComment.submissionComment
    )

    cache.writeQuery({...queryToUpdate, data})
  }

  const updateCache = (cache, result) => {
    const submissionFail = result?.data?.createSubmissionComment?.errors
    const addConversationFail = result?.data?.addConversationMessage?.errors
    const createConversationFail = result?.data?.createConversation?.errors
    if (submissionFail || addConversationFail || createConversationFail) {
      // Error messages get set in the onConversationCreateComplete function
      // This just prevents a cacheUpdate when there is an error
      return
    }
    if (isSubmissionCommentsType) {
      updateSubmissionCommentsCache(cache, result)
    } else {
      updateConversationMessagesCache(cache, result)
      updateConversationsCache(cache, result)
      updateReplyConversationsCache(cache, result)
    }
  }

  const onConversationCreateComplete = data => {
    setSendingMessage(false)
    // success is true if there is no error message or if data === true
    const errorMessage = data?.errors
    const success = errorMessage ? false : !!data

    if (success) {
      // before we do anything, let's allow some time for any ModalSpinner to truly go away
      setTimeout(() => {
        props.onDismiss()
        setOnSuccess(I18n.t('Message sent!'), false)
      }, 500)
    } else {
      if (errorMessage && errorMessage[0]?.message) {
        setModalError(errorMessage[0].message)
      } else if (isSubmissionCommentsType) {
        setModalError(I18n.t('Error creating Submission Comment'))
      } else if (props.isReply || props.isReplyAll || props.isForward) {
        setModalError(I18n.t('Error occurred while adding message to conversation'))
      } else {
        setModalError(I18n.t('Error occurred while creating conversation message'))
      }

      setTimeout(() => {
        setModalError(null)
      }, 2500)
    }
  }

  const [createConversation] = useMutation(CREATE_CONVERSATION, {
    update: updateCache,
    onCompleted: data => onConversationCreateComplete(data?.createConversation),
    onError: () => onConversationCreateComplete(false),
  })

  const [addConversationMessage] = useMutation(ADD_CONVERSATION_MESSAGE, {
    update: updateCache,
    onCompleted: data => onConversationCreateComplete(data?.addConversationMessage),
    onError: () => onConversationCreateComplete(false),
  })

  const [createSubmissionComment] = useMutation(CREATE_SUBMISSION_COMMENT, {
    update: updateCache,
    onCompleted: data => onConversationCreateComplete(data?.createSubmissionComment),
    onError: () => onConversationCreateComplete(false),
  })

  // Keep selectedIDs updated with the correct recipients when replying
  useEffect(() => {
    if ((props.isReply || props.isReplyAll) && !isSubmissionCommentsType) {
      const recipients = getReplyRecipients()
      const selectedUsers = recipients.map(u => {
        return {
          _id: u._id,
          id: u.id,
          name: u.name,
          itemType: 'user',
        }
      })
      props.onSelectedIdsChange(selectedUsers)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isSubmissionCommentsType, props.isReply, props.isReplyAll])

  if (!props.open) {
    return null
  }

  // Handle query errors
  if (coursesQuery?.error) {
    setOnFailure(I18n.t('Error loading course data'))
    return null
  }
  if (replyConversationQuery?.error) {
    setOnFailure(I18n.t('Error loading past messages'))
    return null
  }

  // Handle loading
  if (coursesQuery?.loading || replyConversationQuery?.loading) {
    return <ModalSpinner label={I18n.t('Loading')} message={I18n.t('Loading Compose Modal')} />
  }

  const filteredCourses = () => {
    const courses = coursesQuery?.data?.legacyNode
    if (courses) {
      courses.enrollments = courses?.enrollments.filter(enrollment => !enrollment?.concluded)
      courses.favoriteGroupsConnection.nodes = courses?.favoriteGroupsConnection?.nodes.filter(
        group => group?.canMessage
      )
    }

    return courses
  }

  return (
    <ComposeModalContainer
      addConversationMessage={data => {
        addConversationMessage({
          variables: {
            ...data.variables,
            conversationId: props.conversation?._id,
            recipients: data.variables.recipients
              ? data.variables.recipients
              : props.selectedIds.map(rec => rec?._id || rec.id),
          },
        })
      }}
      createSubmissionComment={data => {
        createSubmissionComment({
          variables: {
            ...data.variables,
            submissionId: props?.conversation?._id,
          },
        })
      }}
      courses={filteredCourses()}
      createConversation={createConversation}
      isReply={props.isReply || props.isReplyAll}
      isForward={props.isForward}
      onDismiss={props.onDismiss}
      open={props.open}
      pastConversation={replyConversationQuery?.data?.legacyNode}
      sendingMessage={sendingMessage}
      setSendingMessage={setSendingMessage}
      onSelectedIdsChange={props.onSelectedIdsChange}
      selectedIds={props.selectedIds}
      contextIdFromUrl={props.contextIdFromUrl}
      maxGroupRecipientsMet={props.maxGroupRecipientsMet}
      submissionCommentsHeader={isSubmissionCommentsType ? props?.conversation?.subject : null}
      modalError={modalError}
      isPrivateConversation={!!props?.conversation?.isPrivate}
      currentCourseFilter={props.currentCourseFilter}
    />
  )
}

ComposeModalManager.propTypes = {
  conversation: Conversation.shape,
  conversationMessage: ConversationMessage.shape,
  isReply: PropTypes.bool,
  isReplyAll: PropTypes.bool,
  isForward: PropTypes.bool,
  onDismiss: PropTypes.func,
  open: PropTypes.bool,
  conversationsQueryOption: PropTypes.object,
  onSelectedIdsChange: PropTypes.func,
  selectedIds: PropTypes.array,
  contextIdFromUrl: PropTypes.string,
  maxGroupRecipientsMet: PropTypes.bool,
  currentCourseFilter: PropTypes.string,
}

export default ComposeModalManager
