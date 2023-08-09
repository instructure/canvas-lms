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
import formatMessage from '../../../../format-message'
import {cropperSettingsReducer, actions, defaultState} from './reducers/imageCropper'
import {Preview} from './Preview'
import {Controls} from './controls'
import {ImageCropperSettingsPropTypes} from './propTypes'
import {DirectionRegion} from './DirectionRegion'
import {instuiPopupMountNode} from '../../../../util/fullscreenHelpers'

const renderBody = (image, settings, dispatch, message, loading) => {
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
        <Preview image={image} settings={settings} dispatch={dispatch} />
      </Flex.Item>
      <DirectionRegion direction={settings.direction} />
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
  shape,
  onClose,
  onSubmit,
  image,
  message,
  cropSettings,
  loading,
}) => {
  const [settings, dispatch] = useReducer(cropperSettingsReducer, defaultState)

  useEffect(() => {
    shape !== settings.shape && dispatch({type: actions.SET_SHAPE, payload: shape})
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [shape])

  useEffect(() => {
    cropSettings && dispatch({type: actions.UPDATE_SETTINGS, payload: cropSettings})
  }, [cropSettings])

  return (
    <Modal
      data-mce-component={true}
      as="form"
      label={formatMessage('Crop Image')}
      mountNode={instuiPopupMountNode}
      size="large"
      open={open}
      onDismiss={onClose}
      onSubmit={e => {
        e.preventDefault()
        // Direction is only used while in cropper and
        // should not be embedded in the icon's metadata
        const {direction, ...cropperSettings} = settings
        onSubmit(cropperSettings)
        onClose()
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
      <Modal.Body>{renderBody(image, settings, dispatch, message, loading)}</Modal.Body>
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
  shape: PropTypes.string,
  onClose: PropTypes.func,
  onSubmit: PropTypes.func,
  loading: PropTypes.bool,
}

ImageCropperModal.defaultProps = {
  shape: 'square',
  open: false,
  cropSettings: null,
  message: null,
  loading: false,
  onClose: () => {},
  onSubmit: () => {},
}
