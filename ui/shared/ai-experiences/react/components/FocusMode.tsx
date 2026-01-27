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

import React, {useEffect, useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {CloseButton, Button} from '@instructure/ui-buttons'

const I18n = createI18nScope('ai_experiences')

interface FocusModeProps {
  isOpen: boolean
  onClose: () => void
  children: React.ReactNode
  title?: string
}

const FocusMode: React.FC<FocusModeProps> = ({
  isOpen,
  onClose,
  children,
  title = I18n.t('Conversation'),
}) => {
  // Handle ESC key press
  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      if (event.key === 'Escape' && isOpen) {
        onClose()
      }
    },
    [isOpen, onClose],
  )

  useEffect(() => {
    if (isOpen) {
      document.addEventListener('keydown', handleKeyDown)
      return () => {
        document.removeEventListener('keydown', handleKeyDown)
      }
    }
  }, [isOpen, handleKeyDown])

  if (!isOpen) return null

  return (
    <Modal
      open={isOpen}
      onDismiss={onClose}
      size="fullscreen"
      label={title}
      shouldCloseOnDocumentClick={false}
      shouldReturnFocus={false}
    >
      <Modal.Header>
        <Flex gap="small" alignItems="center" justifyItems="space-between" width="100%">
          <Flex.Item shouldGrow>
            <Heading>{title}</Heading>
          </Flex.Item>
          <Flex.Item>
            <CloseButton
              onClick={onClose}
              screenReaderLabel={I18n.t('Exit focus mode')}
              data-testid="focus-mode-exit-button"
            />
          </Flex.Item>
        </Flex>
      </Modal.Header>
      <Modal.Body padding="0">
        <div
          style={{
            outline: 'none',
            height: 'calc(100vh - 200px)',
            display: 'flex',
            flexDirection: 'column',
            overflow: 'hidden',
          }}
          tabIndex={-1}
        >
          <Flex direction="column" height="100%" style={{overflow: 'hidden'}}>
            <Flex.Item
              shouldGrow
              shouldShrink
              style={{display: 'flex', flexDirection: 'column', overflow: 'hidden'}}
            >
              <View
                as="div"
                maxWidth="1200px"
                width="100%"
                margin="0 auto"
                height="100%"
                padding="medium"
                style={{overflow: 'hidden', boxSizing: 'border-box'}}
              >
                {children}
              </View>
            </Flex.Item>
          </Flex>
        </div>
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item>
            <Button onClick={onClose} color="secondary" data-testid="focus-mode-exit-button-footer">
              {I18n.t('Exit Focus Mode')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default FocusMode
