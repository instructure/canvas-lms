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
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {ImageCropper} from './ImageCropper'
import formatMessage from '../../../../../../format-message'

export const ImageCropperModal = ({open, onClose, image}) => {
  return (
    <Modal size="large" open={open} onDismiss={onClose} shouldCloseOnDocumentClick={false}>
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onClose} screenReaderLabel="Close" />
        <Heading>{formatMessage('Crop Image')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <ImageCropper image={image} />
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
