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
import React, {useContext, useEffect, useState} from 'react'
import {SEARCH_TERM_DEBOUNCE_DELAY, SearchContext} from '../../utils/constants'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

export const DiscussionTopicToolbarContainer = props => {
  const {searchTerm, filter, sort, setSearchTerm, setFilter, setSort} = useContext(SearchContext)
  const [currentSearchValue, setCurrentSearchValue] = useState('')

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

  const onSortClick = () => {
    sort === 'asc' ? setSort('desc') : setSort('asc')
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
        childTopics={getGroupsMenuTopics()}
        selectedView={filter}
        sortDirection={sort}
        isCollapsedReplies
        onSearchChange={value => setCurrentSearchValue(value)}
        onViewFilter={onViewFilter}
        onSortClick={onSortClick}
        onCollapseRepliesToggle={() => {}}
        onTopClick={() => {}}
        searchTerm={currentSearchValue}
        discussionAnonymousState={props.discussionTopic.anonymousState}
        canReplyAnonymously={props.discussionTopic.canReplyAnonymously}
      />
    </View>
  )
}

DiscussionTopicToolbarContainer.propTypes = {
  discussionTopic: Discussion.shape
}

export default DiscussionTopicToolbarContainer
