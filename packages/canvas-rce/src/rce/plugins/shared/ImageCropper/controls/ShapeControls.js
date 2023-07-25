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
import PropTypes from 'prop-types'
import {Flex} from '@instructure/ui-flex'
import formatMessage from '../../../../../format-message'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ZoomControls} from './ZoomControls'
import {Shape} from '../shape'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const SHAPE_OPTIONS = [
  {id: Shape.Square, label: formatMessage('Square')},
  {id: Shape.Circle, label: formatMessage('Circle')},
  {id: Shape.Triangle, label: formatMessage('Triangle')},
  {id: Shape.Diamond, label: formatMessage('Diamond')},
  {id: Shape.Pentagon, label: formatMessage('Pentagon')},
  {id: Shape.Hexagon, label: formatMessage('Hexagon')},
  {id: Shape.Octagon, label: formatMessage('Octagon')},
  {id: Shape.Star, label: formatMessage('Star')},
]

export const ShapeControls = ({shape, onChange}) => {
  return (
    <Flex.Item margin="0 medium 0 0">
      <SimpleSelect
        isInline={true}
        value={shape}
        onChange={(event, {id}) => onChange(id)}
        renderLabel={
          <ScreenReaderContent>{formatMessage('Select crop shape')}</ScreenReaderContent>
        }
        data-testid="shape-select-dropdown"
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
  onChange: PropTypes.func,
}

ZoomControls.defaultProps = {
  shape: 'square',
  onChange: () => {},
}
