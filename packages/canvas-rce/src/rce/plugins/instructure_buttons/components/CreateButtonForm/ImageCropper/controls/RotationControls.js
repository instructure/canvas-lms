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
import {IconButton} from '@instructure/ui-buttons'
import {IconRotateLeftLine, IconRotateRightLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {CustomNumberInput} from './CustomNumberInput'
import {calculateRotation, getNearestRectAngle} from './utils'
import {BUTTON_ROTATION_DEGREES} from '../constants'
import formatMessage from '../../../../../../../format-message'

const parseRotationText = value => {
  // Matches a positive/negative integer/decimal followed by "º" symbol
  const matches = value.match(/([-|+]?\d+(?:\.\d+)?)º?/)
  if (!matches) {
    return null
  }
  const result = parseInt(matches[1], 10)
  if (Number.isNaN(result)) {
    return null
  }
  return result
}

const formatRotationText = value => `${value}º`

export const RotationControls = ({rotation, onChange}) => {
  const rotateLeftCallback = () =>
    onChange(calculateRotation(getNearestRectAngle(rotation, true) - BUTTON_ROTATION_DEGREES))
  const rotateRightCallback = () =>
    onChange(calculateRotation(getNearestRectAngle(rotation, false) + BUTTON_ROTATION_DEGREES))

  return (
    <>
      <Flex.Item margin="0 small 0 0">
        <CustomNumberInput
          value={rotation}
          parseValueCallback={parseRotationText}
          formatValueCallback={formatRotationText}
          processValueCallback={calculateRotation}
          placeholder={formatMessage('Rotation')}
          onChange={value => onChange(value)}
        />
      </Flex.Item>
      <Flex.Item margin="0 small 0 0">
        <IconButton
          onClick={rotateLeftCallback}
          screenReaderLabel={formatMessage('Rotate image -90 degrees')}
        >
          <IconRotateLeftLine />
        </IconButton>
      </Flex.Item>
      <Flex.Item margin="0 medium 0 0">
        <IconButton
          onClick={rotateRightCallback}
          screenReaderLabel={formatMessage('Rotate image 90 degrees')}
        >
          <IconRotateRightLine />
        </IconButton>
      </Flex.Item>
    </>
  )
}

RotationControls.propTypes = {
  rotation: PropTypes.number,
  onChange: PropTypes.func
}

RotationControls.defaultProps = {
  rotation: 0,
  onChange: () => {}
}
