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
import {IconButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconQuestionLine} from '@instructure/ui-icons'
import {FormFieldLabel} from '@instructure/ui-form-field'
import {decode} from '../../svg/utils'
import useDebouncedValue from '../../utils/useDebouncedValue'

const getAltTextLabel = () => (
  <Flex alignItems="center" margin="0 0 small 0">
    <Flex.Item>
      <FormFieldLabel>{formatMessage('Alt Text')}</FormFieldLabel>
    </Flex.Item>
    <Flex.Item margin="0 0 0 xx-small">
      <Tooltip
        on={['hover', 'focus']}
        placement="top"
        renderTip={
          <View display="block" id="alt-text-label-tooltip" maxWidth="14rem">
            {formatMessage('Used by screen readers to describe the content of an image')}
          </View>
        }
      >
        <IconButton
          renderIcon={IconQuestionLine}
          withBackground={false}
          withBorder={false}
          size="small"
          screenReaderLabel={formatMessage('Toggle tooltip')}
        />
      </Tooltip>
    </Flex.Item>
  </Flex>
)

export const Header = ({settings, onChange, allowNameChange, nameRef, editing}) => {
  const originalName = settings.originalName

  const [name, setName] = useDebouncedValue(settings.name, n => onChange({name: n}))
  const [alt, setAlt] = useDebouncedValue(settings.alt, a => onChange({alt: a}))

  useEffect(() => {
    if (!allowNameChange) onChange({name: originalName})
  }, [allowNameChange, onChange, originalName])

  return (
    <Flex direction="column" padding="small small 0">
      <Flex.Item padding="small">
        <TextInput
          id="icon-name"
          data-testid="icon-name"
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
      {!editing && (
        <>
          <Flex.Item padding="small">
            {getAltTextLabel()}
            <TextArea
              label=""
              aria-label={formatMessage('Alt Text')}
              id="icon-alt-text"
              height="4rem"
              disabled={settings.isDecorative}
              onChange={setAlt}
              placeholder={formatMessage('(Describe the icon)')}
              resize="vertical"
              value={alt}
            />
          </Flex.Item>
          <Flex.Item padding="small">
            <Checkbox
              checked={settings.isDecorative}
              label={formatMessage('Decorative Icon')}
              onChange={() => onChange({isDecorative: !settings.isDecorative})}
            />
          </Flex.Item>
        </>
      )}
    </Flex>
  )
}
