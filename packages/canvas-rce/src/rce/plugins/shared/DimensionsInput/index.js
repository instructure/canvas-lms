/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {bool, func, number, shape, string} from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {IconLockLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-layout'

import formatMessage from '../../../../format-message'
import DimensionInput from './DimensionInput'

export {default as useDimensionsState} from './useDimensionsState'

export default function DimensionsInput(props) {
  const {dimensionsState, minHeight, minWidth} = props

  let messages = [{text: formatMessage('Aspect ratio will be preserved'), type: 'hint'}]

  if (!dimensionsState.isNumeric) {
    messages = [
      {
        text: formatMessage('Width and height must be numbers'),
        type: 'error'
      }
    ]
  } else if (!dimensionsState.isAtLeastMinimums) {
    messages = [
      {
        text: formatMessage('Must be at least {width} x {height}px', {
          width: minWidth,
          height: minHeight
        }),
        type: 'error'
      }
    ]
  }

  return (
    <FormFieldGroup
      description={<ScreenReaderContent>{formatMessage('Dimensions')}</ScreenReaderContent>}
      messages={messages}
    >
      <Flex alignItems="start" direction="row">
        <Flex.Item shrink>
          <DimensionInput
            dimensionState={dimensionsState.widthState}
            label={formatMessage('Width')}
            minValue={minWidth}
          />
        </Flex.Item>

        <Flex.Item padding="x-small small">
          <IconLockLine />
        </Flex.Item>

        <Flex.Item shrink>
          <DimensionInput
            dimensionState={dimensionsState.heightState}
            label={formatMessage('Height')}
            minValue={minHeight}
          />
        </Flex.Item>
      </Flex>
    </FormFieldGroup>
  )
}

DimensionsInput.propTypes = {
  dimensionsState: shape({
    heightState: shape({
      addOffset: func.isRequired,
      inputValue: string.isRequired,
      setInputValue: func.isRequired
    }).isRequired,
    isNumeric: bool.isRequired,
    widthState: shape({
      addOffset: func.isRequired,
      inputValue: string.isRequired,
      setInputValue: func.isRequired
    }).isRequired
  }),
  minHeight: number.isRequired,
  minWidth: number.isRequired
}
