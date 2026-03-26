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
import React, {useState, useRef, useMemo, useEffect} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('SIS_Import')

interface ConfirmationModalProps {
  isOpen: boolean
  onSubmit: () => void
  onRequestClose: () => void
  showBatchModeWarning: boolean
  showSiteAdminConfirmation: boolean
  accountName: string
}

export function ConfirmationModal({
  isOpen,
  onSubmit,
  onRequestClose,
  showBatchModeWarning,
  showSiteAdminConfirmation,
  accountName,
}: ConfirmationModalProps) {
  const [inputValue, setInputValue] = useState('')
  const [error, setError] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement | null>(null)

  const messages = useMemo((): FormMessage[] => {
    if (error) {
      return [{text: error, type: 'error'}]
    }
    return []
  }, [error])

  useEffect(() => {
    if (!isOpen) {
      setInputValue('')
      setError(null)
    }
  }, [isOpen])

  const handleConfirm = () => {
    if (showSiteAdminConfirmation && inputValue.toLowerCase() !== accountName.toLowerCase()) {
      setError(I18n.t('Account name does not match. Please try again.'))
      inputRef.current?.focus()
      return
    }
    setInputValue('')
    setError(null)
    onSubmit()
  }

  const handleClose = () => {
    setInputValue('')
    setError(null)
    onRequestClose()
  }

  return (
    <Modal
      as="form"
      open={isOpen}
      onDismiss={handleClose}
      onSubmit={(e: React.FormEvent) => {
        e.preventDefault()
        handleConfirm()
      }}
      size="small"
      label={I18n.t('Confirm SIS Import')}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={handleClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Confirm SIS Import')}</Heading>
      </Modal.Header>
      <Modal.Body>
        {showSiteAdminConfirmation && (
          <>
            <Alert variant="warning" margin="0 0 small 0">
              {I18n.t(
                'You are about to import SIS data as a site admin into an account you do not directly administer.',
              )}
            </Alert>
            <Text as="p" weight="bold">
              {I18n.t('Account: %{accountName}', {accountName})}
            </Text>
            <TextInput
              renderLabel={I18n.t('Type the account name to confirm')}
              value={inputValue}
              onChange={(_e, value) => {
                setInputValue(value)
                setError(null)
              }}
              messages={messages}
              data-testid="site-admin-confirm-input"
              inputRef={ref => {
                inputRef.current = ref
              }}
            />
          </>
        )}
        {showBatchModeWarning && (
          <>
            <Alert variant="warning" margin={showSiteAdminConfirmation ? 'medium 0 small 0' : 'small'}>
              {I18n.t(
                'If selected, this will delete everything for this term, which includes all courses and enrollments that are not in the selected import file above. See the documentation for details.',
              )}
            </Alert>
            <div>{I18n.t('Please confirm you want to move forward with these changes.')}</div>
          </>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button
          id="confirmation_modal_cancel"
          onClick={handleClose}
          margin="0 buttons 0 0"
          data-testid="site-admin-cancel-btn"
        >
          {I18n.t('Cancel')}
        </Button>
        <Button
          id="confirmation_modal_confirm"
          color="primary"
          type="submit"
          data-testid="site-admin-confirm-btn"
        >
          {I18n.t('Confirm')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
