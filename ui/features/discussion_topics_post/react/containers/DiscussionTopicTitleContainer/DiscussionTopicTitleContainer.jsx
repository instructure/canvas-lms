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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import PropTypes from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {HeadingMenu} from '@canvas/discussions/react/components/HeadingMenu'

const I18n = createI18nScope('discussions_v2')

const getFilters = title => ({
  all: {name: I18n.t('All Replies'), title},
  unread: {name: I18n.t('Unread Replies'), title},
})

const DiscussionTopicTitleContainer = ({
  discussionTopicTitle,
  mobileHeader = false,
  onViewFilter,
  selectedView,
}) => {
  const onFilterChange = event => {
    onViewFilter(event, {value: event.value})
  }

  return (
    <Flex direction="column" as="div" gap="medium">
      <Flex.Item>
        <Flex as="div" direction="row" justifyItems="start" wrap="wrap">
          <Flex.Item margin="0 0 x-small 0" padding="xxx-small">
            <HeadingMenu
              name={I18n.t('Discussion Filter')}
              filters={getFilters(discussionTopicTitle)}
              defaultSelectedFilter={selectedView ?? 'all'}
              onSelectFilter={onFilterChange}
              mobileHeader={mobileHeader}
            />
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

DiscussionTopicTitleContainer.propTypes = {
  discussionTopicTitle: PropTypes.string,
  mobileHeader: PropTypes.bool,
  onViewFilter: PropTypes.func,
  selectedView: PropTypes.string,
}
export default DiscussionTopicTitleContainer
