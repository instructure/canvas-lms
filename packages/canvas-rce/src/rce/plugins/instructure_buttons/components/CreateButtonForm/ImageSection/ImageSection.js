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

import React, {useReducer} from 'react'

import formatMessage from '../../../../../../format-message'
import reducer, {initialState, modes} from '../../../reducers/imageSection'

import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Group} from '../Group'
import ModeSelect from './ModeSelect'
import Course from './Course'
import PreviewIcon from '../../../../shared/PreviewIcon'

export const ImageSection = ({editor}) => {
  const [state, dispatch] = useReducer(reducer, initialState)
  const allowedModes = {[modes.courseImages.type]: Course}

  return (
    <Group as="section" defaultExpanded summary={formatMessage('Image')}>
      <Flex direction="column" margin="small">
        <Flex.Item>
          <Text weight="bold">{formatMessage('Current Image')}</Text>
        </Flex.Item>
        <Flex.Item>
          <Flex>
            <Flex.Item shouldGrow>
              <Flex>
                <Flex.Item margin="0 small 0 0">
                  <PreviewIcon variant="large" testId="selected-image-preview" />
                </Flex.Item>
                <Flex.Item>
                  <Text>{!state.currentImage && formatMessage('None Selected')}</Text>
                </Flex.Item>
              </Flex>
            </Flex.Item>
            <Flex.Item>
              <ModeSelect dispatch={dispatch} />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          {!!allowedModes[state.mode] && React.createElement(allowedModes[state.mode])}
        </Flex.Item>
      </Flex>
    </Group>
  )
}
