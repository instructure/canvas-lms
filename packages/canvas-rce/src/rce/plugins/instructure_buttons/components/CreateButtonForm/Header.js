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
import useDebouncedValue from '../../utils/useDebouncedValue'

export const Header = ({settings, onChange, allowNameChange, nameRef}) => {
  const originalName = settings.originalName

  const [name, setName, setImmediateName] = useDebouncedValue(settings.name, n =>
    onChange({name: n})
  )
  const [alt, setAlt] = useDebouncedValue(settings.alt, a => onChange({alt: a}))

  useEffect(() => {
    if (!allowNameChange) onChange({name: originalName})
  }, [allowNameChange, onChange, originalName])

  useEffect(() => {
    // The "immediate" bit of name state may have been initialized to an
    // empty value if the app has not yet fetched the file's name from the
    // API (on icon edit).
    //
    // If that's the case, we need to update the "immediate" piece of name
    // state to present the file name.
    if (!name && !!settings.name) {
      setImmediateName(settings.name)
    }
  }, [name, setImmediateName, settings.name])

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
          onChange={setName}
          value={name ? decode(name) : ''}
          inputRef={ref => {
            if (nameRef) nameRef.current = ref
          }}
        />
      </Flex.Item>
      <Flex.Item padding="small">
        <TextArea
          id="button-alt-text"
          height="4rem"
          label={textAreaLabel}
          onChange={setAlt}
          placeholder={formatMessage('(Describe the image)')}
          resize="vertical"
          value={alt}
        />
      </Flex.Item>
    </Flex>
  )
}
