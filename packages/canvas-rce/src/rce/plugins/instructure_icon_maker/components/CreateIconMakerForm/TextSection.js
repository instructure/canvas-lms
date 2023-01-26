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
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ColorInput} from '../../../shared/ColorInput'

import formatMessage from '../../../../../format-message'
import {Group} from './Group'
import {MAX_TOTAL_TEXT_CHARS} from '../../svg/constants'
import useDebouncedValue from '../../utils/useDebouncedValue'

const TEXT_SIZES = ['small', 'medium', 'large', 'x-large']
const TEXT_POSITIONS = ['middle', 'bottom-third', 'below']

const getTextSection = () => document.querySelector('#icons-tray-text-section')

const processText = (oldValue, newValue) => {
  let result = newValue
  if (newValue.length > MAX_TOTAL_TEXT_CHARS) {
    if (oldValue.length >= MAX_TOTAL_TEXT_CHARS) {
      // When typing chars
      result = oldValue
    } else {
      // When pasting text
      result = result.substring(0, MAX_TOTAL_TEXT_CHARS)
    }
  }
  return result
}

export const TextSection = ({settings, onChange}) => {
  const [text, setText] = useDebouncedValue(
    settings.text || '',
    value => onChange({text: value}),
    value => processText(text, value)
  )

  return (
    <Group as="section" defaultExpanded={true} summary={formatMessage('Text')}>
      <Flex
        as="section"
        justifyItems="space-between"
        direction="column"
        id="icons-tray-text-section"
      >
        <Flex.Item padding="small">
          <TextInput
            id="icon-text"
            renderLabel={formatMessage('Text')}
            onChange={setText}
            value={text}
            messages={[
              {
                text: `${text.length}/${MAX_TOTAL_TEXT_CHARS}`,
                type: 'hint',
              },
            ]}
          />
        </Flex.Item>

        <Flex.Item padding="small">
          <SimpleSelect
            assistiveText={formatMessage('Use arrow keys to select a text size.')}
            id="icon-text-size"
            mountNode={getTextSection}
            onChange={(e, option) => onChange({textSize: option.value})}
            renderLabel={formatMessage('Text Size')}
            value={settings.textSize}
          >
            {TEXT_SIZES.map(size => (
              <SimpleSelect.Option id={`text-size-${size}`} key={`text-size-${size}`} value={size}>
                {TEXT_SIZE_DESCRIPTION[size] || ''}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
        </Flex.Item>

        <Flex.Item padding="small">
          <ColorInput
            color={settings.textColor}
            label={formatMessage('Text Color')}
            name="icon-text-color"
            onChange={textColor => onChange({textColor})}
            popoverMountNode={getTextSection}
            requireColor={true}
          />
        </Flex.Item>

        <Flex.Item padding="small">
          <ColorInput
            color={settings.textBackgroundColor}
            label={formatMessage('Text Background Color')}
            name="icon-text-background-color"
            onChange={textBackgroundColor => onChange({textBackgroundColor})}
            popoverMountNode={getTextSection}
          />
        </Flex.Item>

        <Flex.Item padding="small">
          <SimpleSelect
            mountNode={getTextSection}
            assistiveText={formatMessage('Use arrow keys to select a text position.')}
            id="icon-text-position"
            onChange={(e, option) => onChange({textPosition: option.value})}
            renderLabel={formatMessage('Text Position')}
            value={settings.textPosition}
          >
            {TEXT_POSITIONS.map(position => (
              <SimpleSelect.Option
                id={`text-position-${position}`}
                key={`text-position-${position}`}
                value={position}
              >
                {TEXT_POSITION_DESCRIPTION[position] || ''}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
        </Flex.Item>
      </Flex>
    </Group>
  )
}

const TEXT_SIZE_DESCRIPTION = {
  small: formatMessage('Small'),
  medium: formatMessage('Medium'),
  large: formatMessage('Large'),
  'x-large': formatMessage('Extra Large'),
}

const TEXT_POSITION_DESCRIPTION = {
  middle: formatMessage('Middle'),
  'bottom-third': formatMessage('Bottom Third'),
  below: formatMessage('Below'),
}
