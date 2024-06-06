/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import Modal from './InstuiModal'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

/**
 * Replacement for window.confirm() that uses the InstUI Modal component.
 * Provides a Promise that resolves to true if the user confirms, false if they cancel.
 */

export type ConfirmProps = {
  title: string
  heading?: string
  message: React.ReactNode

  /**
   * defaults to primary except when calling confirmDanger()
   */
  confirmButtonColor?: 'primary' | 'danger'

  /**
   * defaults to 'Confirm'
   */
  confirmButtonLabel?: string

  /**
   * defaults to 'Cancel'
   */
  cancelButtonLabel?: string
}

export function confirmDanger(
  confirmProps: Omit<ConfirmProps, 'confirmButtonColor'>
): Promise<boolean> {
  return confirm({
    ...confirmProps,
    confirmButtonColor: 'danger',
  })
}

export function confirm(confirmProps: ConfirmProps): Promise<boolean> {
  return new Promise(resolve => {
    const alertContainer = getConfirmContainer()
    const container = document.createElement('div')
    container.setAttribute('style', 'max-width:5em;margin:1rem auto;')
    container.setAttribute('class', 'flashalert-message')
    alertContainer.appendChild(container)
    const handleConfirm = () => {
      ReactDOM.unmountComponentAtNode(container)
      alertContainer.removeChild(container)
      resolve(true)
    }
    const handleCancel = () => {
      ReactDOM.unmountComponentAtNode(container)
      alertContainer.removeChild(container)
      resolve(false)
    }
    ReactDOM.render(
      <ConfirmationModal {...confirmProps} onConfirm={handleConfirm} onCancel={handleCancel} />,
      container
    )
  })
}

const I18n = useI18nScope('modal')

type ConfirmationModalProps = ConfirmProps & {
  onConfirm: () => void
  onCancel: () => void
}

const ConfirmationModal = ({
  title: label,
  heading,
  message,
  confirmButtonColor: confirmColor,
  confirmButtonLabel: confirmText,
  cancelButtonLabel: cancelText,
  onConfirm,
  onCancel,
}: ConfirmationModalProps) => {
  return (
    <Modal
      open={true}
      label={label}
      onDismiss={onCancel}
      shouldCloseOnDocumentClick={false}
      size="small"
    >
      <Modal.Body>
        {heading && <Heading level="h3">{heading}</Heading>}
        {typeof message === 'string' ? <Text as="p">{message}</Text> : message}
      </Modal.Body>

      <Modal.Footer>
        <View as="div" margin="small 0 0 0">
          <Button margin="x-small" onClick={onCancel}>
            {cancelText || I18n.t('Cancel')}
          </Button>
          <Button margin="x-small" color={confirmColor || 'primary'} onClick={onConfirm}>
            {confirmText || I18n.t('Confirm')}
          </Button>
        </View>
      </Modal.Footer>
    </Modal>
  )
}

const messageHolderId = 'canvas_confirm_modal_holder'

function getConfirmContainer() {
  let confirmContainer = document.getElementById(messageHolderId)
  if (!confirmContainer) {
    confirmContainer = document.createElement('div')
    confirmContainer.classList.add('clickthrough-container')
    confirmContainer.id = messageHolderId
    confirmContainer.setAttribute(
      'style',
      'position: fixed; top: 0; left: 0; width: 100%; z-index: 100000;'
    )
    document.body.appendChild(confirmContainer)
  }
  return confirmContainer
}
