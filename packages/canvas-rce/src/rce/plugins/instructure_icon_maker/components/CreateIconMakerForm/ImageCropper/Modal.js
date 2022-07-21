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
import React, {useEffect, useReducer} from 'react'
import PropTypes from 'prop-types'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import formatMessage from '../../../../../../format-message'
import {cropperSettingsReducer, actions, defaultState} from '../../../reducers/imageCropper'
import {Preview} from './Preview'
import {Controls} from './controls'
import {convertFileToBase64} from '../../../svg/utils'
import {createCroppedImageSvg} from './imageCropUtils'
import {ImageCropperSettingsPropTypes} from './propTypes'

const handleSubmit = (onSubmit, settings) =>
  createCroppedImageSvg(settings)
    .then(generatedSvg =>
      convertFileToBase64(new Blob([generatedSvg.outerHTML], {type: 'image/svg+xml'}))
    )
    .then(base64Image => onSubmit(settings, base64Image))

export const ImageCropperModal = ({open, onClose, onSubmit, image, cropSettings}) => {
  const [settings, dispatch] = useReducer(cropperSettingsReducer, defaultState)
  useEffect(() => {
    dispatch({type: actions.SET_IMAGE, payload: image})
  }, [image])

  useEffect(() => {
    cropSettings && dispatch({type: actions.UPDATE_SETTINGS, payload: cropSettings})
  }, [cropSettings])

  return (
    <Modal size="large" open={open} onDismiss={onClose} shouldCloseOnDocumentClick={false}>
      <Modal.Header id="imageCropperHeader">
        <CloseButton placement="end" offset="small" onClick={onClose} screenReaderLabel="Close" />
        <Heading>{formatMessage('Crop Image')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" margin="none">
          <Flex.Item margin="0 0 small 0">
            <Controls settings={settings} dispatch={dispatch} />
          </Flex.Item>
          <Flex.Item>
            <Preview settings={settings} dispatch={dispatch} />
          </Flex.Item>
        </Flex>
      </Modal.Body>
      <Modal.Footer id="imageCropperFooter">
        <Button onClick={onClose} margin="0 x-small 0 0">
          {formatMessage('Cancel')}
        </Button>
        <Button
          color="primary"
          type="submit"
          onClick={e => {
            e.preventDefault()
            handleSubmit(onSubmit, settings).then(onClose).catch(onClose)
          }}
        >
          {formatMessage('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

ImageCropperModal.propTypes = {
  image: PropTypes.string.isRequired,
  cropSettings: ImageCropperSettingsPropTypes,
  open: PropTypes.bool,
  onClose: PropTypes.func,
  onSubmit: PropTypes.func
}

ImageCropperModal.defaultProps = {
  open: false,
  cropSettings: null,
  onClose: () => {},
  onSubmit: () => {}
}
