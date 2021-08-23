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
import {SimpleSelect} from '@instructure/ui-simple-select'

import {ColorInput} from '../../../shared/ColorInput'
import formatMessage from '../../../../../format-message'

const OUTLINE_SIZES = ['none', 'small', 'medium', 'large']

const getColorSection = () => document.querySelector('#buttons-tray-color-section')

export const ColorSection = ({settings, onChange}) => (
  <Flex
    as="section"
    direction="column"
    id="buttons-tray-color-section"
    justifyItems="space-between"
    padding="0 small"
  >
    <Flex.Item padding="small">
      <ColorInput
        color={settings.color}
        label={formatMessage('Button Color')}
        name="button-color"
        onChange={color => onChange({color})}
        popoverMountNode={getColorSection}
      />
    </Flex.Item>

    <Flex.Item padding="small">
      <ColorInput
        color={settings.outlineColor}
        label={formatMessage('Button Outline')}
        name="button-outline"
        onChange={outlineColor => onChange({outlineColor})}
        popoverMountNode={getColorSection}
      />
    </Flex.Item>

    <Flex.Item padding="small">
      <SimpleSelect
        assistiveText={formatMessage('Use arrow keys to select an outline size.')}
        id="button-outline-size"
        onChange={(e, option) => onChange({outlineSize: option.value})}
        renderLabel={formatMessage('Button Outline Size')}
        value={settings.outlineSize}
      >
        {OUTLINE_SIZES.map(size => (
          <SimpleSelect.Option
            id={`outline-size-${size}`}
            key={`outline-size-${size}`}
            value={size}
          >
            {OUTLINE_SIZE_DESCRIPTION[size] || ''}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    </Flex.Item>
  </Flex>
)

const OUTLINE_SIZE_DESCRIPTION = {
  none: formatMessage('None'),
  small: formatMessage('Small'),
  medium: formatMessage('Medium'),
  large: formatMessage('Large')
}
