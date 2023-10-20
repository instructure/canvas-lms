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
import formatMessage from '../../../../../../format-message'
import {actions} from '../../../reducers/imageSection'
import {actions as svgActions} from '../../../reducers/svgSettings'
import {UploadFile} from '../../../../shared/Upload/UploadFile'
import {
  canCompressImage,
  compressImage,
  shouldCompressImage,
} from '../../../../shared/compressionUtils'
import {isAnUnsupportedGifPngImage, MAX_GIF_PNG_SIZE_BYTES} from './utils'
import {PREVIEW_HEIGHT, PREVIEW_WIDTH} from '../../../../shared/ImageCropper/constants'

function dispatchCompressedImage(theFile, dispatch, onChange) {
  dispatch({...actions.SET_IMAGE, payload: ''})
  onChange({type: svgActions.SET_EMBED_IMAGE, payload: ''})
  dispatch({...actions.SET_CROPPER_OPEN, payload: true})
  dispatch({...actions.SET_IMAGE_COLLECTION_OPEN, payload: false})
  return compressImage({
    encodedImage: theFile.preview,
    previewWidth: PREVIEW_WIDTH,
    previewHeight: PREVIEW_HEIGHT,
  })
    .then(blob => {
      dispatch({...actions.SET_COMPRESSION_STATUS, payload: true})
      dispatch({...actions.SET_IMAGE, payload: blob})
      onChange({type: svgActions.SET_EMBED_IMAGE, payload: blob})
      dispatch({...actions.SET_IMAGE_NAME, payload: theFile.name})
    })
    .catch(() => {
      // If compression fails, use the original one
      // TODO: We can show the user that compression failed in some way
      dispatch({...actions.SET_IMAGE, payload: theFile.preview})
      onChange({type: svgActions.SET_EMBED_IMAGE, payload: theFile.preview})
      dispatch({...actions.SET_IMAGE_NAME, payload: theFile.name})
    })
}

export const onSubmit = (dispatch, onChange) => (_editor, _accept, _selectedPanel, uploadData) => {
  const {theFile} = uploadData

  if (isAnUnsupportedGifPngImage(theFile)) {
    dispatch({...actions.SET_IMAGE_COLLECTION_OPEN, payload: false})
    return onChange({
      type: svgActions.SET_ERROR,
      payload: formatMessage(
        'GIF/PNG format images larger than {size} KB are not currently supported.',
        {size: MAX_GIF_PNG_SIZE_BYTES / 1024}
      ),
    })
  }

  if (canCompressImage() && shouldCompressImage(theFile)) {
    return dispatchCompressedImage(theFile, dispatch, onChange)
  }

  dispatch({...actions.SET_IMAGE, payload: theFile.preview})
  onChange({type: svgActions.SET_EMBED_IMAGE, payload: theFile.preview})
  dispatch({...actions.SET_IMAGE_NAME, payload: theFile.name})
  dispatch({...actions.SET_IMAGE_COLLECTION_OPEN, payload: false})
  dispatch({...actions.SET_CROPPER_OPEN, payload: true})
}

const Upload = ({editor, dispatch, mountNode, onChange, canvasOrigin}) => {
  return (
    <UploadFile
      accept="image/*"
      editor={editor}
      label={formatMessage('Upload Image')}
      mountNode={mountNode}
      panels={['COMPUTER']}
      onDismiss={() => {
        dispatch(actions.CLEAR_MODE)
      }}
      requireA11yAttributes={false}
      onSubmit={onSubmit(dispatch, onChange)}
      canvasOrigin={canvasOrigin}
    />
  )
}

Upload.propTypes = {
  editor: PropTypes.object.isRequired,
  dispatch: PropTypes.func,
  onChange: PropTypes.func,
  mountNode: PropTypes.oneOfType([PropTypes.element, PropTypes.func]),
  canvasOrigin: PropTypes.string.isRequired,
}

Upload.defaultProps = {
  dispatch: () => {},
  onChange: () => {},
}

export default Upload
