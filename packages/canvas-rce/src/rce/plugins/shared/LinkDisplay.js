/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import formatMessage from '../../../format-message'
import {showFlashAlert} from '../../../common/FlashAlert'

const EDIT_MESSAGE = formatMessage('If left empty, link text will display as course link name')

export const LinkDisplay = ({
  linkText,
  Icon,
  placeholderText,
  linkFileName,
  published,
  handleTextChange,
}) => {
  useEffect(() => {
    showFlashAlert({
      message: formatMessage('Selected {linkFileName}', {linkFileName}),
      type: 'info',
      srOnly: true,
    })
  }, [linkFileName])

  return (
    <View as="div" data-testid="LinkDisplay">
      <View as="div">
        <Flex>
          <Flex.Item>
            <TextInput
              renderLabel={() => formatMessage('Text (optional)')}
              onChange={(e, value) => handleTextChange(value)}
              value={linkText}
              placeholder={placeholderText}
              messages={[{type: 'hint', text: EDIT_MESSAGE}]}
            />
          </Flex.Item>
        </Flex>
      </View>
      <View as="div" margin="medium none medium none">
        <Flex margin="small none small none">
          <Text weight="bold">Current Link</Text>
        </Flex>
        <Flex margin="small none none none">
          <Flex.Item padding="0 x-small 0 small">
            <Text data-testid="icon-wrapper" color={published ? 'success' : 'primary'}>
              <Icon size="x-small" />
            </Text>
          </Flex.Item>
          <Flex.Item padding="0 x-small 0 0" grow={true} shrink={true} textAlign="start">
            <View as="div">
              <span data-testid="selected-link-name">{linkFileName}</span>
            </View>
          </Flex.Item>
        </Flex>
      </View>
    </View>
  )
}
