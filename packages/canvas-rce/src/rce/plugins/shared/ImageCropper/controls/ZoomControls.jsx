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
import {View} from '@instructure/ui-view'
import {calculateScaleRatio, calculateScalePercentage} from './utils'
import round from '../../round'
import {MAX_SCALE_RATIO, MIN_SCALE_RATIO, BUTTON_SCALE_STEP} from '../constants'
import formatMessage from '../../../../../format-message'
import PropTypes from 'prop-types'
import {CustomNumberInput} from './CustomNumberInput'
import {showFlashAlert} from '../../../../../common/FlashAlert'
import {debounce} from '@instructure/debounce'

const parseZoomText = value => {
  // Matches a positive/negative integer/decimal followed by %" symbol
  const matches = value.match(/([-|+]?\d+(?:\.\d+)?)%?/)
  if (!matches) {
    return null
  }
  const result = parseInt(matches[1], 10)
  if (Number.isNaN(result)) {
    return null
  }
  return result
}

const formatZoomText = value => `${value}%`

const debouncedAlert = debounce(showFlashAlert, 1000)

export const ZoomControls = ({scaleRatio, onChange}) => {
  const onZoomChange = value => {
    const message = {
      message: `${round(value * 100)}% Zoom`,
      type: 'info',
      srOnly: true,
    }
    debouncedAlert(message)
    onChange(value)
  }

  const zoomOutCallback = () => {
    const newScaleRatio = calculateScaleRatio(scaleRatio - BUTTON_SCALE_STEP)
    onZoomChange(newScaleRatio)
  }

  const zoomInCallback = () => {
    const newScaleRatio = calculateScaleRatio(scaleRatio + BUTTON_SCALE_STEP)
    onZoomChange(newScaleRatio)
  }

  return (
    <Flex.Item title={formatMessage('Zoom')} role="toolbar" tabindex={-1}>
      <View display="inline-block" margin="0 small 0 0">
        <CustomNumberInput
          value={round(scaleRatio * 100)}
          parseValueCallback={parseZoomText}
          formatValueCallback={formatZoomText}
          processValueCallback={calculateScalePercentage}
          placeholder={formatMessage('Zoom')}
          onChange={value => onZoomChange(round(value / 100))}
        />
      </View>
      <IconButton
        margin="0 small 0 0"
        onClick={zoomOutCallback}
        interaction={scaleRatio > MIN_SCALE_RATIO ? 'enabled' : 'disabled'}
        screenReaderLabel={formatMessage('Zoom out image')}
      >
        <IconZoomOutLine />
      </IconButton>
      <IconButton
        data-testid="zoom-in-button"
        onClick={zoomInCallback}
        interaction={scaleRatio < MAX_SCALE_RATIO ? 'enabled' : 'disabled'}
        screenReaderLabel={formatMessage('Zoom in image')}
      >
        <IconZoomInLine />
      </IconButton>
    </Flex.Item>
  )
}

ZoomControls.propTypes = {
  scaleRatio: PropTypes.number,
  onChange: PropTypes.func,
}

ZoomControls.defaultProps = {
  scaleRatio: MIN_SCALE_RATIO,
  onChange: () => {},
}
