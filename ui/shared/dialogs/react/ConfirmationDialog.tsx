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
import {legacyRender, legacyUnmountComponentAtNode} from '@canvas/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import CanvasModal from '@canvas/instui-bindings/react/Modal'

const I18n = createI18nScope('ConfirmationDialog')

const dialogHolderId = 'confirmation_dialog_holder'

type ButtonColor = 'primary' | 'primary-inverse' | 'secondary' | 'success' | 'danger'

interface ConfirmationDialogProps {
  open: boolean
  label: string
  children: React.ReactNode
  confirmColor?: ButtonColor
  confirmText?: string
  onConfirm: () => void
  onReject: () => void
  size?: 'auto' | 'small' | 'medium' | 'large' | 'fullscreen'
}

export default function ConfirmationDialog({
  open,
  label,
  children,
  confirmColor,
  confirmText,
  onConfirm,
  onReject,
  size = 'medium',
}: ConfirmationDialogProps) {
  return (
    <CanvasModal
      label={label}
      onDismiss={onReject}
      open={open}
      size={size}
      footer={
        <>
          <Button key="cancel" data-testid="cancel-button" onClick={onReject}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            key="confirm"
            data-testid="confirm-button"
            margin="0 0 0 small"
            color={confirmColor || 'primary'}
            onClick={onConfirm}
          >
            {confirmText || I18n.t('Confirm')}
          </Button>
        </>
      }
    >
      {children as React.ReactElement}
    </CanvasModal>
  )
}

interface ShowConfirmationDialogOptions {
  label: string
  body: React.ReactNode
  confirmText?: string
  confirmColor?: ButtonColor
  size?: 'auto' | 'small' | 'medium' | 'large' | 'fullscreen'
}

export async function showConfirmationDialog({
  label,
  body,
  confirmText,
  confirmColor,
  size = 'medium',
}: ShowConfirmationDialogOptions): Promise<boolean> {
  let resolver!: (value: boolean) => void
  const returnedPromise = new Promise<boolean>(resolve => {
    resolver = resolve
  })

  function getDialogContainer(): HTMLElement {
    let dialogContainer = document.getElementById(dialogHolderId)
    if (!dialogContainer) {
      dialogContainer = document.createElement('div')
      dialogContainer.id = dialogHolderId
      document.body.appendChild(dialogContainer)
    }
    return dialogContainer
  }

  const confirmationFunction = () => {
    legacyUnmountComponentAtNode(getDialogContainer())
    resolver(true)
  }

  const rejectFunction = () => {
    legacyUnmountComponentAtNode(getDialogContainer())
    resolver(false)
  }

  function renderDialog(parent: HTMLElement) {
    legacyRender(
      <ConfirmationDialog
        open={true}
        label={label}
        confirmColor={confirmColor}
        confirmText={confirmText}
        onConfirm={confirmationFunction}
        onReject={rejectFunction}
        size={size}
      >
        {body}
      </ConfirmationDialog>,
      parent,
    )
  }
  renderDialog(getDialogContainer())
  return returnedPromise
}
