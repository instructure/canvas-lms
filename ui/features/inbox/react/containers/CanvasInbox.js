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
import {useMutation} from 'react-apollo'
import {DELETE_CONVERSATIONS} from '../../graphql/Mutations'
import {CONVERSATIONS_QUERY} from '../../graphql/Queries'
import {decodeQueryString} from 'query-string-encoding'
import {responsiveQuerySizes} from '../../util/utils'
import {CondensedButton, IconButton} from '@instructure/ui-buttons'

import {Flex} from '@instructure/ui-flex'
import {IconArrowOpenStartLine, IconXSolid} from '@instructure/ui-icons'
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
        itemType: 'user'
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

  const conversationContext = {
    multiselect,
    setMultiselect,
    messageOpenEvent,
    setMessageOpenEvent,
    isSubmissionCommentsType,
    setIsSubmissionCommentsType
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

  const conversationsQueryOption = {
    query: CONVERSATIONS_QUERY,
    variables: {
      userID: ENV.current_user_id?.toString(),
      scope,
      filter: [userFilter, courseFilter]
    }
  }

  const handleDelete = individualConversation => {
    const conversationsToDeleteByID =
      individualConversation || selectedConversations.map(convo => convo._id)

    const delMsg = I18n.t(
      {
        one: 'Are you sure you want to delete your copy of this conversation? This action cannot be undone.',
        other:
          'Are you sure you want to delete your copy of these conversations? This action cannot be undone.'
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
        other: 'Messages Deleted!'
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
    }
  })

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
          return cp.user._id === userID && cp.workflowState === 'archived'
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
          messageDetailMargin: '0 0 0 small'
        },
        desktop: {
          conversationListWidth: '400px',
          messageDetailMargin: undefined
        }
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
                  deleteDisabled={deleteDisabled}
                  deleteToggler={setDeleteDisabled}
                  archiveDisabled={archiveDisabled}
                  archiveToggler={setArchiveDisabled}
                  onConversationRemove={removeFromSelectedConversations}
                  displayUnarchiveButton={displayUnarchiveButton}
                  conversationsQueryOptions={conversationsQueryOption}
                  onDelete={handleDelete}
                />
              </Flex.Item>
            )}
            <Flex.Item shouldGrow shouldShrink>
              <Flex height="100%" as="div" align="center" justifyItems="center">
                {(matches.includes('desktop') ||
                  (matches.includes('mobile') && !selectedConversations.length) ||
                  multiselect) && (
                  <Flex.Item width={responsiveProps.conversationListWidth} height="100%">
                    <ConversationListContainer
                      course={courseFilter}
                      userFilter={userFilter}
                      scope={scope}
                      onSelectConversation={updateSelectedConversations}
                    />
                  </Flex.Item>
                )}
                {(matches.includes('desktop') ||
                  (matches.includes('mobile') &&
                    selectedConversations.length > 0 &&
                    !multiselect)) && (
                  <Flex.Item
                    shouldGrow
                    shouldShrink
                    height="100%"
                    overflowY="auto"
                    margin={responsiveProps.messageDetailMargin}
                  >
                    {selectedConversations.length > 0 ? (
                      <>
                        {matches.includes('mobile') && (
                          <View as="div" borderWidth="none none small none">
                            <Flex>
                              <Flex.Item shouldGrow border>
                                <CondensedButton
                                  data-testid="message-detail-back-button"
                                  renderIcon={<IconArrowOpenStartLine size="x-small" />}
                                  onClick={() => {
                                    setSelectedConversations([])
                                  }}
                                >
                                  <Text>{I18n.t('Back')}</Text>
                                </CondensedButton>
                              </Flex.Item>
                              <Flex.Item>
                                <IconButton
                                  shape="rectangle"
                                  screenReaderLabel="Delete tag"
                                  margin="small"
                                  withBorder={false}
                                  withBackground={false}
                                  onClick={() => {
                                    setSelectedConversations([])
                                  }}
                                >
                                  <IconXSolid />
                                </IconButton>
                              </Flex.Item>
                            </Flex>
                          </View>
                        )}
                        <MessageDetailContainer
                          conversation={selectedConversations[0]}
                          onReply={conversationMessage => onReply({conversationMessage})}
                          onReplyAll={conversationMessage =>
                            onReply({conversationMessage, replyAll: true})
                          }
                          onDelete={handleDelete}
                          onForward={conversationMessage => onForward({conversationMessage})}
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
