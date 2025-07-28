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
import {useScope as createI18nScope} from '@canvas/i18n'
import {useMutation, useQuery} from '@apollo/client'
import {
  CREATE_USER_INBOX_LABEL,
  DELETE_CONVERSATIONS,
  DELETE_USER_INBOX_LABEL,
  UPDATE_CONVERSATION_PARTICIPANTS,
  UPDATE_SUBMISSIONS_READ_STATE,
} from '../../graphql/Mutations'
import {
  CONVERSATIONS_QUERY,
  USER_INBOX_LABELS_QUERY,
  VIEWABLE_SUBMISSIONS_QUERY,
} from '../../graphql/Queries'
import {decodeQueryString} from '@instructure/query-string-encoding'
import WithBreakpoints from '@canvas/with-breakpoints'

import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Heading} from '@instructure/ui-heading'
import {ManageUserLabels} from '../components/ManageUserLabels/ManageUserLabels'
import {Button} from '@instructure/ui-buttons'
import {IconSettingsLine, IconComposeLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import InboxSettingsModalContainer, {
  SAVE_SETTINGS_OK,
  SAVE_SETTINGS_FAIL,
  LOAD_SETTINGS_FAIL,
} from './InboxSettingsModalContainer/InboxSettingsModalContainer'
import TopNavPortal from '@canvas/top-navigation/react/TopNavPortal'
import { InstUISettingsProvider } from '@instructure/emotion'
import canvas from '@instructure/ui-themes'

const I18n = createI18nScope('conversations_2')

const validFilters = ['inbox', 'unread', 'starred', 'sent', 'archived', 'submission_comments']

const parseFilterHash = hash => {
  const hashParams = hash.substring('#filter='.length)
  const hashData = decodeQueryString(hashParams)
  const filterType = hashData.filter(i => i.type !== undefined)[0]?.type
  const courseSelection = hashData.filter(i => i.course !== undefined)[0]?.course

  return {
    filterType: validFilters.includes(filterType) ? filterType : null,
    courseSelection: courseSelection || null,
  }
}

const CanvasInbox = ({breakpoints}) => {
  const urlFilters = parseFilterHash(window.location.hash)

  const [scope, setScope] = useState(urlFilters.filterType || 'inbox')
  const [courseFilter, setCourseFilter] = useState(urlFilters.courseSelection)
  const [userFilter, setUserFilter] = useState()
  const [selectedConversations, setSelectedConversations] = useState([])
  const [selectedConversationMessage, setSelectedConversationMessage] = useState()
  const [composeModal, setComposeModal] = useState(false)
  const [inboxSettingsModal, setInboxSettingsModal] = useState(false)
  const [manageLabels, setManageLabels] = useState(false)
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
  const [urlContextId, setUrlContextId] = useState()
  const [selectedIds, setSelectedIds] = useState([])
  const [maxGroupRecipientsMet, setMaxGroupRecipientsMet] = useState(false)
  const [conversationIdToGoBackTo, setConversationIdToGoBackTo] = useState(null)

  const inboxSignatureBlock = !!ENV.CONVERSATIONS.INBOX_SIGNATURE_BLOCK_ENABLED
  const inboxAutoResponse = !!ENV.CONVERSATIONS.INBOX_AUTO_RESPONSE_ENABLED
  const inboxSettingsFeature = inboxSignatureBlock || inboxAutoResponse

  const setFilterStateToCurrentWindowHash = () => {
    const {filterType, courseSelection} = parseFilterHash(window.location.hash)

    setCourseFilter(courseSelection)
    if (filterType) setScope(filterType)
  }

  const setUrlUserRecepientFromUrlParam = () => {
    const urlData = new URLSearchParams(window.location.search)
    const userIdFromUrlData = urlData.get('user_id')
    const userNameFromUrlData = urlData.get('user_name')
    const contextIdFromUrlData = urlData.get('context_id')
    if (userIdFromUrlData && userNameFromUrlData) {
      setUrlUserRecepient({
        _id: userIdFromUrlData,
        name: userNameFromUrlData,
        commonCoursesInfo: [],
        itemType: 'user',
      })
      if (contextIdFromUrlData) {
        setUrlContextId(contextIdFromUrlData)
      }
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
      setUrlContextId(null)
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
        selectedConversations[0]._id,
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

  // when selected Ids change, determine is maxGroupRecipients have been met,
  // so that we can programatically check and disable the
  // individual message checkbox
  useEffect(() => {
    let totalRecipients = 0
    selectedIds?.forEach(recipient => {
      totalRecipients += recipient.totalRecipients
    })
    setMaxGroupRecipientsMet(totalRecipients > ENV.CONVERSATIONS.MAX_GROUP_CONVERSATION_SIZE)
  }, [selectedIds])

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

  const userInboxLabelsQuery = useQuery(USER_INBOX_LABELS_QUERY, {
    variables: {userID: ENV.current_user_id?.toString()},
    fetchPolicy: 'cache-and-network',
    skip: !ENV?.react_inbox_labels,
  })

  useEffect(() => {
    if (conversationsQuery.loading) {
      setOnSuccess(I18n.t('Loading inbox conversations'))
    } else if (conversationsQuery.data) {
      const searchResults = [
        ...(conversationsQuery.data?.legacyNode?.conversationsConnection?.nodes ?? []),
      ]
      const successMessage =
        searchResults.length > 0
          ? I18n.t('%{count} Conversation messages loaded', {count: searchResults.length})
          : I18n.t('No Conversation messages loaded')
      setOnSuccess(successMessage)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [conversationsQuery.loading, conversationsQuery.data])

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
      JSON.stringify(cache.readQuery(conversationsQueryOption)),
    )
    const conversationParticipantIDsFromResult =
      result.data.updateConversationParticipants.conversationParticipants.map(cp => cp._id)

    const updatedCPs = conversationsFromCache.legacyNode.conversationsConnection.nodes.filter(
      conversationParticipant =>
        !conversationParticipantIDsFromResult.includes(conversationParticipant._id),
    )
    conversationsFromCache.legacyNode.conversationsConnection.nodes = updatedCPs
    cache.writeQuery({...conversationsQueryOption, data: conversationsFromCache})
  }

  const handleBack = () => {
    // clear conversation selection then use timeout to give time
    // for the conversation list to appear for mobile
    setSelectedConversations([])
    setTimeout(() => {
      document
        .querySelector(`[data-testid="open-conversation-for-${conversationIdToGoBackTo}"]`)
        .focus()
    }, 0)
  }

  const handleArchive = () => {
    const archiveConfirmMsg = I18n.t(
      {
        one: 'Are you sure you want to archive your copy of this conversation?',
        other: 'Are you sure you want to archive your copy of these conversations?',
      },
      {count: selectedConversations.length},
    )

    const confirmResult = window.confirm(archiveConfirmMsg)
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
      {count: selectedConversations.length},
    )

    const confirmResult = window.confirm(unarchiveConfirmMsg)
    if (confirmResult) {
      unarchiveConversationParticipants({
        variables: {
          conversationIds: selectedConversations.map(convo => convo._id),
          workflowState: 'read',
          subscribed: true,
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
      {count: selectedConversations.length},
    )
    if (data.updateConversationParticipants.errors) {
      setArchiveDisabled(false)
      setOnFailure(I18n.t('Archive operation failed'))
    } else {
      setArchiveDisabled(true)
      if (scope !== 'starred') {
        const selectedConversationIds = selectedConversations.map(convo => convo._id)
        removeFromSelectedConversations(selectedConversationIds)
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
      {count: selectedConversations.length},
    )
    if (data.updateConversationParticipants.errors) {
      setArchiveDisabled(true)
      setOnFailure(I18n.t('Unarchive operation failed'))
    } else {
      setArchiveDisabled(false)
      if (scope !== 'starred') {
        const selectedConversationIds = selectedConversations.map(convo => convo._id)
        removeFromSelectedConversations(selectedConversationIds)
      }
      setOnSuccess(unarchiveSuccessMsg, false)
    }
  }

  const [archiveConversationParticipants] = useMutation(UPDATE_CONVERSATION_PARTICIPANTS, {
    update: removeOutOfScopeConversationsFromCache,
    onCompleted: handleArchiveComplete,
    onError() {
      setOnFailure(I18n.t('Archive operation failed'))
    },
  })

  const [unarchiveConversationParticipants] = useMutation(UPDATE_CONVERSATION_PARTICIPANTS, {
    update: removeOutOfScopeConversationsFromCache,
    onCompleted: handleUnarchiveComplete,
    onError() {
      setOnFailure(I18n.t('Unarchive operation failed'))
    },
  })

  const [createUserInboxLabel] = useMutation(CREATE_USER_INBOX_LABEL, {
    update: (cache, result) => {
      if (result.data.createUserInboxLabel.errors) {
        return
      }

      const options = {
        query: USER_INBOX_LABELS_QUERY,
        variables: {userID: ENV.current_user_id?.toString()},
      }
      const labelsFromCache = JSON.parse(JSON.stringify(cache.readQuery(options)))

      labelsFromCache.legacyNode.inboxLabels = [...result.data.createUserInboxLabel.inboxLabels]

      cache.writeQuery({...options, data: labelsFromCache})
    },
    onError: () => {
      setOnFailure(I18n.t('Label(s) creation failed.'))
    },
  })

  const [deleteUserInboxLabel] = useMutation(DELETE_USER_INBOX_LABEL, {
    update: (cache, result) => {
      if (result.data.deleteUserInboxLabel.errors) {
        return
      }

      const options = {
        query: USER_INBOX_LABELS_QUERY,
        variables: {userID: ENV.current_user_id?.toString()},
      }
      const labelsFromCache = JSON.parse(JSON.stringify(cache.readQuery(options)))

      labelsFromCache.legacyNode.inboxLabels = [...result.data.deleteUserInboxLabel.inboxLabels]

      cache.writeQuery({...options, data: labelsFromCache})
    },
    onError: () => {
      setOnFailure(I18n.t('Label(s) deletion failed.'))
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
      {count: conversationsToDeleteByID.length},
    )
    const confirmResult = window.confirm(delMsg)
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
      {count: deletedConversationIDs.length},
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
      JSON.stringify(cache.readQuery(conversationsQueryOption)),
    )

    const conversationIDsFromResult = result.data.deleteConversations.conversationIds

    const updatedCPs = conversationsFromCache.legacyNode.conversationsConnection.nodes.filter(
      conversationParticipant => {
        return !conversationIDsFromResult.includes(conversationParticipant.conversation._id)
      },
    )

    conversationsFromCache.legacyNode.conversationsConnection.nodes = updatedCPs
    cache.writeQuery({...conversationsQueryOption, data: conversationsFromCache})
  }

  const [deleteConversations] = useMutation(DELETE_CONVERSATIONS, {
    update: removeDeletedConversationsFromCache,
    onCompleted: handleDeleteComplete,
    onError() {
      setOnFailure(I18n.t('Delete operation failed'))
    },
  })

  const firstConversation = selectedConversations.length > 0 ? selectedConversations[0] : {}

  const firstConversationIsStarred = firstConversation?.label === 'starred'

  const [starConversationParticipants] = useMutation(UPDATE_CONVERSATION_PARTICIPANTS, {
    onCompleted: data => {
      const isStarred =
        data.updateConversationParticipants.conversationParticipants[0].label === 'starred'
      const count = data.updateConversationParticipants.conversationParticipants.length
      if (!isStarred) {
        setOnSuccess(
          I18n.t(
            {
              one: 'The conversation has been successfully unstarred.',
              other: 'The conversations has been successfully unstarred.',
            },
            {count},
          ),
        )
      } else {
        setOnSuccess(
          I18n.t(
            {
              one: 'The conversation has been successfully starred.',
              other: 'The conversations has been successfully starred.',
            },
            {count},
          ),
        )
      }
    },
    onError: () => {
      setOnFailure(I18n.t('There was an unexpected error updating the conversation participants.'))
    },
  })

  const handleStar = (starred, conversations = null) => {
    const conversationIds =
      conversations?.map(convo => convo._id) || selectedConversations.map(convo => convo._id)
    const globalConversationIds =
      conversations?.map(convo => convo.id) || selectedConversations.map(convo => convo.id)
    starConversationParticipants({
      variables: {
        conversationIds,
        starred,
      },
      optimisticResponse: {
        updateConversationParticipants: {
          conversationParticipants: globalConversationIds.map(id => ({
            id,
            label: starred ? 'starred' : null,
            __typename: 'ConversationParticipant',
          })),
          errors: null,
          __typename: 'UpdateConversationParticipantsPayload',
        },
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
            {count: '1000'},
          ),
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
            {count: '1000'},
          ),
        )
      }
    },
    onError() {
      setOnFailure(I18n.t('Read state change failed'))
    },
  })

  const handleReadState = (markAsRead, conversations = null) => {
    const conversationIds =
      conversations?.map(convo => convo._id) || selectedConversations.map(convo => convo._id)
    const globalConversationIds =
      conversations?.map(convo => convo.id) || selectedConversations.map(convo => convo.id)
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
          conversationIds,
          workflowState: markAsRead,
        },
        optimisticResponse: {
          updateConversationParticipants: {
            conversationParticipants: globalConversationIds.map(id => ({
              id,
              workflowState: markAsRead,
              __typename: 'ConversationParticipant',
            })),
            errors: null,
            __typename: 'UpdateConversationParticipantsPayload',
          },
        },
      })
    }

    // always change this to whatever was just changed
    if (markAsRead === 'unread') {
      sessionStorage.setItem('conversationsManuallyMarkedUnread', JSON.stringify(conversationIds))
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
        selectedConversations.some(conversation => conversation.workflowState === 'archived'),
      )
    }
  }, [selectedConversations, userID])

  const handleDismissWithAlert = status => {
    setInboxSettingsModal(false)
    if (status === SAVE_SETTINGS_OK) {
      setOnSuccess(I18n.t('Inbox settings saved!'), false)
    } else if (status === SAVE_SETTINGS_FAIL) {
      setOnFailure(I18n.t('There was an error while saving inbox settings'))
    } else if (status === LOAD_SETTINGS_FAIL) {
      setOnFailure(I18n.t('There was an error while loading inbox settings'))
    }
  }

  const renderSettingsButton = () => {
    return (
      <Tooltip key="settings-button" renderTip={I18n.t('Inbox settings')} placement="top">
        <Button
          color="secondary"
          onClick={() => setInboxSettingsModal(true)}
          renderIcon={IconSettingsLine}
          display={getResponsiveStyles().buttonsDisplay}
          key="settings-button"
        >
          {I18n.t('Settings')}
        </Button>
      </Tooltip>
    )
  }

  const renderComposeButton = () => {
    return (
      <Tooltip key="compose-button" renderTip={I18n.t('Compose a new message')} placement="top">
        <Button
          color="primary"
          margin="none"
          renderIcon={IconComposeLine}
          onClick={() => {
            if (/#filter=type=submission_comments/.test(window.location.hash))
              window.location.hash = '#filter=type=inbox'
            setComposeModal(true)
          }}
          testid="compose"
          display={getResponsiveStyles().buttonsDisplay}
          ariaLabel={I18n.t('Compose a new message')}
        >
          {I18n.t('Compose')}
        </Button>
      </Tooltip>
    )
  }

  const renderActionButtons = () => {
    return breakpoints.mobileOnly
      ? [renderComposeButton(), renderSettingsButton()]
      : [renderSettingsButton(), renderComposeButton()]
  }

  const getResponsiveStyles = () => {
    return {
      conversationListWidth: breakpoints.mobileOnly ? '100%' : '400px',
      messageDetailMargin: breakpoints.mobileOnly ? '0 0 0 small' : undefined,
      buttonsWidth: breakpoints.mobileOnly ? '100%' : 'auto',
      buttonsDirection: breakpoints.mobileOnly ? 'column' : 'row',
      buttonsDisplay: breakpoints.mobileOnly ? 'block' : 'inline-block',
      headerMargin: breakpoints.ICEDesktop ? '0' : '0 0 medium 0',
      containerWidth: breakpoints.ICEDesktop ? 'auto' : '100%',
    }
  }

  return (
    <>
      <TopNavPortal />
      <ConversationContext.Provider value={conversationContext}>
        {!inboxSettingsFeature && (
          <Heading level="h1">
            <ScreenReaderContent>{I18n.t('Inbox')}</ScreenReaderContent>
          </Heading>
        )}
        <InstUISettingsProvider
          theme={{
            componentOverrides: {
              View: { borderColorSecondary: canvas.colors.contrasts.grey3045 }
            }
          }}
        >
          <Flex as="div" height="100vh" direction="column">
            {inboxSettingsFeature && (
              <Flex.Item>
                <Flex
                  data-testid="inbox-settings-in-header"
                  as="div"
                  direction="row"
                  justifyItems="space-between"
                  wrap="wrap"
                  overflowX="hidden"
                  overflowY="hidden"
                  margin="small medium medium medium"
                >
                  <Flex.Item width={getResponsiveStyles().containerWidth} shouldShrink={true}>
                    <Heading margin={getResponsiveStyles().headerMargin} level="h1">
                      {I18n.t('Inbox')}
                    </Heading>
                  </Flex.Item>
                  <Flex.Item width={getResponsiveStyles().buttonsWidth}>
                    <Flex
                      wrap="no-wrap"
                      direction={getResponsiveStyles().buttonsDirection}
                      gap="small"
                      justifyItems="end"
                      overflowX="hidden"
                      overflowY="hidden"
                      width="100%"
                      height="100%"
                    >
                      {renderActionButtons()}
                    </Flex>
                  </Flex.Item>
                </Flex>
              </Flex.Item>
            )}
            {(breakpoints.desktopOnly ||
              (breakpoints.mobileOnly && !selectedConversations.length) ||
              multiselect) && (
              <Flex.Item
                data-testid={
                  breakpoints.mobileOnly
                    ? 'mobile-message-action-header'
                    : 'desktop-message-action-header'
                }
              >
                <MessageListActionContainer
                  activeMailbox={scope}
                  activeCourseFilterID={courseFilter}
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
                  onManageLabels={() => (userInboxLabelsQuery.loading ? null : setManageLabels(true))}
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
                  showComposeButton={!inboxSettingsFeature} // TODO: after feature flag is removed, this should always be false
                />
              </Flex.Item>
            )}
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <Flex height="100%" as="div" align="center" justifyItems="center">
                {(breakpoints.desktopOnly ||
                  (breakpoints.mobileOnly && !selectedConversations.length) ||
                  multiselect) && (
                  <Flex.Item
                    width={
                      conversationLength || submissionCommentLength
                        ? getResponsiveStyles().conversationListWidth
                        : '100%'
                    }
                    height="100%"
                  >
                    <ConversationListContainer
                      course={courseFilter}
                      userFilter={userFilter}
                      scope={scope}
                      onSelectConversation={updateSelectedConversations}
                      onStarStateChange={handleStar}
                      onReadStateChange={handleReadState}
                      commonQueryVariables={commonQueryVariables}
                      conversationsQuery={conversationsQuery}
                      submissionCommentsQuery={submissionCommentsQuery}
                      setConversationIdToGoBackTo={setConversationIdToGoBackTo}
                    />
                  </Flex.Item>
                )}
                {(breakpoints.desktopOnly ||
                  (breakpoints.mobileOnly && selectedConversations.length > 0 && !multiselect)) && (
                  <Flex.Item
                    shouldGrow={true}
                    shouldShrink={true}
                    height="100%"
                    overflowY="auto"
                    margin={getResponsiveStyles().messageDetailMargin}
                  >
                    {!conversationsQuery.loading &&
                    !submissionCommentsQuery.loading &&
                    selectedConversations.length > 0 ? (
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
                        onBack={handleBack}
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
                        conversationsQueryOption={conversationsQueryOption}
                      />
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
        </InstUISettingsProvider>
        {inboxSettingsFeature && inboxSettingsModal && (
          <InboxSettingsModalContainer
            onDismissWithAlert={handleDismissWithAlert}
            inboxSignatureBlock={inboxSignatureBlock}
            inboxAutoResponse={inboxAutoResponse}
          />
        )}
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
          onSelectedIdsChange={setSelectedIds}
          selectedIds={selectedIds}
          contextIdFromUrl={urlContextId}
          maxGroupRecipientsMet={maxGroupRecipientsMet}
          activeCourseFilterID={courseFilter}
          inboxSignatureBlock={inboxSignatureBlock}
        />
        <ManageUserLabels
          open={manageLabels}
          labels={
            userInboxLabelsQuery.loading
              ? []
              : userInboxLabelsQuery.data?.legacyNode?.inboxLabels || []
          }
          onCreate={names => {
            createUserInboxLabel({
              variables: {
                names,
              },
            })
          }}
          onDelete={names => {
            deleteUserInboxLabel({
              variables: {
                names,
              },
            })
          }}
          onClose={() => setManageLabels(false)}
        />
      </ConversationContext.Provider>
    </>
  )
}

export default WithBreakpoints(CanvasInbox)
