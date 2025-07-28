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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import Modal from './InstuiModal'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

// TODO: could probably generalize this along with Confirm.tsx

export type AlertProps = {
  title: string
  heading?: string
  message: React.ReactNode

  /**
   * defaults to primary
   */
  okButtonColor?: 'primary' | 'danger'

  /**
   * defaults to 'OK'
   */
  okButtonLabel?: string
}

/**
 * Replacement for window.alert() that uses the InstUI Modal component.
 * Provides a Promise that resolves when the user clicks the "OK" button.
 */
export function alert(alertProps: AlertProps): Promise<void> {
  return new Promise(resolve => {
    const alertContainer = getAlertContainer()
    const container = document.createElement('div')
    container.setAttribute('style', 'max-width:5em;margin:1rem auto;')
    container.setAttribute('class', 'flashalert-message')
    alertContainer.appendChild(container)
    const handleOk = () => {
      ReactDOM.unmountComponentAtNode(container)
      alertContainer.removeChild(container)
      resolve()
    }

    ReactDOM.render(<AlertModal {...alertProps} onOk={handleOk} />, container)
  })
}

const I18n = createI18nScope('modal')

type AlertModalProps = AlertProps & {
  onOk: () => void
}

const AlertModal = ({
  title: label,
  heading,
  message,
  okButtonColor,
  okButtonLabel,
  onOk,
}: AlertModalProps) => {
  return (
    <Modal
      open={true}
      label={label}
      onDismiss={onOk}
      shouldCloseOnDocumentClick={false}
      size="small"
    >
      <Modal.Body>
        {heading && <Heading level="h3">{heading}</Heading>}
        {typeof message === 'string' ? <Text as="p">{message}</Text> : message}
      </Modal.Body>

      <Modal.Footer>
        <View as="div" margin="small 0 0 0">
          <Button margin="x-small" onClick={onOk}>
            {okButtonLabel || I18n.t('Ok')}
          </Button>
        </View>
      </Modal.Footer>
    </Modal>
  )
}

const messageHolderId = 'canvas_alert_modal_holder'

function getAlertContainer() {
  let alertContainer = document.getElementById(messageHolderId)
  if (!alertContainer) {
    alertContainer = document.createElement('div')
    alertContainer.classList.add('clickthrough-container')
    alertContainer.id = messageHolderId
    alertContainer.setAttribute(
      'style',
      'position: fixed; top: 0; left: 0; width: 100%; z-index: 100000;',
    )
    document.body.appendChild(alertContainer)
  }
  return alertContainer
}
