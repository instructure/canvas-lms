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
import {useScope as createI18nScope} from '@canvas/i18n'
import ModalSpinner from './ModalSpinner'
import PropTypes from 'prop-types'
import React, {useContext, useState, useEffect} from 'react'
import {useMutation, useQuery} from '@apollo/client'
import {ConversationContext} from '../../../util/constants'

const I18n = createI18nScope('conversations_2')

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
      horizonCourses: false,
    },
    fetchPolicy: 'no-cache',
    skip: props.isReply || props.isReplyAll || props.isForward,
  })

  const getReplyRecipients = () => {
    if (isSubmissionCommentsType) return []
    if (!replyConversationQuery.data?.legacyNode) return []

    const lastMessage =
      replyConversationQuery.data.legacyNode.conversationMessagesConnection.nodes[0]

    const lastAuthor = lastMessage?.author

    if (
      lastAuthor &&
      lastAuthor?._id &&
      props.isReply &&
      lastAuthor?._id.toString() !== ENV.current_user_id.toString()
    ) {
      return [lastAuthor]
    }
    return lastMessage?.recipients || []
  }

  const replyConversationQuery = useQuery(REPLY_CONVERSATION_QUERY, {
    variables: {
      conversationID: props.conversation?._id,
      participants: [ENV.current_user_id?.toString()],
      ...(props.conversationMessage && {createdBefore: props.conversationMessage?.createdAt}),
      first: props.isForward && props.conversationMessage ? 1 : null,
    },
    notifyOnNetworkStatusChange: true,
    skip: !(props.isReply || props.isReplyAll || props.isForward) || isSubmissionCommentsType,
  })

  const updateConversationsCache = (cache, result) => {
    const queryResult = JSON.parse(JSON.stringify(cache.readQuery(props.conversationsQueryOption)))

    if (!queryResult) {
      return
    }

    const legacyNode = queryResult.legacyNode

    if (props.isReply || props.isReplyAll || props.isForward) {
      const conversation = legacyNode.conversationsConnection.nodes.find(
        c => c.conversation._id === props.conversation._id,
      ).conversation

      if (result.data?.addConversationMessage?.conversationMessage) {
        conversation.conversationMessagesConnection.nodes.unshift(
          result.data.addConversationMessage.conversationMessage,
        )
      }

      conversation.conversationMessagesCount++
    } else {
      legacyNode.conversationsConnection.nodes.unshift(
        ...result.data.createConversation.conversations,
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
              participants: [ENV.current_user_id?.toString()],
              ...(props.conversationMessage && {
                createdBefore: props.conversationMessage?.createdAt,
              }),
            },
          }),
        ),
      )

      if (!replyQueryResult) {
        return
      }

      if (result.data?.addConversationMessage?.conversationMessage) {
        replyQueryResult.legacyNode.conversationMessagesConnection.nodes.unshift(
          result.data.addConversationMessage.conversationMessage,
        )
      }

      cache.writeQuery({
        query: REPLY_CONVERSATION_QUERY,
        variables: {
          conversationID: props.conversation?._id,
          participants: [ENV.current_user_id?.toString()],
          ...(props.conversationMessage && {createdBefore: props.conversationMessage?.createdAt}),
        },
        data: {legacyNode: replyQueryResult.legacyNode},
      })
    }
  }

  const updateConversationMessagesCache = (cache, result) => {
    if (props?.conversation) {
      const queryToUpdate = {
        query: CONVERSATION_MESSAGES_QUERY,
        variables: {
          conversationID: props.conversation._id,
        },
      }
      const data = JSON.parse(JSON.stringify(cache.readQuery(queryToUpdate)))

      if (result.data?.addConversationMessage?.conversationMessage) {
        data.legacyNode.conversationMessagesConnection.nodes = [
          result.data.addConversationMessage.conversationMessage,
          ...data.legacyNode.conversationMessagesConnection.nodes,
        ]
      }

      cache.writeQuery({...queryToUpdate, data})
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
        result.data.createSubmissionComment.submissionComment,
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

    if (!data) {
      return
    }

    const submissionToUpdate = data.legacyNode.viewableSubmissionsConnection.nodes.find(
      c => c._id === props.conversation._id,
    )
    submissionToUpdate.commentsConnection.nodes.unshift(
      result.data.createSubmissionComment.submissionComment,
    )

    cache.writeQuery({...queryToUpdate, data})
  }

  const updateCache = (cache, result) => {
    if (result?.data?.addConversationMessage?.conversationMessage?._id === '0') {
      // if the user sends another delayed message right now, we will have 2 0 id message in our stack, which will cause duplication
      result.data.addConversationMessage.conversationMessage.id = Date.now().toString()
    }
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
      props.onDismiss()
      setOnSuccess(I18n.t('Message sent!'), false)
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
  }, [isSubmissionCommentsType, props.isReply, props.isReplyAll, replyConversationQuery.data])

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
    const legacyNode = coursesQuery?.data?.legacyNode

    if (!legacyNode) {
      return null
    }

    const courses = JSON.parse(JSON.stringify(legacyNode))
    if (courses) {
      courses.enrollments = courses?.enrollments.filter(enrollment => !enrollment?.concluded)
      courses.favoriteGroupsConnection.nodes = courses?.favoriteGroupsConnection?.nodes.filter(
        group => group?.canMessage,
      )
    }

    return courses
  }

  return (
    <ComposeModalContainer
      inboxSignatureBlock={props.inboxSignatureBlock}
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
      activeCourseFilterID={props.activeCourseFilterID}
      setModalError={setModalError}
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
  activeCourseFilterID: PropTypes.string,
  inboxSignatureBlock: PropTypes.bool,
}

export default ComposeModalManager
