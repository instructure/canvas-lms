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

import React, {useState} from 'react'

import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'

import formatMessage from '../../../../../../format-message'
import ComputerPanel from '../../../../shared/Upload/ComputerPanel'

export const UploadModal = ({label = formatMessage('Add Image'), onDismiss, open}) => {
  const [theFile, setFile] = useState(null)
  const [error, setError] = useState(null)

  const handleSubmit = event => {
    event.preventDefault()
  }

  return (
    <Modal
      data-mce-component
      as="form"
      label={label}
      onDismiss={onDismiss}
      onSubmit={handleSubmit}
      open={open}
      shouldCloseOnDocumentClick
    >
      <Modal.Header>
        <CloseButton onClick={onDismiss} offset="small" placement="end">
          {formatMessage('Close')}
        </CloseButton>
        <Heading>{label}</Heading>
      </Modal.Header>
      <Modal.Body>
        <ComputerPanel label={label} setError={setError} setFile={setFile} theFile={theFile} />
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onDismiss}>{formatMessage('Cancel')}</Button>&nbsp;
        <Button disabled={!!error} variant="primary" type="submit">
          {formatMessage('Next')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
