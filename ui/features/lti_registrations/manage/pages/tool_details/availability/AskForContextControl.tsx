/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import * as React from 'react'
import {createRoot} from 'react-dom/client'
import {Button} from '@instructure/ui-buttons'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('lti_registrations')

export type AskProps = {
  title: string
  heading?: string
  message?: React.ReactNode
  messageDangerouslySetInnerHTML?: {__html: string}
  confirmButtonColor?: 'primary' | 'danger'
  confirmButtonLabel?: string
  cancelButtonLabel?: string
}

/**
 * This is a helper function to ask the user for the values
 * needed to create a context control.
 *
 * It's only used in debug mode for testing purposed,
 * and will be deleted when we build the final selection screen
 *
 * @param confirmProps
 * @returns
 */
export function askForContextControl(confirmProps: AskProps): Promise<[string, boolean]> {
  return new Promise((resolve, reject) => {
    const alertContainer = getConfirmContainer()
    const container = document.createElement('div')
    container.setAttribute('style', 'max-width:5em;margin:1rem auto;')
    container.setAttribute('class', 'flashalert-message')
    alertContainer.appendChild(container)

    const root = createRoot(container)
    const handleConfirm = (s: string, isCourse: boolean) => {
      root.unmount()
      alertContainer.removeChild(container)
      resolve([s, isCourse])
    }
    const handleCancel = () => {
      root.unmount()
      alertContainer.removeChild(container)
      reject()
    }

    root.render(
      <ConfirmationModal {...confirmProps} onConfirm={handleConfirm} onCancel={handleCancel} />,
    )
  })
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
      'position: fixed; top: 0; left: 0; width: 100%; z-index: 100000;',
    )
    document.body.appendChild(confirmContainer)
  }
  return confirmContainer
}

type ConfirmationModalProps = AskProps & {
  onConfirm: (s: string, isCourse: boolean) => void
  onCancel: () => void
}

const ConfirmationModal = ({
  title: label,
  heading,
  message,
  messageDangerouslySetInnerHTML,
  confirmButtonColor: confirmColor,
  confirmButtonLabel: confirmText,
  cancelButtonLabel: cancelText,
  onConfirm,
  onCancel,
}: ConfirmationModalProps) => {
  const [state, setState] = React.useState('')
  const [isCourse, setIsCourse] = React.useState(false)
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
        {messageDangerouslySetInnerHTML && (
          <Text as="p" dangerouslySetInnerHTML={messageDangerouslySetInnerHTML} />
        )}
        <TextInput
          renderLabel="Context ID"
          value={state}
          onChange={e => {
            setState(e.currentTarget.value)
          }}
        ></TextInput>
        <View margin="small 0 0 " as={'div'}>
          <Checkbox
            checked={isCourse}
            onChange={() => {
              setIsCourse(!isCourse)
            }}
            label="Is Course"
          ></Checkbox>
        </View>
      </Modal.Body>

      <Modal.Footer>
        <View as="div" margin="small 0 0 0">
          <Button margin="x-small" onClick={onCancel}>
            {cancelText || I18n.t('Cancel')}
          </Button>
          <Button
            margin="x-small"
            color={confirmColor || 'primary'}
            onClick={() => onConfirm(state, isCourse)}
          >
            {confirmText || I18n.t('Confirm')}
          </Button>
        </View>
      </Modal.Footer>
    </Modal>
  )
}
