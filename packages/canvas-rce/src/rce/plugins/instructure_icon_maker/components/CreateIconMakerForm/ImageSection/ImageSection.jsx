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

import React, {useReducer, useEffect, useRef, Suspense} from 'react'
import _ from 'lodash'
import PropTypes from 'prop-types'

import formatMessage from '../../../../../../format-message'
import reducer, {actions, initialState, modes} from '../../../reducers/imageSection'
import {actions as svgActions} from '../../../reducers/svgSettings'

import {Flex} from '@instructure/ui-flex'
import {Group} from '../Group'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'

import Course from './Course'
import {ImageOptions} from './ImageOptions'
import {ColorInput} from '../../../../shared/ColorInput'
import {convertFileToBase64} from '../../../../shared/fileUtils'
import {transformForShape} from '../../../svg/image'
import SingleColorSVG from './SingleColor/svg'
import {createCroppedImageSvg} from '../../../../shared/ImageCropper/imageCropUtils'

const IMAGE_SECTION_ID = 'icon-maker-tray-image-section'
const getImageSection = () => document.querySelector(`#${IMAGE_SECTION_ID}`)

const scrollToBottom = () => {
  const section = getImageSection()
  if (section?.scrollIntoView) {
    section.scrollIntoView({behavior: 'smooth'})
  }
}

const filterSectionStateMetadata = state => {
  const {mode, image, imageName, icon, iconFillColor, cropperSettings} = state
  return {mode, image, imageName, icon, iconFillColor, cropperSettings}
}

export const ImageSection = ({settings, onChange, editor, canvasOrigin}) => {
  const [state, dispatch] = useReducer(reducer, initialState)
  const Upload = React.lazy(() => import('./Upload'))
  const SingleColor = React.lazy(() => import('./SingleColor'))
  const MultiColor = React.lazy(() => import('./MultiColor'))

  // This object maps image selection modes to the
  // component that handles that selection.
  //
  // The selected component is dynamically rendered
  // in this component's returned JSX
  const allowedModes = {
    [modes.courseImages.type]: Course,
    [modes.uploadImages.type]: Upload,
    [modes.singleColorImages.type]: SingleColor,
    [modes.multiColorImages.type]: MultiColor,
  }

  const metadata = filterSectionStateMetadata(state)

  const isMetadataLoaded = useRef(false)

  useEffect(() => {
    const transform = transformForShape(settings.shape, settings.size)

    // Set Q1 crop defaults
    // TODO: Set these properties based on cropper
    onChange({
      type: svgActions.SET_X,
      payload: transform.x,
    })

    onChange({
      type: svgActions.SET_Y,
      payload: transform.y,
    })

    onChange({
      type: svgActions.SET_WIDTH,
      payload: transform.width,
    })

    onChange({
      type: svgActions.SET_HEIGHT,
      payload: transform.height,
    })

    onChange({
      type: svgActions.SET_TRANSLATE_X,
      payload: transform.translateX,
    })

    onChange({
      type: svgActions.SET_TRANSLATE_Y,
      payload: transform.translateY,
    })
  }, [onChange, settings.shape, settings.size])

  useEffect(() => {
    if (state.icon && state.icon in SingleColorSVG) {
      dispatch({...actions.START_LOADING})
      // eslint-disable-next-line promise/catch-or-return
      convertFileToBase64(
        new Blob([SingleColorSVG[state.icon].source(state.iconFillColor)], {
          type: 'image/svg+xml',
        })
      ).then(base64Image => {
        dispatch({...actions.SET_IMAGE, payload: base64Image})
        dispatch({...actions.STOP_LOADING})
        onChange({type: svgActions.SET_EMBED_IMAGE, payload: base64Image})
      })
    }
  }, [onChange, state.icon, state.iconFillColor])

  // After a new shape is selected in shape section a new embedded image should be generated
  useEffect(() => {
    if (state.cropperSettings && settings.shape !== state.cropperSettings.shape) {
      const newCropperSettings = {...state.cropperSettings, shape: settings.shape}
      dispatch({
        type: actions.SET_CROPPER_SETTINGS.type,
        payload: newCropperSettings,
      })
      createCroppedImageSvg(newCropperSettings, settings.imageSettings.image)
        .then(generatedSvg =>
          convertFileToBase64(new Blob([generatedSvg.outerHTML], {type: 'image/svg+xml'}))
        )
        .then(base64Image => {
          onChange({
            type: svgActions.SET_EMBED_IMAGE,
            payload: base64Image,
          })
        })
        // eslint-disable-next-line no-console
        .catch(error => console.error(error))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [settings.shape])

  useEffect(() => {
    if (
      settings.imageSettings &&
      !isMetadataLoaded.current &&
      !_.isEqual(settings.imageSettings, metadata)
    ) {
      isMetadataLoaded.current = true
      dispatch({
        type: actions.UPDATE_SETTINGS.type,
        payload: settings.imageSettings,
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [settings.imageSettings])

  useEffect(() => {
    if (!_.isEqual(metadata, settings.imageSettings)) {
      onChange({
        type: svgActions.SET_IMAGE_SETTINGS,
        payload: metadata,
      })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, Object.values(metadata))

  const modeIsAllowed = !!allowedModes[state.mode]
  const ImageSelector = allowedModes[state.mode]

  return (
    <Group as="section" defaultExpanded={true} summary={formatMessage('Image')}>
      <Flex as="section" justifyItems="space-between" direction="column" id={IMAGE_SECTION_ID}>
        <Flex.Item>
          <Flex direction="column">
            <Flex.Item padding="small 0 0 small">
              <Text weight="bold">{formatMessage('Current Image')}</Text>
            </Flex.Item>
            <Flex.Item>
              <ImageOptions
                state={state}
                settings={settings}
                dispatch={dispatch}
                mountNode={getImageSection}
                trayDispatch={onChange}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Suspense
          fallback={
            <Flex justifyItems="center">
              <Flex.Item>
                <Spinner renderTitle={formatMessage('Loading')} />
              </Flex.Item>
            </Flex>
          }
        >
          {modeIsAllowed && state.collectionOpen && (
            <Flex.Item padding="small">
              <ImageSelector
                dispatch={dispatch}
                editor={editor}
                data={state}
                onChange={onChange}
                onLoading={scrollToBottom}
                onLoaded={scrollToBottom}
                canvasOrigin={canvasOrigin}
              />
            </Flex.Item>
          )}
        </Suspense>
        {state.icon && state.mode === modes.singleColorImages.type && (
          <Flex.Item padding="small">
            <ColorInput
              color={state.iconFillColor}
              label={formatMessage('Single Color Image Color')}
              name="single-color-image-fill"
              onChange={color => dispatch({type: actions.SET_ICON_FILL_COLOR.type, payload: color})}
              popoverMountNode={getImageSection}
              requireColor={true}
            />
          </Flex.Item>
        )}
      </Flex>
    </Group>
  )
}

ImageSection.propTypes = {
  settings: PropTypes.object.isRequired,
  editor: PropTypes.object.isRequired,
  onChange: PropTypes.func,
  canvasOrigin: PropTypes.string,
}

ImageSection.defaultProps = {
  onChange: () => {},
}
