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
import {IconButton} from '@instructure/ui-buttons'
import {IconZoomInLine, IconZoomOutLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {calculateScaleRatio} from './utils'
import {MAX_SCALE_RATIO, MIN_SCALE_RATIO, BUTTON_SCALE_STEP} from '../constants'
import formatMessage from '../../../../../../../format-message'
import PropTypes from 'prop-types'

export const ZoomControls = ({scaleRatio, onChange}) => {
  const zoomOutCallback = () => {
    const newScaleRatio = calculateScaleRatio(scaleRatio - BUTTON_SCALE_STEP)
    onChange(newScaleRatio)
  }

  const zoomInCallback = () => {
    const newScaleRatio = calculateScaleRatio(scaleRatio + BUTTON_SCALE_STEP)
    onChange(newScaleRatio)
  }

  return (
    <>
      <Flex.Item margin="0 small 0 0">
        <IconButton
          onClick={zoomOutCallback}
          interaction={scaleRatio > MIN_SCALE_RATIO ? 'enabled' : 'disabled'}
          screenReaderLabel={formatMessage('Zoom out image')}
        >
          <IconZoomOutLine />
        </IconButton>
      </Flex.Item>
      <Flex.Item>
        <IconButton
          onClick={zoomInCallback}
          interaction={scaleRatio < MAX_SCALE_RATIO ? 'enabled' : 'disabled'}
          screenReaderLabel={formatMessage('Zoom in image')}
        >
          <IconZoomInLine />
        </IconButton>
      </Flex.Item>
    </>
  )
}

ZoomControls.propTypes = {
  scaleRatio: PropTypes.number,
  onChange: PropTypes.func
}

ZoomControls.defaultProps = {
  scaleRatio: MIN_SCALE_RATIO,
  onChange: () => {}
}
