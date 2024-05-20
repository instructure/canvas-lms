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
import {Button} from '@instructure/ui-buttons'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

type ConfirmationModalProps = {
  message: string | React.ReactNode
  confirmText?: string
  cancelText?: string
  onConfirm: () => void
  onCancel: () => void
}

const ConfirmationModal = ({
  message,
  confirmText,
  cancelText,
  onConfirm,
  onCancel,
}: ConfirmationModalProps) => {
  return (
    <Alert variant="warning">
      <Text>{message}</Text>
      <View as="div" margin="small 0 0 0">
        <Button margin="x-small" onClick={onCancel}>
          {cancelText || 'Cancel'}
        </Button>
        <Button margin="x-small" color="danger" onClick={onConfirm}>
          {confirmText || 'Confirm'}
        </Button>
      </View>
    </Alert>
  )
}

const messageHolderId = 'flashalert_message_holder' // canvas

function getAlertContainer() {
  let alertContainer = document.getElementById(messageHolderId)
  if (!alertContainer) {
    alertContainer = document.createElement('div')
    alertContainer.classList.add('clickthrough-container')
    alertContainer.id = messageHolderId
    alertContainer.setAttribute(
      'style',
      'position: fixed; top: 0; left: 0; width: 100%; z-index: 100000;'
    )
    document.body.appendChild(alertContainer)
  }
  return alertContainer
}

function confirm(
  message: string | React.ReactNode,
  confirmText: string = 'Confirm',
  cancelText: string = 'Cancel'
): Promise<boolean> {
  return new Promise(resolve => {
    const alertContainer = getAlertContainer()
    const container = document.createElement('div')
    container.setAttribute('style', 'max-width:30em;margin:1rem auto;')
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
      <ConfirmationModal
        message={message}
        confirmText={confirmText}
        cancelText={cancelText}
        onConfirm={handleConfirm}
        onCancel={handleCancel}
      />,
      container
    )
  })
}

export default confirm
export {ConfirmationModal}
