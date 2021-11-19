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

import React, {useState} from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Flex} from '@instructure/ui-flex'
import ImageCropperPreview from './ImageCropperPreview'
import formatMessage from '../../../../../../format-message'

const SHAPE_OPTIONS = [
  {id: 'square', label: formatMessage('Square')},
  {id: 'circle', label: formatMessage('Circle')},
  {id: 'triangle', label: formatMessage('Triangle')},
  {id: 'hexagon', label: formatMessage('Hexagon')},
  {id: 'octagon', label: formatMessage('Octagon')},
  {id: 'star', label: formatMessage('Star')}
]

export const ImageCropper = () => {
  const [selectedShape, setSelectedShape] = useState('square')
  return (
    <Flex direction="column" margin="none">
      <Flex.Item margin="none none small">
        <SimpleSelect
          isInline
          assistiveText={formatMessage('Select crop shape')}
          value={selectedShape}
          onChange={(event, {id}) => setSelectedShape(id)}
        >
          {SHAPE_OPTIONS.map(option => (
            <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
              {option.label}
            </SimpleSelect.Option>
          ))}
        </SimpleSelect>
      </Flex.Item>
      <Flex.Item>
        <ImageCropperPreview shape={selectedShape} />
      </Flex.Item>
    </Flex>
  )
}
