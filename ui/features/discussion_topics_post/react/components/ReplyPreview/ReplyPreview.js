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

import DateHelper from '../../../../../shared/datetime/dateHelper'
import PropTypes from 'prop-types'
import React from 'react'

import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

export const ReplyPreview = ({...props}) => {
  return (
    <View as="div" borderWidth="0 0 0 large" padding="x-small 0 x-small medium">
      <Flex direction="column">
        <Flex.Item>
          <View>
            <Text weight="bold">{props.authorName}</Text>
          </View>
          <View margin="0 0 0 small">
            <Text>{DateHelper.formatDatetimeForDiscussions(props.createdAt)}</Text>
          </View>
        </Flex.Item>
        <Flex.Item margin="small 0 0 0">
          <Text>{props.message}</Text>
        </Flex.Item>
      </Flex>
    </View>
  )
}

ReplyPreview.propTypes = {
  /**
   * Quoted author
   */
  authorName: PropTypes.string,
  /**
   * Quoted reply created at date
   */
  createdAt: PropTypes.string,
  /**
   * Quoted message
   */
  message: PropTypes.string
}
