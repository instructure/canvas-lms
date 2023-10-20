/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import DateHelper from '@canvas/datetime/dateHelper'
import PropTypes from 'prop-types'

import {Avatar} from '@instructure/ui-avatar'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

const SubmissionComment = ({comment}) => {
  return (
    <Flex as="div" direction="column">
      <Flex.Item padding="medium 0 0 0">
        <Flex>
          <Flex.Item>
            <Avatar name={comment?.author?.shortName} margin="0 small 0 0" />
          </Flex.Item>
          <Flex.Item>
            <Flex direction="column">
              <Flex.Item shouldGrow={true} shouldShrink={true}>
                <Text size="small">{comment?.author?.shortName}</Text>
              </Flex.Item>
              <Flex.Item shouldGrow={true} shouldShrink={true}>
                <Text size="small">{DateHelper.formatDatetimeForDisplay(comment?.createdAt)}</Text>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      </Flex.Item>
      <Flex.Item shouldGrow={true} shouldShrink={true} padding="medium 0 0 0">
        <Text>{comment.comment}</Text>
      </Flex.Item>
    </Flex>
  )
}

SubmissionComment.propTypes = {
  comment: PropTypes.shape({
    author: PropTypes.shape({
      shortName: PropTypes.string,
    }),
    createdAt: PropTypes.string,
    comment: PropTypes.string,
  }),
}

export default SubmissionComment
