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

import React, {useEffect} from 'react'

import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'

import formatMessage from '../../../../../format-message'
import {TextArea} from '@instructure/ui-text-area'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {IconQuestionLine} from '@instructure/ui-icons'
import {decode} from '../../svg/utils'

export const Header = ({settings, onChange, allowNameChange}) => {
  const originalName = settings.originalName

  useEffect(() => {
    if (!allowNameChange) onChange({name: originalName})
  }, [allowNameChange, onChange, originalName])

  const tooltipText = formatMessage('Used by screen readers to describe the content of an image')
  const textAreaLabel = (
    <Flex alignItems="center">
      <Flex.Item>{formatMessage('Alt Text')}</Flex.Item>

      <Flex.Item margin="0 0 0 xx-small">
        <Tooltip
          on={['hover', 'focus']}
          placement="top"
          tip={
            <View display="block" id="alt-text-label-tooltip" maxWidth="14rem">
              {tooltipText}
            </View>
          }
        >
          <Button icon={IconQuestionLine} size="small" variant="icon" />
        </Tooltip>
      </Flex.Item>
    </Flex>
  )
  return (
    <Flex direction="column" padding="small small 0">
      <Flex.Item padding="small">
        <TextInput
          id="button-name"
          data-testid="button-name"
          renderLabel={formatMessage('Name')}
          placeholder={formatMessage('untitled')}
          interaction={allowNameChange ? 'enabled' : 'disabled'}
          onChange={e => {
            const name = e.target.value
            onChange({name})
          }}
          value={settings.name ? decode(settings.name) : ''}
        />
      </Flex.Item>
      <Flex.Item padding="small">
        <TextArea
          id="button-alt-text"
          height="4rem"
          label={textAreaLabel}
          onChange={e => {
            const alt = e.target.value
            onChange({alt})
          }}
          placeholder={formatMessage('(Describe the image)')}
          resize="vertical"
          value={settings.alt}
        />
      </Flex.Item>
    </Flex>
  )
}
