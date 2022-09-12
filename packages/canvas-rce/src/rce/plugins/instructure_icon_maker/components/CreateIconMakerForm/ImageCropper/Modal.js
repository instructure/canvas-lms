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
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
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

const renderBody = (settings, dispatch, message, loading) => {
  if (loading) {
    return (
      <Flex justifyItems="center" margin="">
        <Flex.Item>
          <Spinner margin="small" renderTitle={formatMessage('Loading...')} size="large" />
        </Flex.Item>
      </Flex>
    )
  }
  return (
    <Flex direction="column" margin="none">
      {message && (
        <Flex.Item data-testid="alert-message">
          <Alert variant="info" renderCloseButtonLabel="Close" margin="small" timeout={10000}>
            {message}
          </Alert>
        </Flex.Item>
      )}
      <Flex.Item margin="0 0 small 0">
        <Controls settings={settings} dispatch={dispatch} />
      </Flex.Item>
      <Flex.Item>
        <Preview settings={settings} dispatch={dispatch} />
      </Flex.Item>
    </Flex>
  )
}

const renderFooter = (settings, onClose) => {
  return (
    <>
      <Button onClick={onClose} margin="0 x-small 0 0">
        {formatMessage('Cancel')}
      </Button>
      <Button color="primary" type="submit">
        {formatMessage('Save')}
      </Button>
    </>
  )
}

export const ImageCropperModal = ({
  open,
  onClose,
  onSubmit,
  image,
  message,
  cropSettings,
  loading
}) => {
  const [settings, dispatch] = useReducer(cropperSettingsReducer, defaultState)
  useEffect(() => {
    dispatch({type: actions.SET_IMAGE, payload: image})
  }, [image])

  useEffect(() => {
    cropSettings && dispatch({type: actions.UPDATE_SETTINGS, payload: cropSettings})
  }, [cropSettings])

  return (
    <Modal
      data-mce-component={true}
      as="form"
      label={formatMessage('Crop Image')}
      size="large"
      open={open}
      onDismiss={onClose}
      onSubmit={e => {
        e.preventDefault()
        handleSubmit(onSubmit, settings).then(onClose).catch(onClose)
      }}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header id="imageCropperHeader">
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={formatMessage('Close')}
        />
        <Heading>{formatMessage('Crop Image')}</Heading>
      </Modal.Header>
      <Modal.Body>{renderBody(settings, dispatch, message, loading)}</Modal.Body>
      {!loading && (
        <Modal.Footer id="imageCropperFooter">{renderFooter(settings, onClose)}</Modal.Footer>
      )}
    </Modal>
  )
}

ImageCropperModal.propTypes = {
  image: PropTypes.string.isRequired,
  cropSettings: ImageCropperSettingsPropTypes,
  message: PropTypes.string,
  open: PropTypes.bool,
  onClose: PropTypes.func,
  onSubmit: PropTypes.func,
  loading: PropTypes.bool
}

ImageCropperModal.defaultProps = {
  open: false,
  cropSettings: null,
  message: null,
  loading: false,
  onClose: () => {},
  onSubmit: () => {}
}
