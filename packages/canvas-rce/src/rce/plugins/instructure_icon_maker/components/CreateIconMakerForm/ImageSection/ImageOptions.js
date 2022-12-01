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

import React, {useState, useCallback} from 'react'
import formatMessage from '../../../../../../format-message'
import {actions, modes} from '../../../reducers/imageSection'
import {actions as trayActions} from '../../../reducers/svgSettings'
import {IconButton} from '@instructure/ui-buttons'
import {IconCropLine, IconTrashLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import PreviewIcon from '../../../../shared/PreviewIcon'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'
import {ImageCropperModal} from '../ImageCropper'
import ModeSelect from './ModeSelect'
import PropTypes from 'prop-types'
import {ImageCropperSettingsPropTypes} from '../ImageCropper/propTypes'
import {MAX_IMAGE_SIZE_BYTES} from './compressionUtils'

const getCompressionMessage = () =>
  formatMessage(
    'Your image has been compressed for Icon Maker. Images less than {size} KB will not be compressed.',
    {
      size: MAX_IMAGE_SIZE_BYTES / 1024,
    }
  )

function renderImagePreview({image, loading}) {
  return (
    <PreviewIcon
      variant="large"
      testId="selected-image-preview"
      image={image}
      loading={loading}
      checkered={true}
    />
  )
}

function renderImageName({imageName}) {
  return (
    <View maxWidth="200px" as="div">
      <TruncateText>
        <Text>{imageName || formatMessage('None Selected')}</Text>
      </TruncateText>
    </View>
  )
}

function renderImageActionButtons({mode, collectionOpen}, dispatch, setFocus, ref) {
  const showCropButton =
    [modes.uploadImages.type, modes.courseImages.type].includes(mode) && !collectionOpen
  return (
    <>
      {showCropButton && (
        <IconButton
          margin="0 small 0 0"
          screenReaderLabel={formatMessage('Crop image')}
          onClick={() => dispatch({type: actions.SET_CROPPER_OPEN.type, payload: true})}
        >
          <IconCropLine />
        </IconButton>
      )}
      <IconButton
        ref={ref}
        screenReaderLabel={formatMessage('Clear image')}
        onClick={() => dispatch(actions.RESET_ALL)}
        onFocus={() => setFocus(true)}
        onBlur={() => setFocus(false)}
        data-testid="clear-image"
      >
        <IconTrashLine />
      </IconButton>
    </>
  )
}

export const ImageOptions = ({state, dispatch, rcsConfig, trayDispatch}) => {
  const [isImageActionFocused, setIsImageActionFocused] = useState(false)
  const imageActionRef = useCallback(
    el => {
      if (el && isImageActionFocused) el.focus()
    },
    [isImageActionFocused]
  )

  const {image} = state
  return (
    <Flex padding="small">
      <Flex.Item margin="0 small 0 0">{renderImagePreview(state)}</Flex.Item>
      <Flex.Item>{renderImageName(state)}</Flex.Item>
      <Flex.Item margin="0 0 0 auto">
        {image ? (
          renderImageActionButtons(state, dispatch, setIsImageActionFocused, imageActionRef)
        ) : (
          <ModeSelect
            dispatch={dispatch}
            ref={imageActionRef}
            onFocus={() => setIsImageActionFocused(true)}
            onBlur={() => setIsImageActionFocused(false)}
            rcsConfig={rcsConfig}
          />
        )}
        {state.cropperOpen && (
          <ImageCropperModal
            open={state.cropperOpen}
            onClose={() => dispatch({type: actions.SET_CROPPER_OPEN.type, payload: false})}
            onSubmit={(settings, generatedImage) => {
              trayDispatch({
                type: trayActions.SET_EMBED_IMAGE,
                payload: generatedImage,
              })
              dispatch({
                type: actions.SET_CROPPER_SETTINGS.type,
                payload: settings,
              })
            }}
            image={image}
            cropSettings={state.cropperSettings}
            message={state.compressed ? getCompressionMessage() : null}
            loading={!image}
            trayDispatch={trayDispatch}
          />
        )}
      </Flex.Item>
    </Flex>
  )
}

ImageOptions.propTypes = {
  state: PropTypes.shape({
    image: PropTypes.string.isRequired,
    imageName: PropTypes.string.isRequired,
    mode: PropTypes.string.isRequired,
    loading: PropTypes.bool.isRequired,
    cropperOpen: PropTypes.bool.isRequired,
    cropperSettings: ImageCropperSettingsPropTypes,
    compressed: PropTypes.bool.isRequired,
  }).isRequired,
  dispatch: PropTypes.func.isRequired,
  rcsConfig: PropTypes.object.isRequired,
  trayDispatch: PropTypes.func.isRequired,
}
