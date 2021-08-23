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

import React from 'react'
import ReactDOM from 'react-dom'
import I18n from 'i18n!ConfirmationDialog'
import {Button} from '@instructure/ui-buttons'
import CanvasModal from '@canvas/instui-bindings/react/Modal'

const dialogHolderId = 'confirmation_dialog_holder'

export default function ConfirmationDialog({
  open,
  label,
  children,
  confirmColor,
  confirmText,
  onConfirm,
  onReject
}) {
  return (
    <CanvasModal
      label={label}
      onDismiss={onReject}
      open={open}
      size="small"
      footer={
        <>
          <Button onClick={onReject}>{I18n.t('Cancel')}</Button>
          <Button margin="0 0 0 small" variant={confirmColor || 'primary'} onClick={onConfirm}>
            {confirmText || I18n.t('Confirm')}
          </Button>
        </>
      }
    >
      {children}
    </CanvasModal>
  )
}

export async function showConfirmationDialog({label, body, confirmText, confirmColor}) {
  let resolver
  const returnedPromise = new Promise(resolve => {
    resolver = resolve
  })

  function getDialogContainer() {
    let dialogContainer = document.getElementById(dialogHolderId)
    if (!dialogContainer) {
      dialogContainer = document.createElement('div')
      dialogContainer.id = dialogHolderId
      document.body.appendChild(dialogContainer)
    }
    return dialogContainer
  }

  const confirmationFunction = () => {
    ReactDOM.unmountComponentAtNode(getDialogContainer())
    resolver(true)
  }

  const rejectFunction = () => {
    ReactDOM.unmountComponentAtNode(getDialogContainer())
    resolver(false)
  }

  function renderDialog(parent) {
    ReactDOM.render(
      <ConfirmationDialog
        open
        label={label}
        confirmColor={confirmColor}
        confirmText={confirmText}
        onConfirm={confirmationFunction}
        onReject={rejectFunction}
      >
        {body}
      </ConfirmationDialog>,
      parent
    )
  }
  renderDialog(getDialogContainer())
  return returnedPromise
}
