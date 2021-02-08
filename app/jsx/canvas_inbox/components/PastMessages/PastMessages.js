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

import PropTypes from 'prop-types'
import React from 'react'

import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const PastMessage = props => (
  <View as="div" borderWidth="small none none none">
    <Flex direction="column" margin="medium">
      <Flex.Item>
        <Flex wrap="wrap">
          <Flex.Item shouldShrink shouldGrow>
            <Text>{props.name}</Text>
          </Flex.Item>
          <Flex.Item>
            <Text weight="light">{props.date}</Text>
          </Flex.Item>
        </Flex>
      </Flex.Item>
      <Flex.Item margin="x-small 0 0 0">
        <Text weight="light">{props.messageBody}</Text>
      </Flex.Item>
    </Flex>
  </View>
)

export const PastMessages = props => {
  return (
    <Flex direction="column">
      {props.messages.map(message => (
        <Flex.Item key={btoa(JSON.stringify(message))}>
          <PastMessage {...message} />
        </Flex.Item>
      ))}
    </Flex>
  )
}

PastMessages.propTypes = {
  messages: PropTypes.arrayOf(
    PropTypes.shape({
      name: PropTypes.string,
      date: PropTypes.string,
      messageBody: PropTypes.string
    })
  )
}
