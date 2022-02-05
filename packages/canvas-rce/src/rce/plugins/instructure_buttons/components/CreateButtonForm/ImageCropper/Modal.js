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

export const ImageCropperModal = ({open, onClose, image}) => {
  const [settings, dispatch] = useReducer(cropperSettingsReducer, defaultState)
  useEffect(() => {
    dispatch({type: actions.SET_IMAGE, payload: image})
  }, [image])

  return (
    <Modal size="large" open={open} onDismiss={onClose} shouldCloseOnDocumentClick={false}>
      <Modal.Header>
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
      <Modal.Footer>
        <Button onClick={onClose} margin="0 x-small 0 0">
          {formatMessage('Cancel')}
        </Button>
        <Button color="primary" type="submit">
          {formatMessage('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

ImageCropperModal.propTypes = {
  open: PropTypes.bool,
  onClose: PropTypes.func,
  image: PropTypes.string
}
