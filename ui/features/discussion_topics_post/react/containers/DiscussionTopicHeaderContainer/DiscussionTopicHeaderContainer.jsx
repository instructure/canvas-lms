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
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import PropTypes from 'prop-types'

const instUINavEnabled = () => window.ENV?.FEATURES?.instui_nav

export const DiscussionTopicHeaderContainer = props => {
  if (!instUINavEnabled()) {
    return null
  }

  return (
    <Flex direction="column" as="div" gap="medium">
      <Flex.Item overflow="hidden">
        <Flex as="div" direction="row" justifyItems="start" wrap="wrap">
          <Flex.Item margin="0 0 x-small 0">
            <Heading level="h1">{props.discussionTopicTitle}</Heading>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

DiscussionTopicHeaderContainer.propTypes = {
  discussionTopicTitle: PropTypes.string,
}

export default DiscussionTopicHeaderContainer
