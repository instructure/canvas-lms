/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import formatMessage from '../../../../format-message'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {func} from 'prop-types'
import {TextArea} from '@instructure/ui-text-area'
import {instuiPopupMountNode} from '../../../../util/fullscreenHelpers'

export function Embed({onSubmit, onDismiss}) {
  const [embedCode, setEmbedCode] = useState('')

  return (
    <Modal
      data-mce-component={true}
      label={formatMessage('Embed')}
      mountNode={instuiPopupMountNode}
      size="medium"
      onDismiss={onDismiss}
      open={true}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          onClick={onDismiss}
          offset="medium"
          placement="end"
          screenReaderLabel={formatMessage('Close')}
        />
        <Heading>{formatMessage('Embed')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <TextArea
          maxHeight="10rem"
          label={formatMessage('Embed Code')}
          value={embedCode}
          onChange={e => {
            setEmbedCode(e.target.value)
          }}
        />
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onDismiss}>{formatMessage('Close')}</Button>&nbsp;
        <Button
          onClick={e => {
            e.preventDefault()
            onSubmit(embedCode)
            onDismiss()
          }}
          color="primary"
          type="submit"
          disabled={!embedCode}
        >
          {formatMessage('Submit')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

Embed.propTypes = {
  onSubmit: func.isRequired,
  onDismiss: func.isRequired,
}
