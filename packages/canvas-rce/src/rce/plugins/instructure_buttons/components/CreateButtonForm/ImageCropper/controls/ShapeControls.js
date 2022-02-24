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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import formatMessage from '../../../../../../../format-message'
import {SimpleSelect} from '@instructure/ui-simple-select'
import PropTypes from 'prop-types'
import {ZoomControls} from './ZoomControls'

const SHAPE_OPTIONS = [
  {id: 'square', label: formatMessage('Square')},
  {id: 'circle', label: formatMessage('Circle')},
  {id: 'triangle', label: formatMessage('Triangle')},
  {id: 'diamond', label: formatMessage('Diamond')},
  {id: 'pentagon', label: formatMessage('Pentagon')},
  {id: 'hexagon', label: formatMessage('Hexagon')},
  {id: 'octagon', label: formatMessage('Octagon')},
  {id: 'star', label: formatMessage('Star')}
]

export const ShapeControls = ({shape, onChange}) => {
  return (
    <Flex.Item margin="0 small 0 0">
      <SimpleSelect
        isInline
        assistiveText={formatMessage('Select crop shape')}
        value={shape}
        onChange={(event, {id}) => onChange(id)}
        renderLabel={null}
      >
        {SHAPE_OPTIONS.map(option => (
          <SimpleSelect.Option key={option.id} id={option.id} value={option.id}>
            {option.label}
          </SimpleSelect.Option>
        ))}
      </SimpleSelect>
    </Flex.Item>
  )
}

ShapeControls.propTypes = {
  shape: PropTypes.string,
  onChange: PropTypes.func
}

ZoomControls.defaultProps = {
  shape: 'square',
  onChange: () => {}
}
