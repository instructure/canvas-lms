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

import {ConversationContext} from '../../util/constants'
import {ConversationListHolder} from '../components/ConversationListHolder/ConversationListHolder'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Mask} from '@instructure/ui-overlays'
import PropTypes from 'prop-types'
import React, {useContext, useMemo, useState} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {inboxConversationsWrapper, responsiveQuerySizes} from '../../util/utils'
import {Responsive} from '@instructure/ui-responsive'

const I18n = useI18nScope('conversations_2')

const ConversationListContainer = ({
  scope,
  onSelectConversation,
  onReadStateChange,
  onStarStateChange,
  commonQueryVariables,
  conversationsQuery,
  submissionCommentsQuery,
  setConversationIdToGoBackTo,
}) => {
  const {isSubmissionCommentsType} = useContext(ConversationContext)
  const [isLoadingMoreData, setIsLoadingMoreData] = useState(false)

  const handleMarkAsUnread = conversation => {
    onReadStateChange('unread', [conversation])
  }

  const handleMarkAsRead = conversation => {
    onReadStateChange('read', [conversation])
  }

  const fetchMoreMenuData = () => {
    setIsLoadingMoreData(true)
    if (!isSubmissionCommentsType) {
      conversationsQuery.fetchMore({
        variables: {
          ...commonQueryVariables,
          _id: inboxItemData[inboxItemData.length - 1]._node_id,
          scope,
          afterConversation:
            conversationsQuery.data?.legacyNode?.conversationsConnection?.pageInfo.endCursor,
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
                __typename: 'ConversationParticipantConnection',
              },
              __typename: 'User',
            },
          }
        },
      })
    } else {
      submissionCommentsQuery.fetchMore({
        variables: {
          ...commonQueryVariables,
          _id: inboxItemData[inboxItemData.length - 1]._node_id,
          sort: 'desc',
          afterSubmission:
            submissionCommentsQuery.data?.legacyNode?.viewableSubmissionsConnection?.pageInfo
              .endCursor,
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
                __typename: 'SubmissionConnection',
              },
              __typename: 'User',
            },
          }
        },
      })
    }
  }

  const inboxItemData = useMemo(() => {
    if (
      (conversationsQuery.loading && !conversationsQuery?.data?.legacyNode) ||
      (submissionCommentsQuery.loading && !submissionCommentsQuery?.data?.legacyNode)
    ) {
      return []
    }

    const data = isSubmissionCommentsType
      ? submissionCommentsQuery.data?.legacyNode?.viewableSubmissionsConnection?.nodes
      : conversationsQuery.data?.legacyNode?.conversationsConnection?.nodes?.filter(
          ({conversation}) => conversation
        )
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
    isSubmissionCommentsType,
  ])

  const renderLoading = () => {
    return (
      <View as="div" style={{position: 'relative'}} height="100%">
        <Mask>
          <Spinner
            renderTitle={() => I18n.t('Loading Message List')}
            variant="inverse"
            delay={300}
          />
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
            datatestid: 'list-items-mobile',
            truncateSize: 90,
          },
          tablet: {
            textSize: 'x-small',
            datatestid: 'list-items-tablet',
            truncateSize: 40,
          },
          desktop: {
            textSize: 'small',
            datatestid: 'list-items-desktop',
            truncateSize: 40,
          },
        }}
        render={responsiveProps => (
          <ConversationListHolder
            conversations={inboxItemData}
            onSelect={onSelectConversation}
            onStar={onStarStateChange}
            onMarkAsRead={handleMarkAsRead}
            onMarkAsUnread={handleMarkAsUnread}
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
            truncateSize={responsiveProps.truncateSize}
            setConversationIdToGoBackTo={setConversationIdToGoBackTo}
          />
        )}
      />
    </span>
  )
}

export default ConversationListContainer

ConversationListContainer.propTypes = {
  scope: PropTypes.string,
  onSelectConversation: PropTypes.func,
  onReadStateChange: PropTypes.func,
  onStarStateChange: PropTypes.func,
  commonQueryVariables: PropTypes.object,
  conversationsQuery: PropTypes.object,
  submissionCommentsQuery: PropTypes.object,
  setConversationIdToGoBackTo: PropTypes.func,
}

ConversationListContainer.defaultProps = {
  scope: 'inbox',
  onSelectConversation: () => {},
  setConversationIdToGoBackTo: () => {},
}
