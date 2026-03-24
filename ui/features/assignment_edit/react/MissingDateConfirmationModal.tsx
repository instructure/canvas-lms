/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {forwardRef, useCallback, useImperativeHandle, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('calendar.edit')

export interface MissingDateConfirmationModalHandle {
  open: () => void
  close: () => void
}

interface MissingDateConfirmationModalProps {
  onContinue?: () => void
  onGoBack?: () => void
}

const MissingDateConfirmationModal = forwardRef<
  MissingDateConfirmationModalHandle,
  MissingDateConfirmationModalProps
>(function MissingDateConfirmationModal({onContinue, onGoBack}, ref) {
  const [isOpen, setIsOpen] = useState(false)

  useImperativeHandle(
    ref,
    () => ({
      open() {
        setIsOpen(true)
      },
      close() {
        setIsOpen(false)
      },
    }),
    [],
  )

  const handleGoBack = useCallback(() => {
    setIsOpen(false)
    onGoBack?.()
  }, [onGoBack])

  const handleContinue = useCallback(() => {
    setIsOpen(false)
    onContinue?.()
  }, [onContinue])

  return (
    <Modal open={isOpen} onDismiss={handleGoBack} label={I18n.t('Warning')}>
      <Modal.Body>
        <View as="div" margin="0 0 small 0">
          <Text>{I18n.t('Not everyone will be assigned this item!')}</Text>
        </View>
        <Text>{I18n.t('Would you like to continue?')}</Text>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={handleGoBack} margin="0 x-small 0 0">
          {I18n.t('Go Back')}
        </Button>
        <Button color="primary" onClick={handleContinue}>
          {I18n.t('Continue')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
})

export default MissingDateConfirmationModal
