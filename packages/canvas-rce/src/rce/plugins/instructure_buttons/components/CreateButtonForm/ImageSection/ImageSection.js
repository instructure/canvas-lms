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

import React, {useReducer, useEffect, Suspense} from 'react'

import formatMessage from '../../../../../../format-message'
import reducer, {actions, initialState, modes} from '../../../reducers/imageSection'
import {actions as svgActions} from '../../../reducers/svgSettings'

import {Flex} from '@instructure/ui-flex'
import {Group} from '../Group'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'

import Course from './Course'
import {ImageOptions} from './ImageOptions'

export const ImageSection = ({settings, onChange, editing, editor}) => {
  const [state, dispatch] = useReducer(reducer, initialState)

  const Upload = React.lazy(() => import('./Upload'))
  const MultiColor = React.lazy(() => import('./MultiColor'))

  // This object maps image selection modes to the
  // component that handles that selection.
  //
  // The selected component is dynamically rendered
  // in this component's returned JSX
  const allowedModes = {
    [modes.courseImages.type]: Course,
    [modes.uploadImages.type]: Upload,
    [modes.multiColorImages.type]: MultiColor
  }

  useEffect(() => {
    if (editing) {
      dispatch({
        type: actions.SET_IMAGE.type,
        payload: settings.encodedImage
      })
    }
  }, [settings.encodedImage])

  useEffect(() => {
    if (editing) {
      dispatch({
        type: actions.SET_IMAGE_NAME.type,
        payload: settings.encodedImageName
      })
    }
  }, [settings.encodedImageName])

  useEffect(() => {
    onChange({
      type: svgActions.SET_ENCODED_IMAGE,
      payload: state.image
    })
  }, [state.image])

  useEffect(() => {
    onChange({
      type: svgActions.SET_ENCODED_IMAGE_TYPE,
      payload: state.mode
    })
  }, [state.mode])

  useEffect(() => {
    onChange({
      type: svgActions.SET_ENCODED_IMAGE_NAME,
      payload: state.imageName
    })
  }, [state.imageName])

  return (
    <Group as="section" defaultExpanded summary={formatMessage('Image')}>
      <Flex
        as="section"
        justifyItems="space-between"
        direction="column"
        id="buttons-tray-text-section"
      >
        <Flex.Item>
          <Flex direction="column">
            <Flex.Item padding="small 0 0 small">
              <Text weight="bold">{formatMessage('Current Image')}</Text>
            </Flex.Item>
            <Flex.Item>
              <ImageOptions state={state} dispatch={dispatch} />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item padding="small">
          <Suspense
            fallback={
              <Flex justifyItems="center">
                <Flex.Item>
                  <Spinner renderTitle={formatMessage('Loading')} />
                </Flex.Item>
              </Flex>
            }
          >
            {!!allowedModes[state.mode] &&
              React.createElement(allowedModes[state.mode], {dispatch, editor})}
          </Suspense>
        </Flex.Item>
      </Flex>
    </Group>
  )
}
