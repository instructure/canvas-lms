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
import {SearchContext} from '../../utils/constants'
import {View} from '@instructure/ui-view'

export const DiscussionPostToolbarContainer = props => {
  const {searchTerm, filter, sort, setSearchTerm, setFilter, setSort} = useContext(SearchContext)
  const [currentSearchValue, setCurrentSearchValue] = useState('')

  useEffect(() => {
    const interval = setInterval(() => {
      if (currentSearchValue !== searchTerm) {
        setSearchTerm(currentSearchValue)
      }
    }, 500)

    return () => clearInterval(interval)
  }, [currentSearchValue, searchTerm, setSearchTerm])

  const onViewFilter = (_event, value) => {
    setFilter(value.value)
  }

  const onSortClick = () => {
    sort === 'asc' ? setSort('desc') : setSort('asc')
  }

  const getGroupsMenuTopics = () => {
    if (!props.discussionTopic.permissions?.readAsAdmin) {
      return null
    }
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
      />
    </View>
  )
}

DiscussionPostToolbarContainer.propTypes = {
  discussionTopic: Discussion.shape
}

export default DiscussionPostToolbarContainer
