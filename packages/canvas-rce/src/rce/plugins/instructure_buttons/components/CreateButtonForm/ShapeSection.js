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

import formatMessage from '../../../../../format-message'

const SHAPES = ['square', 'circle', 'triangle', 'hexagon', 'octagon', 'star']
const SIZES = ['x-small', 'small', 'medium', 'large']

export const ShapeSection = ({settings, onChange}) => (
  <Flex as="section" direction="column" justifyItems="space-between" padding="small small 0">
    <Flex.Item padding="small">
      <SimpleSelect
        assistiveText={formatMessage('Use arrow keys to select a shape.')}
        id="button-shape"
        onChange={(e, option) => onChange({shape: option.value})}
        renderLabel={formatMessage('Button Shape')}
        value={settings.shape}
      >
        {SHAPES.map(shape => (
          <SimpleSelect.Option id={`shape-${shape}`} key={`shape-${shape}`} value={shape}>
            {SHAPE_DESCRIPTION[shape] || ''}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    </Flex.Item>

    <Flex.Item padding="small">
      <SimpleSelect
        assistiveText={formatMessage('Use arrow keys to select a size.')}
        id="button-size"
        onChange={(e, option) => onChange({size: option.value})}
        renderLabel={formatMessage('Button Size')}
        value={settings.size}
      >
        {SIZES.map(size => (
          <SimpleSelect.Option id={`size-${size}`} key={`size-${size}`} value={size}>
            {SIZE_DESCRIPTION[size] || ''}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    </Flex.Item>
  </Flex>
)

const SHAPE_DESCRIPTION = {
  square: formatMessage('Square'),
  circle: formatMessage('Circle'),
  triangle: formatMessage('Triangle'),
  hexagon: formatMessage('Hexagon'),
  octagon: formatMessage('Octagon'),
  star: formatMessage('Star')
}

const SIZE_DESCRIPTION = {
  'x-small': formatMessage('Extra Small'),
  small: formatMessage('Small'),
  medium: formatMessage('Medium'),
  large: formatMessage('Large')
}
