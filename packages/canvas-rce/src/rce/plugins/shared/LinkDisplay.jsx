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
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {getIcon, getFriendlyLinkType} from './linkUtils'

const getEditMessage = () =>
  formatMessage('If left empty, link text will display as course link name')

export const LinkDisplay = ({
  linkText,
  placeholderText,
  linkFileName,
  published,
  handleTextChange,
  linkType,
}) => {
  useEffect(() => {
    showFlashAlert({
      message: formatMessage('Selected {linkFileName}', {linkFileName}),
      type: 'info',
      srOnly: true,
    })
  }, [linkFileName])

  const Icon = getIcon(linkType)
  const linkTypeMessage = getFriendlyLinkType(linkType)
  const publishedMessage = published ? formatMessage('published') : formatMessage('unpublished')

  return (
    <View as="div" data-testid="LinkDisplay">
      <View as="div">
        <Flex>
          <Flex.Item>
            <TextInput
              data-testid="link-text-input"
              renderLabel={() => formatMessage('Text (optional)')}
              onChange={(_e, value) => handleTextChange(value)}
              value={linkText}
              placeholder={placeholderText}
              messages={[{type: 'hint', text: getEditMessage()}]}
            />
          </Flex.Item>
        </Flex>
      </View>
      <View as="div" margin="medium none medium none">
        <Flex margin="small none small none">
          <Text weight="bold">{formatMessage('Current Link')}</Text>
        </Flex>
        <Flex margin="small none none none">
          <Flex.Item padding="0 x-small 0 small">
            <Text data-testid="icon-wrapper" color={published ? 'success' : 'primary'}>
              <Icon size="x-small" />
            </Text>
          </Flex.Item>
          <Flex.Item
            padding="0 x-small 0 0"
            shouldGrow={true}
            shouldShrink={true}
            textAlign="start"
          >
            <View as="div">
              <span data-testid="selected-link-name">{linkFileName}</span>
              {linkType && (
                <ScreenReaderContent data-testid="screenreader_content">
                  {formatMessage('link type: {linkTypeMessage}', {linkTypeMessage})}
                  {linkType !== 'navigation' && publishedMessage}
                </ScreenReaderContent>
              )}
            </View>
          </Flex.Item>
        </Flex>
      </View>
    </View>
  )
}
