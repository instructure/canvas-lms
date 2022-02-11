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

import React, {useState} from 'react'
import formatMessage from '../../../../../../format-message'
import {actions, modes} from '../../../reducers/imageSection'

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

function renderImagePreview({image, loading}) {
  return (
    <PreviewIcon variant="large" testId="selected-image-preview" image={image} loading={loading} />
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

function renderImageActionButtons({mode}, setOpenCropModal, dispatch) {
  return (
    <>
      {mode === modes.courseImages.type && (
        <IconButton
          margin="0 small 0 0"
          screenReaderLabel={formatMessage('Crop image')}
          onClick={() => {
            setOpenCropModal(true)
          }}
        >
          <IconCropLine />
        </IconButton>
      )}
      <IconButton
        screenReaderLabel={formatMessage('Clear image')}
        onClick={() => {
          dispatch({type: actions.CLEAR_IMAGE.type})
          dispatch({type: actions.CLEAR_MODE.type})
        }}
      >
        <IconTrashLine />
      </IconButton>
    </>
  )
}

export const ImageOptions = ({state, dispatch}) => {
  const {image} = state
  const [openCropModal, setOpenCropModal] = useState(false)
  return (
    <Flex padding="small">
      <Flex.Item margin="0 small 0 0">{renderImagePreview(state)}</Flex.Item>
      <Flex.Item>{renderImageName(state)}</Flex.Item>
      <Flex.Item margin="0 0 0 auto">
        {image ? (
          renderImageActionButtons(state, setOpenCropModal, dispatch)
        ) : (
          <ModeSelect dispatch={dispatch} />
        )}
        {openCropModal && (
          <ImageCropperModal
            open={openCropModal}
            onClose={() => setOpenCropModal(false)}
            image={image}
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
    loading: PropTypes.bool.isRequired
  }).isRequired,
  dispatch: PropTypes.func.isRequired
}
