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
import {useState, useRef, type ReactNode, useMemo} from 'react'
import {createRoot} from 'react-dom/client'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import Modal from './InstuiModal'
import {Text} from '@instructure/ui-text'
import {FormMessage} from '@instructure/ui-form-field'

export type PromptConfirmProps = {
  valueMatchesExpected: (value: string) => boolean
  title: string
  message: ReactNode
  placeholder?: string
  hintText?: string
  label?: string
  confirmButtonLabel?: string
  cancelButtonLabel?: string
}

export function confirmWithPrompt(props: PromptConfirmProps): Promise<boolean> {
  return new Promise(resolve => {
    const alertContainer = getConfirmContainer()
    const container = document.createElement('div')
    container.setAttribute('style', 'max-width:5em;margin:1rem auto;')
    container.setAttribute('class', 'flashalert-message')
    alertContainer.appendChild(container)

    const handleConfirm = () => {
      root.unmount()
      alertContainer.removeChild(container)
      resolve(true)
    }

    const handleCancel = () => {
      root.unmount()
      alertContainer.removeChild(container)
      resolve(false)
    }

    const root = createRoot(container)
    root.render(
      <PromptConfirmationModal {...props} onConfirm={handleConfirm} onCancel={handleCancel} />,
    )
  })
}

const I18n = createI18nScope('modal')

type PromptConfirmationModalProps = PromptConfirmProps & {
  onConfirm: () => void
  onCancel: () => void
}

const PromptConfirmationModal = ({
  valueMatchesExpected,
  hintText,
  placeholder,
  label,
  title,
  message,
  confirmButtonLabel,
  cancelButtonLabel,
  onConfirm,
  onCancel,
}: PromptConfirmationModalProps) => {
  const [inputValue, setInputValue] = useState('')
  const [error, setError] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement | null>(null)

  const messages = useMemo((): FormMessage[] => {
    return [
      error ? {text: error, type: 'error'} : undefined,
      hintText ? {text: hintText, type: 'hint'} : undefined,
    ].filter(Boolean) as FormMessage[]
  }, [hintText, error])

  const handleConfirmClick = () => {
    if (valueMatchesExpected(inputValue)) {
      onConfirm()
    } else {
      setError(I18n.t('The provided value is incorrect. Please try again.'))
      inputRef.current?.focus()
    }
  }

  return (
    <Modal
      open={true}
      label={title}
      onDismiss={onCancel}
      shouldCloseOnDocumentClick={false}
      size="small"
    >
      <Modal.Body>
        {typeof message === 'string' ? <Text as="p">{message}</Text> : message}
        <TextInput
          renderLabel={label}
          value={inputValue}
          required={true}
          placeholder={placeholder}
          onChange={(_, value) => setInputValue(value)}
          data-testid="confirm-prompt-input"
          messages={messages}
          inputRef={ref => {
            if (inputRef.current === null) {
              inputRef.current = ref
            }
          }}
        />
      </Modal.Body>

      <Modal.Footer>
        <View as="div" margin="small 0 0 0">
          <Button margin="x-small" onClick={onCancel} data-testid="confirm-prompt-cancel-button">
            {cancelButtonLabel || I18n.t('Cancel')}
          </Button>
          <Button
            margin="x-small"
            color="primary"
            onClick={handleConfirmClick}
            data-testid="confirm-prompt-confirm-button"
          >
            {confirmButtonLabel || I18n.t('Confirm')}
          </Button>
        </View>
      </Modal.Footer>
    </Modal>
  )
}

const messageHolderId = 'canvas_confirm_with_prompt_modal_holder'

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
