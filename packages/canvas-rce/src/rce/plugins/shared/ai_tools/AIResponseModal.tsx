/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import formatMessage from '../../../../format-message'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'

type AIResponseModaProps = {
  open: boolean
  html: string
  onClose: () => void
  onInsert: () => void
  onReplace: () => void
}

const AIResponseModal = ({open, html, onClose, onInsert, onReplace}: AIResponseModaProps) => {
  return (
    <Modal open={open} onDismiss={onClose} size="medium" label={formatMessage('AI Response')}>
      <Modal.Header>
        <CloseButton
          onClick={onClose}
          placement="end"
          offset="medium"
          screenReaderLabel={formatMessage('Close')}
        />
        <Heading level="h3">AI Response</Heading>
      </Modal.Header>
      <Modal.Body>
        <div dangerouslySetInnerHTML={{__html: html}} />
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} margin="medium 0 0 0">
          {formatMessage('Close')}
        </Button>
        <Button onClick={onReplace} margin="medium 0 0 medium">
          {formatMessage('Replace')}
        </Button>
        <Button onClick={onInsert} color="primary" margin="medium 0 0 medium">
          {formatMessage('Insert')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export {AIResponseModal}
