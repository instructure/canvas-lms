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

import React, {useState, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Checkbox} from '@instructure/ui-checkbox'
import {AccessibilityResourceScan} from '../../../../../shared/react/types'

const I18n = createI18nScope('accessibility_checker')

const DONT_SHOW_MODAL_KEY = 'accessibility_checker_dont_show_close_remediation_modal'

export const shouldShowCloseRemediationModal = (): boolean => {
  return localStorage.getItem(DONT_SHOW_MODAL_KEY) !== 'true'
}

export const resetCloseRemediationModalPreference = (): void => {
  localStorage.removeItem(DONT_SHOW_MODAL_KEY)
}

interface CloseRemediationModalProps {
  isOpen: boolean
  scan: AccessibilityResourceScan
  onClose: () => void
  onReopen: () => void
}

export const CloseRemediationModal = ({
  isOpen,
  scan,
  onClose,
  onReopen,
}: CloseRemediationModalProps) => {
  const [dontShowAgain, setDontShowAgain] = useState(false)

  useEffect(() => {
    if (isOpen) {
      const stored = localStorage.getItem(DONT_SHOW_MODAL_KEY)
      setDontShowAgain(stored === 'true')
    }
  }, [isOpen])

  const handleClose = () => {
    if (dontShowAgain) {
      localStorage.setItem(DONT_SHOW_MODAL_KEY, 'true')
    }
    onClose()
  }

  const handleReopen = () => {
    if (dontShowAgain) {
      localStorage.setItem(DONT_SHOW_MODAL_KEY, 'true')
    }
    onReopen()
  }

  return (
    <Modal
      open={isOpen}
      onDismiss={handleClose}
      size="small"
      label={I18n.t('You closed remediation')}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
          data-testid="close-remediation-modal-button"
        />
        <Heading>{I18n.t('You closed remediation')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" padding="small 0">
          <Text>
            {I18n.t(
              'You have closed accessibility remediation on %{resourceName}. The remaining %{count} issues will no longer count towards unresolved issues statistics.',
              {
                resourceName: scan.resourceName,
                count: scan.issueCount,
              },
            )}
          </Text>
        </View>
        <View as="div" padding="small 0">
          <Text>{I18n.t('If you edit this resource, it will be reopened.')}</Text>
        </View>
        <View as="div" padding="small 0">
          <Checkbox
            label={I18n.t("Don't show this again")}
            checked={dontShowAgain}
            onChange={() => setDontShowAgain(!dontShowAgain)}
          />
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={handleReopen} margin="0 x-small 0 0">
          {I18n.t('Reopen')}
        </Button>
        <Button color="primary" onClick={handleClose}>
          {I18n.t('OK')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
