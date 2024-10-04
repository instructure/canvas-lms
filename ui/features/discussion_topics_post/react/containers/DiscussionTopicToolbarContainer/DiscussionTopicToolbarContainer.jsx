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

import {Discussion} from '../../../graphql/Discussion'
import {DiscussionPostToolbar} from '../../components/DiscussionPostToolbar/DiscussionPostToolbar'
import PropTypes from 'prop-types'
import React, {useContext, useEffect, useState} from 'react'
import {
  DiscussionManagerUtilityContext,
  SEARCH_TERM_DEBOUNCE_DELAY,
  SearchContext,
} from '../../utils/constants'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TranslationControls} from '../../components/TranslationControls/TranslationControls'
import {useMutation} from 'react-apollo'
import {UPDATE_DISCUSSION_SORT_ORDER} from '../../../graphql/Mutations'

export const DiscussionTopicToolbarContainer = props => {
  const {searchTerm, filter, sort, setSearchTerm, setFilter, setSort} = useContext(SearchContext)
  const {showTranslationControl} = useContext(DiscussionManagerUtilityContext)
  const [currentSearchValue, setCurrentSearchValue] = useState(searchTerm || '')

  useEffect(() => {
    const interval = setInterval(() => {
      if (currentSearchValue !== searchTerm) {
        setSearchTerm(currentSearchValue)
      }
    }, SEARCH_TERM_DEBOUNCE_DELAY)

    return () => clearInterval(interval)
  }, [currentSearchValue, searchTerm, setSearchTerm])

  const onViewFilter = (_event, value) => {
    setFilter(value.value)
  }

  const [updateDiscussionSortOrder] = useMutation(UPDATE_DISCUSSION_SORT_ORDER)

  const onSortClick = () => {
    let newOrder = null
    if (sort === null) {
      newOrder = props.discussionTopic.sortOrder === 'asc' ? 'desc' : 'asc'
    } else {
      newOrder = sort === 'asc' ? 'desc' : 'asc'
    }
    setSort(newOrder)
    updateDiscussionSortOrder({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        sortOrder: newOrder,
      },
    })
  }

  const onSummarizeClick = () => {
    props.setIsSummaryEnabled(true)
  }

  const getGroupsMenuTopics = () => {
    if (!props.discussionTopic.groupSet) {
      return null
    }
    if (props.discussionTopic.childTopics?.length > 0) {
      return props.discussionTopic.childTopics
    } else if (props.discussionTopic.rootTopic?.childTopics?.length > 0) {
      return props.discussionTopic.rootTopic.childTopics
    } else {
      return []
    }
  }

  return (
    <View as="div" padding="0 0 medium 0" background="primary">
      <ScreenReaderContent>
        <h1>{props.discussionTopic.title}</h1>
      </ScreenReaderContent>
      <DiscussionPostToolbar
        isAdmin={props.discussionTopic.permissions.readAsAdmin}
        canEdit={props.discussionTopic.permissions.update}
        childTopics={getGroupsMenuTopics()}
        selectedView={filter}
        sortDirection={props.discussionTopic.sortOrder}
        isCollapsedReplies={true}
        onSearchChange={value => setCurrentSearchValue(value)}
        onViewFilter={onViewFilter}
        onSortClick={onSortClick}
        onCollapseRepliesToggle={() => {}}
        onTopClick={() => {}}
        searchTerm={currentSearchValue}
        discussionAnonymousState={props.discussionTopic.anonymousState}
        canReplyAnonymously={props.discussionTopic.canReplyAnonymously}
        setUserSplitScreenPreference={props.setUserSplitScreenPreference}
        userSplitScreenPreference={props.userSplitScreenPreference}
        onSummarizeClick={onSummarizeClick}
        isSummaryEnabled={props.isSummaryEnabled}
        closeView={props.closeView}
        discussionId={props.discussionTopic._id}
        typeName={props.discussionTopic.__typename?.toLowerCase()}
        discussionTitle={props.discussionTopic.title}
        pointsPossible={props.discussionTopic.assignment?.pointsPossible}
        isAnnouncement={props.discussionTopic.isAnnouncement}
        isGraded={props.discussionTopic.assignment !== null}
        contextType={props.discussionTopic.contextType}
        manageAssignTo={props.discussionTopic.permissions.manageAssignTo}
        isGroupDiscussion={props.discussionTopic.groupSet !== null}
        isCheckpointed={props?.discussionTopic?.assignment?.checkpoints?.length > 0}
      />
      {showTranslationControl && <TranslationControls />}
    </View>
  )
}

DiscussionTopicToolbarContainer.propTypes = {
  discussionTopic: Discussion.shape,
  setUserSplitScreenPreference: PropTypes.func,
  userSplitScreenPreference: PropTypes.bool,
  isSummaryEnabled: PropTypes.bool,
  setIsSummaryEnabled: PropTypes.func,
  closeView: PropTypes.func,
}

export default DiscussionTopicToolbarContainer
