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

import React, {useState, useEffect, useContext} from 'react'
import {ConversationContext} from '../../util/constants'
import ComposeModalManager from './ComposeModalContainer/ComposeModalManager'
import {MessageDetailContainer} from './MessageDetailContainer/MessageDetailContainer'
import MessageListActionContainer from './MessageListActionContainer'
import ConversationListContainer from './ConversationListContainer'
import {NoSelectedConversation} from '../components/NoSelectedConversation/NoSelectedConversation'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {useScope as useI18nScope} from '@canvas/i18n'
import {useMutation, useQuery} from 'react-apollo'
import {
  DELETE_CONVERSATIONS,
  UPDATE_CONVERSATION_PARTICIPANTS,
  UPDATE_SUBMISSIONS_READ_STATE,
} from '../../graphql/Mutations'
import {CONVERSATIONS_QUERY, VIEWABLE_SUBMISSIONS_QUERY} from '../../graphql/Queries'
import {decodeQueryString} from 'query-string-encoding'
import {responsiveQuerySizes} from '../../util/utils'

import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'
import {IconArrowOpenStartLine} from '@instructure/ui-icons'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('conversations_2')

const CanvasInbox = () => {
  const [scope, setScope] = useState('inbox')
  const [courseFilter, setCourseFilter] = useState()
  const [userFilter, setUserFilter] = useState()
  const [selectedConversations, setSelectedConversations] = useState([])
  const [selectedConversationMessage, setSelectedConversationMessage] = useState()
  const [composeModal, setComposeModal] = useState(false)
  const [deleteDisabled, setDeleteDisabled] = useState(true)
  const [archiveDisabled, setArchiveDisabled] = useState(true)
  const [canReply, setCanReply] = useState(true)
  const [isReply, setIsReply] = useState(false)
  const [isReplyAll, setIsReplyAll] = useState(false)
  const [isForward, setIsForward] = useState(false)
  const [displayUnarchiveButton, setDisplayUnarchiveButton] = useState(false)
  const [multiselect, setMultiselect] = useState(false)
  const [isSubmissionCommentsType, setIsSubmissionCommentsType] = useState(false)
  const [messageOpenEvent, setMessageOpenEvent] = useState(false)
  const userID = ENV.current_user_id?.toString()
  const [urlUserRecipient, setUrlUserRecepient] = useState()
  const [selectedIds, setSelectedIds] = useState([])

  const setFilterStateToCurrentWindowHash = () => {
    const validFilters = ['inbox', 'unread', 'starred', 'sent', 'archived', 'submission_comments']

    const urlHash = window.location.hash
    const hashParams = urlHash.substring('#filter='.length)
    const hashData = decodeQueryString(hashParams)
    const filterType = hashData.filter(i => i.type !== undefined)[0]?.type
    const courseSelection = hashData.filter(i => i.course !== undefined)[0]?.course

    const newCourseFilter = courseSelection || null
    setCourseFilter(newCourseFilter)

    const isValidFilter = filterType && validFilters.includes(filterType)
    if (isValidFilter) setScope(filterType)
  }

  const setUrlUserRecepientFromUrlParam = () => {
    const urlData = new URLSearchParams(window.location.search)
    const userIdFromUrlData = urlData.get('user_id')
    const userNameFromUrlData = urlData.get('user_name')
    if (userIdFromUrlData && userNameFromUrlData) {
      setUrlUserRecepient({
        _id: userIdFromUrlData,
        name: userNameFromUrlData,
        commonCoursesInfo: [],
        itemType: 'user',
      })
      setComposeModal(true)
    }
  }

  // Get initial filter settings and set listener
  // also get initial recepient settings if it exists in the url
  useEffect(() => {
    setFilterStateToCurrentWindowHash()
    setUrlUserRecepientFromUrlParam()
    window.addEventListener('hashchange', setFilterStateToCurrentWindowHash)
  }, [])

  // pre-populate recepients if urlUserRecipientId exists
  useEffect(() => {
    if (urlUserRecipient) {
      setSelectedIds([urlUserRecipient])
    }
  }, [urlUserRecipient])

  // Keep the url updated
  useEffect(() => {
    const courseHash = courseFilter ? `&course=${courseFilter}` : ''
    window.location.hash = `#filter=type=${scope}${courseHash}`
  }, [courseFilter, scope])

  // upon compose modal close, disregard url recipient going forward
  useEffect(() => {
    if (urlUserRecipient && !composeModal) {
      setUrlUserRecepient(null)
      setSelectedIds([])
    }
  }, [composeModal, urlUserRecipient])

  // Keep the contextUpdated
  useEffect(() => {
    setIsSubmissionCommentsType(scope === 'submission_comments')
  }, [scope])

  // clear conversationsManuallyMarkedUnread when
  // selectedConversations is not the same
  useEffect(() => {
    if (
      selectedConversations.length > 0 &&
      !JSON.parse(sessionStorage.getItem('conversationsManuallyMarkedUnread'))?.includes(
        selectedConversations[0]._id
      )
    ) {
      sessionStorage.removeItem('conversationsManuallyMarkedUnread')
    }
  }, [selectedConversations])

  const conversationContext = {
    multiselect,
    setMultiselect,
    messageOpenEvent,
    setMessageOpenEvent,
    isSubmissionCommentsType,
    setIsSubmissionCommentsType,
  }

  const updateSelectedConversations = conversations => {
    setSelectedConversations(conversations)
    setDeleteDisabled(conversations.length === 0)
    setArchiveDisabled(conversations.length === 0)
    setSelectedConversationMessage(null)
  }

  const onSelectedIdsChange = ids => {
    setSelectedIds(ids)
  }

  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const commonQueryVariables = {
    userID: ENV.current_user_id?.toString(),
    filter: [userFilter, courseFilter],
  }

  const conversationsQueryOption = {
    query: CONVERSATIONS_QUERY,
    variables: {
      ...commonQueryVariables,
      scope,
    },
  }

  const conversationsQuery = useQuery(CONVERSATIONS_QUERY, {
    variables: {...commonQueryVariables, scope},
    fetchPolicy: 'cache-and-network',
    skip: isSubmissionCommentsType || scope === 'submission_comments',
  })

  const submissionCommentsQuery = useQuery(VIEWABLE_SUBMISSIONS_QUERY, {
    variables: {...commonQueryVariables, sort: 'desc'},
    fetchPolicy: 'cache-and-network',
    skip: !isSubmissionCommentsType || !(scope === 'submission_comments'),
  })
  const submissionCommentLength =
    submissionCommentsQuery.data?.legacyNode?.viewableSubmissionsConnection?.nodes?.length || 0
  const conversationLength =
    conversationsQuery.data?.legacyNode?.conversationsConnection?.nodes?.length || 0

  const removeOutOfScopeConversationsFromCache = (cache, result) => {
    if (scope === 'starred') {
      return
    }

    if (result.data.updateConversationParticipants.errors) {
      return
    }

    const conversationsFromCache = JSON.parse(
      JSON.stringify(cache.readQuery(conversationsQueryOption))
    )
    const conversationParticipantIDsFromResult =
      result.data.updateConversationParticipants.conversationParticipants.map(cp => cp._id)

    const updatedCPs = conversationsFromCache.legacyNode.conversationsConnection.nodes.filter(
      conversationParticipant =>
        !conversationParticipantIDsFromResult.includes(conversationParticipant._id)
    )
    conversationsFromCache.legacyNode.conversationsConnection.nodes = updatedCPs
    cache.writeQuery({...conversationsQueryOption, data: conversationsFromCache})
  }

  const handleArchive = () => {
    const archiveConfirmMsg = I18n.t(
      {
        one: 'Are you sure you want to archive your copy of this conversation?',
        other: 'Are you sure you want to archive your copy of these conversations?',
      },
      {count: selectedConversations.length}
    )

    const confirmResult = window.confirm(archiveConfirmMsg) // eslint-disable-line no-alert
    if (confirmResult) {
      archiveConversationParticipants({
        variables: {
          conversationIds: selectedConversations.map(convo => convo._id),
          workflowState: 'archived',
        },
      })
    } else {
      // confirm message was cancelled by user
      setArchiveDisabled(false)
    }
  }

  const handleUnarchive = () => {
    const unarchiveConfirmMsg = I18n.t(
      {
        one: 'Are you sure you want to unarchive your copy of this conversation?',
        other: 'Are you sure you want to unarchive your copy of these conversations?',
      },
      {count: selectedConversations.length}
    )

    const confirmResult = window.confirm(unarchiveConfirmMsg) // eslint-disable-line no-alert
    if (confirmResult) {
      unarchiveConversationParticipants({
        variables: {
          conversationIds: selectedConversations.map(convo => convo._id),
          workflowState: 'read',
        },
      })
    } else {
      // confirm message was cancelled by user
      setArchiveDisabled(false)
    }
  }

  const handleArchiveComplete = data => {
    const archiveSuccessMsg = I18n.t(
      {
        one: 'Message archived!',
        other: 'Messages archived!',
      },
      {count: selectedConversations.length}
    )
    if (data.updateConversationParticipants.errors) {
      setArchiveDisabled(false)
      setOnFailure(I18n.t('Archive operation failed'))
    } else {
      setArchiveDisabled(true)
      if (scope !== 'Starred') {
        removeFromSelectedConversations(selectedConversations)
      }
      setOnSuccess(archiveSuccessMsg, false)
    }
  }

  const handleUnarchiveComplete = data => {
    const unarchiveSuccessMsg = I18n.t(
      {
        one: 'Message unarchived!',
        other: 'Messages unarchived!',
      },
      {count: selectedConversations.length}
    )
    if (data.updateConversationParticipants.errors) {
      setArchiveDisabled(true)
      setOnFailure(I18n.t('Unarchive operation failed'))
    } else {
      setArchiveDisabled(false)
      if (scope !== 'Starred') {
        removeFromSelectedConversations(selectedConversations)
      }
      setOnSuccess(unarchiveSuccessMsg, false)
    }
  }

  const [archiveConversationParticipants] = useMutation(UPDATE_CONVERSATION_PARTICIPANTS, {
    update: removeOutOfScopeConversationsFromCache,
    onCompleted(data) {
      handleArchiveComplete(data)
    },
    onError() {
      setOnFailure(I18n.t('Archive operation failed'))
    },
  })

  const [unarchiveConversationParticipants] = useMutation(UPDATE_CONVERSATION_PARTICIPANTS, {
    update: removeOutOfScopeConversationsFromCache,
    onCompleted(data) {
      handleUnarchiveComplete(data)
    },
    onError() {
      setOnFailure(I18n.t('Unarchive operation failed'))
    },
  })

  const handleDelete = individualConversation => {
    const conversationsToDeleteByID =
      individualConversation || selectedConversations.map(convo => convo._id)

    const delMsg = I18n.t(
      {
        one: 'Are you sure you want to delete your copy of this conversation? This action cannot be undone.',
        other:
          'Are you sure you want to delete your copy of these conversations? This action cannot be undone.',
      },
      {count: conversationsToDeleteByID.length}
    )
    const confirmResult = window.confirm(delMsg) // eslint-disable-line no-alert
    if (confirmResult) {
      deleteConversations({variables: {ids: conversationsToDeleteByID}})
    } else {
      // confirm message was cancelled by user
      setDeleteDisabled(false)
    }
  }

  const handleDeleteComplete = data => {
    const deletedConversationIDs = data.deleteConversations.conversationIds
    const deletedSuccessMsg = I18n.t(
      {
        one: 'Message Deleted!',
        other: 'Messages Deleted!',
      },
      {count: deletedConversationIDs.length}
    )

    if (data.deleteConversations.errors) {
      // keep delete button enabled since deletion returned errors
      setDeleteDisabled(false)
      setOnFailure(I18n.t('Delete operation failed'))
    } else {
      setDeleteDisabled(true)
      removeFromSelectedConversations(deletedConversationIDs)
      setOnSuccess(deletedSuccessMsg, false)
    }
  }

  const removeFromSelectedConversations = conversationIds => {
    setSelectedConversations(prev => {
      const updated = prev.filter(selectedConvo => !conversationIds.includes(selectedConvo._id))
      setDeleteDisabled(updated.length === 0)
      setArchiveDisabled(updated.length === 0)
      return updated
    })
  }

  const removeDeletedConversationsFromCache = (cache, result) => {
    const conversationsFromCache = JSON.parse(
      JSON.stringify(cache.readQuery(conversationsQueryOption))
    )

    const conversationIDsFromResult = result.data.deleteConversations.conversationIds

    const updatedCPs = conversationsFromCache.legacyNode.conversationsConnection.nodes.filter(
      conversationParticipant => {
        return !conversationIDsFromResult.includes(conversationParticipant.conversation._id)
      }
    )

    conversationsFromCache.legacyNode.conversationsConnection.nodes = updatedCPs
    cache.writeQuery({...conversationsQueryOption, data: conversationsFromCache})
  }

  const [deleteConversations] = useMutation(DELETE_CONVERSATIONS, {
    update: removeDeletedConversationsFromCache,
    onCompleted(data) {
      handleDeleteComplete(data)
    },
    onError() {
      setOnFailure(I18n.t('Delete operation failed'))
    },
  })

  const firstConversation = selectedConversations.length > 0 ? selectedConversations[0] : {}

  const myConversationParticipant = firstConversation?.participants?.find(
    node => node?.user?._id === ENV.current_user_id
  )
  const firstConversationIsStarred = myConversationParticipant?.label === 'starred'

  const [starConversationParticipants] = useMutation(UPDATE_CONVERSATION_PARTICIPANTS, {
    onCompleted: () => {
      if (firstConversationIsStarred) {
        setOnSuccess(
          I18n.t(
            {
              one: 'The conversation has been successfully unstarred.',
              other: 'The conversations has been successfully unstarred.',
            },
            {count: selectedConversations.length}
          )
        )
      } else {
        setOnSuccess(
          I18n.t(
            {
              one: 'The conversation has been successfully starred.',
              other: 'The conversations has been successfully starred.',
            },
            {count: selectedConversations.length}
          )
        )
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the conversation participants.'))
    },
  })

  const handleStar = starred => {
    starConversationParticipants({
      variables: {
        conversationIds: selectedConversations.map(convo => convo._id),
        starred,
      },
    })
  }

  const [readStateChangeSubmission] = useMutation(UPDATE_SUBMISSIONS_READ_STATE, {
    onCompleted(data) {
      if (data.updateSubmissionsReadState.errors) {
        setOnFailure(I18n.t('Read state change operation failed'))
      } else {
        setOnSuccess(
          I18n.t(
            {
              one: 'Read state Changed!',
              other: 'Read states Changed!',
            },
            {count: '1000'}
          )
        )
      }
    },
    onError() {
      setOnFailure(I18n.t('Read state change failed'))
    },
  })

  const [readStateChangeConversationParticipants] = useMutation(UPDATE_CONVERSATION_PARTICIPANTS, {
    onCompleted(data) {
      if (data.updateConversationParticipants.errors) {
        setOnFailure(I18n.t('Read state change operation failed'))
      } else {
        setOnSuccess(
          I18n.t(
            {
              one: 'Read state Changed!',
              other: 'Read states Changed!',
            },
            {count: '1000'}
          )
        )
      }
    },
    onError() {
      setOnFailure(I18n.t('Read state change failed'))
    },
  })

  const handleReadState = (markAsRead, conversationIds = null) => {
    const conversationIdsToChange = conversationIds || selectedConversations.map(convo => convo._id)
    if (scope === 'submission_comments') {
      readStateChangeSubmission({
        variables: {
          submissionIds: conversationIds,
          read: markAsRead === 'read',
        },
      })
    } else {
      readStateChangeConversationParticipants({
        variables: {
          conversationIds: conversationIdsToChange,
          workflowState: markAsRead,
        },
      })
    }

    // always change this to whatever was just changed
    if (markAsRead === 'unread') {
      sessionStorage.setItem(
        'conversationsManuallyMarkedUnread',
        JSON.stringify(conversationIdsToChange)
      )
    }
  }

  const onReply = ({conversationMessage = null, replyAll = false} = {}) => {
    conversationMessage = isSubmissionCommentsType ? {} : conversationMessage
    setSelectedConversationMessage(conversationMessage)
    setIsReplyAll(replyAll)
    setIsReply(!replyAll)
    setComposeModal(true)
  }

  const onForward = ({conversationMessage = null} = {}) => {
    setSelectedConversationMessage(conversationMessage)
    setIsForward(true)
    setComposeModal(true)
  }

  useEffect(() => {
    setDeleteDisabled(selectedConversations.length === 0)
    setArchiveDisabled(selectedConversations.length === 0)
    if (selectedConversations.length === 0) {
      setDisplayUnarchiveButton(false)
    } else {
      setDisplayUnarchiveButton(
        selectedConversations[0].participants?.some(cp => {
          return cp?.user?._id === userID && cp.workflowState === 'archived'
        })
      )
    }
  }, [selectedConversations, userID])

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          conversationListWidth: '100%',
          messageDetailMargin: '0 0 0 small',
        },
        desktop: {
          conversationListWidth: '400px',
          messageDetailMargin: undefined,
        },
      }}
      render={(responsiveProps, matches) => (
        <ConversationContext.Provider value={conversationContext}>
          <Flex height="100vh" as="div" direction="column">
            {(matches.includes('desktop') ||
              (matches.includes('mobile') && !selectedConversations.length) ||
              multiselect) && (
              <Flex.Item
                data-testid={
                  matches.includes('desktop')
                    ? 'desktop-message-action-header'
                    : 'mobile-message-action-header'
                }
              >
                <MessageListActionContainer
                  activeMailbox={scope}
                  activeCourseFilter={courseFilter}
                  onSelectMailbox={newScope => {
                    setSelectedConversations([])
                    setScope(newScope)
                  }}
                  onCourseFilterSelect={course => {
                    setSelectedConversations([])
                    setCourseFilter(course)
                  }}
                  onUserFilterSelect={userIDFilter => {
                    setUserFilter(userIDFilter)
                  }}
                  selectedConversations={selectedConversations}
                  onCompose={() => setComposeModal(true)}
                  onReply={() => onReply()}
                  onReplyAll={() => onReply({replyAll: true})}
                  onForward={() => onForward()}
                  onArchive={displayUnarchiveButton ? undefined : handleArchive}
                  onUnarchive={displayUnarchiveButton ? handleUnarchive : undefined}
                  deleteDisabled={deleteDisabled}
                  deleteToggler={setDeleteDisabled}
                  archiveDisabled={archiveDisabled}
                  archiveToggler={setArchiveDisabled}
                  onConversationRemove={removeFromSelectedConversations}
                  displayUnarchiveButton={displayUnarchiveButton}
                  conversationsQueryOptions={conversationsQueryOption}
                  onStar={handleStar}
                  firstConversationIsStarred={firstConversationIsStarred}
                  onDelete={handleDelete}
                  onReadStateChange={handleReadState}
                  canReply={canReply}
                />
              </Flex.Item>
            )}
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <Flex height="100%" as="div" align="center" justifyItems="center">
                {(matches.includes('desktop') ||
                  (matches.includes('mobile') && !selectedConversations.length) ||
                  multiselect) && (
                  <Flex.Item
                    width={
                      conversationLength || submissionCommentLength
                        ? responsiveProps.conversationListWidth
                        : '100%'
                    }
                    height="100%"
                  >
                    <ConversationListContainer
                      course={courseFilter}
                      userFilter={userFilter}
                      scope={scope}
                      onSelectConversation={updateSelectedConversations}
                      onReadStateChange={handleReadState}
                      commonQueryVariables={commonQueryVariables}
                      conversationsQuery={conversationsQuery}
                      submissionCommentsQuery={submissionCommentsQuery}
                    />
                  </Flex.Item>
                )}
                {(matches.includes('desktop') ||
                  (matches.includes('mobile') &&
                    selectedConversations.length > 0 &&
                    !multiselect)) && (
                  <Flex.Item
                    shouldGrow={true}
                    shouldShrink={true}
                    height="100%"
                    overflowY="auto"
                    margin={responsiveProps.messageDetailMargin}
                  >
                    {selectedConversations.length > 0 ? (
                      <>
                        {matches.includes('mobile') && (
                          <View
                            as="div"
                            borderWidth="none none small none"
                            padding="none none none xx-small"
                          >
                            <Flex>
                              <Flex.Item
                                shouldGrow={true}
                                border={true}
                                padding="medium none medium none"
                              >
                                <Link
                                  data-testid="message-detail-back-button"
                                  isWithinText={false}
                                  as="button"
                                  renderIcon={<IconArrowOpenStartLine size="x-small" />}
                                  onClick={() => {
                                    setSelectedConversations([])
                                  }}
                                >
                                  <Text>{I18n.t('Back')}</Text>
                                </Link>
                              </Flex.Item>
                            </Flex>
                          </View>
                        )}
                        <MessageDetailContainer
                          setCanReply={setCanReply}
                          conversation={selectedConversations[0]}
                          onReply={conversationMessage => onReply({conversationMessage})}
                          onReplyAll={conversationMessage =>
                            onReply({conversationMessage, replyAll: true})
                          }
                          onArchive={displayUnarchiveButton ? undefined : handleArchive}
                          onUnarchive={displayUnarchiveButton ? handleUnarchive : undefined}
                          onDelete={handleDelete}
                          onForward={conversationMessage => onForward({conversationMessage})}
                          onStar={
                            !firstConversationIsStarred
                              ? () => {
                                  handleStar(true)
                                }
                              : null
                          }
                          onUnstar={
                            firstConversationIsStarred
                              ? () => {
                                  handleStar(false)
                                }
                              : null
                          }
                          onReadStateChange={handleReadState}
                          scope={scope}
                        />
                      </>
                    ) : (
                      <View padding="small">
                        <NoSelectedConversation />
                      </View>
                    )}
                  </Flex.Item>
                )}
              </Flex>
            </Flex.Item>
          </Flex>
          <ComposeModalManager
            conversation={selectedConversations[0]}
            conversationMessage={selectedConversationMessage}
            isReply={isReply}
            isReplyAll={isReplyAll}
            isForward={isForward}
            onDismiss={() => {
              setComposeModal(false)
              setIsReply(false)
              setIsReplyAll(false)
              setIsForward(false)
              setSelectedConversationMessage(null)
              setSelectedIds([])
            }}
            open={composeModal}
            conversationsQueryOption={conversationsQueryOption}
            onSelectedIdsChange={onSelectedIdsChange}
            selectedIds={selectedIds}
          />
        </ConversationContext.Provider>
      )}
    />
  )
}

export default CanvasInbox
