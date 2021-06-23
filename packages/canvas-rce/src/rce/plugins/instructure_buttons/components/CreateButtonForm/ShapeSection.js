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
  <Flex as="section" justifyItems="space-between" direction="column">
    <Flex.Item padding="small">
      <SimpleSelect
        assistiveText={formatMessage('Use arrow keys to navigate options.')}
        id="button-shape"
        onChange={(e, option) => onChange({shape: option.value})}
        renderLabel={formatMessage('Button Shape')}
        value={settings.shape}
      >
        {SHAPES.map(shape => (
          <SimpleSelect.Option id={`shape-${shape}`} key={shape} value={shape}>
            {getShapeLabel(shape)}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    </Flex.Item>

    <Flex.Item padding="small">
      <SimpleSelect
        assistiveText={formatMessage('Use arrow keys to navigate options.')}
        id="button-size"
        onChange={(e, option) => onChange({size: option.value})}
        renderLabel={formatMessage('Button Size')}
        value={settings.size}
      >
        {SIZES.map(size => (
          <SimpleSelect.Option id={`size-${size}`} key={size} value={size}>
            {getSizeLabel(size)}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    </Flex.Item>
  </Flex>
)

function getShapeLabel(shape) {
  switch (shape) {
    case 'square':
      return formatMessage('Square')
    case 'circle':
      return formatMessage('Circle')
    case 'triangle':
      return formatMessage('Triangle')
    case 'hexagon':
      return formatMessage('Hexagon')
    case 'octagon':
      return formatMessage('Octagon')
    case 'star':
      return formatMessage('Star')
    default:
      return ''
  }
}

function getSizeLabel(size) {
  switch (size) {
    case 'x-small':
      return formatMessage('Extra Small')
    case 'small':
      return formatMessage('Small')
    case 'medium':
      return formatMessage('Medium')
    case 'large':
      return formatMessage('Large')
    default:
      return ''
  }
}
