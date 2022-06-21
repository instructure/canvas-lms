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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ConversationContext} from '../../util/constants'
import {CONVERSATIONS_QUERY, VIEWABLE_SUBMISSIONS_QUERY} from '../../graphql/Queries'
import {UPDATE_CONVERSATION_PARTICIPANTS} from '../../graphql/Mutations'
import {ConversationListHolder} from '../components/ConversationListHolder/ConversationListHolder'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Mask} from '@instructure/ui-overlays'
import PropTypes from 'prop-types'
import React, {useContext, useMemo, useState} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {useQuery, useMutation} from 'react-apollo'
import {View} from '@instructure/ui-view'
import {inboxConversationsWrapper, responsiveQuerySizes} from '../../util/utils'
import {Responsive} from '@instructure/ui-responsive'

const I18n = useI18nScope('conversations_2')

const ConversationListContainer = ({course, scope, onSelectConversation, userFilter}) => {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const {isSubmissionCommentsType} = useContext(ConversationContext)
  const [isLoadingMoreData, setIsLoadingMoreData] = useState(false)

  const userID = ENV.current_user_id?.toString()

  const [starChangeConversationParticipants] = useMutation(UPDATE_CONVERSATION_PARTICIPANTS, {
    onCompleted(data) {
      if (data.updateConversationParticipants.errors) {
        setOnFailure(I18n.t('There was an unexpected error updating the conversation participants'))
      } else {
        const isStarred =
          data.updateConversationParticipants.conversationParticipants[0].label === 'starred'

        if (isStarred) {
          setOnSuccess(I18n.t('The conversation has been successfully starred'))
        } else {
          setOnSuccess(I18n.t('The conversation has been successfully unstarred'))
        }
      }
    },
    onError() {
      setOnFailure(I18n.t('There was an unexpected error updating the conversation participants'))
    }
  })

  const handleStar = (starred, conversationId) => {
    starChangeConversationParticipants({
      variables: {
        conversationIds: [conversationId],
        starred
      }
    })
  }

  const conversationsQuery = useQuery(CONVERSATIONS_QUERY, {
    variables: {userID, scope, filter: [userFilter, course]},
    fetchPolicy: 'cache-and-network',
    skip: isSubmissionCommentsType || scope === 'submission_comments'
  })

  const submissionCommentsQuery = useQuery(VIEWABLE_SUBMISSIONS_QUERY, {
    variables: {userID, sort: 'desc'},
    fetchPolicy: 'cache-and-network',
    skip: !isSubmissionCommentsType || !(scope === 'submission_comments')
  })

  const fetchMoreMenuData = () => {
    setIsLoadingMoreData(true)
    if (!isSubmissionCommentsType) {
      conversationsQuery.fetchMore({
        variables: {
          _id: inboxItemData[inboxItemData.length - 1]._node_id,
          userID,
          scope,
          filter: [userFilter, course],
          afterConversation:
            conversationsQuery.data?.legacyNode?.conversationsConnection?.pageInfo.endCursor
        },
        updateQuery: (previousResult, {fetchMoreResult}) => {
          setIsLoadingMoreData(false)

          const prev_nodes = previousResult.legacyNode.conversationsConnection.nodes
          const fetchMore_nodes = fetchMoreResult.legacyNode.conversationsConnection.nodes
          const fetchMore_pageInfo = fetchMoreResult?.legacyNode?.conversationsConnection?.pageInfo
          return {
            legacyNode: {
              _id: fetchMoreResult?.legacyNode?._id,
              id: fetchMoreResult?.legacyNode?.id,
              conversationsConnection: {
                nodes: [...prev_nodes, ...fetchMore_nodes],
                pageInfo: fetchMore_pageInfo,
                __typename: 'ConversationParticipantConnection'
              },
              __typename: 'User'
            }
          }
        }
      })
    } else {
      submissionCommentsQuery.fetchMore({
        variables: {
          _id: inboxItemData[inboxItemData.length - 1]._node_id,
          userID,
          sort: 'desc',
          afterSubmission:
            submissionCommentsQuery.data?.legacyNode?.viewableSubmissionsConnection?.pageInfo
              .endCursor
        },
        updateQuery: (previousResult, {fetchMoreResult}) => {
          setIsLoadingMoreData(false)

          const prev_nodes = previousResult.legacyNode.viewableSubmissionsConnection.nodes
          const fetchMore_nodes = fetchMoreResult.legacyNode.viewableSubmissionsConnection.nodes
          const fetchMore_pageInfo =
            fetchMoreResult?.legacyNode?.viewableSubmissionsConnection?.pageInfo
          return {
            legacyNode: {
              _id: fetchMoreResult?.legacyNode?._id,
              id: fetchMoreResult?.legacyNode?.id,
              viewableSubmissionsConnection: {
                nodes: [...prev_nodes, ...fetchMore_nodes],
                pageInfo: fetchMore_pageInfo,
                __typename: 'SubmissionConnection'
              },
              __typename: 'User'
            }
          }
        }
      })
    }
  }

  const inboxItemData = useMemo(() => {
    if (
      (conversationsQuery.loading && !conversationsQuery.data) ||
      (submissionCommentsQuery.loading && !submissionCommentsQuery.data)
    ) {
      return []
    }
    const data = isSubmissionCommentsType
      ? submissionCommentsQuery.data?.legacyNode?.viewableSubmissionsConnection?.nodes
      : conversationsQuery.data?.legacyNode?.conversationsConnection?.nodes
    const inboxData = inboxConversationsWrapper(data, isSubmissionCommentsType)

    if (inboxData.length > 0 && !conversationsQuery.loading && !submissionCommentsQuery.loading) {
      inboxData[inboxData.length - 1].isLast = true
    }
    return inboxData
  }, [
    conversationsQuery.loading,
    conversationsQuery.data,
    submissionCommentsQuery.loading,
    submissionCommentsQuery.data,
    isSubmissionCommentsType
  ])

  const renderLoading = () => {
    return (
      <View as="div" style={{position: 'relative'}} height="100%">
        <Mask>
          <Spinner renderTitle={() => I18n.t('Loading Message List')} variant="inverse" />
        </Mask>
      </View>
    )
  }

  if (conversationsQuery.loading && submissionCommentsQuery.loading) {
    renderLoading()
  }

  return (
    <span id="inbox-conversation-holder">
      <Responsive
        match="media"
        query={responsiveQuerySizes({mobile: true, tablet: true, desktop: true})}
        props={{
          mobile: {
            textSize: 'x-small',
            datatestid: 'list-items-mobile'
          },
          tablet: {
            textSize: 'x-small',
            datatestid: 'list-items-tablet'
          },
          desktop: {
            textSize: 'small',
            datatestid: 'list-items-desktop'
          }
        }}
        render={responsiveProps => (
          <ConversationListHolder
            conversations={inboxItemData}
            onSelect={onSelectConversation}
            onStar={handleStar}
            textSize={responsiveProps.textSize}
            datatestid={responsiveProps.datatestid}
            hasMoreMenuData={
              conversationsQuery.data?.legacyNode?.conversationsConnection?.pageInfo?.hasNextPage ||
              submissionCommentsQuery.data?.legacyNode?.viewableSubmissionsConnection?.pageInfo
                ?.hasNextPage
            }
            fetchMoreMenuData={fetchMoreMenuData}
            isLoadingMoreMenuData={isLoadingMoreData}
            isLoading={conversationsQuery.loading || submissionCommentsQuery.loading}
            isError={conversationsQuery.error || submissionCommentsQuery.error}
          />
        )}
      />
    </span>
  )
}

export default ConversationListContainer

ConversationListContainer.propTypes = {
  course: PropTypes.string,
  userFilter: PropTypes.number,
  scope: PropTypes.string,
  onSelectConversation: PropTypes.func
}

ConversationListContainer.defaultProps = {
  scope: 'inbox',
  onSelectConversation: () => {}
}
