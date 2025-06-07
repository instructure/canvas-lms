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

import React, {useEffect, useState, useCallback} from 'react'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

interface Shortcut {
  keycode: string
  description: string
}

interface KeyboardShortcutModalProps {
  shortcuts?: Shortcut[]
}

const KeyboardShortcutModal: React.FC<KeyboardShortcutModalProps> = ({shortcuts = []}) => {
  const I18n = useI18nScope('keyboardShortcutModal')
  const [isOpen, setIsOpen] = useState(false)

  const closeModal = () => {
    setIsOpen(false)
  }

  const handleKeydown = useCallback(
    (e: KeyboardEvent) => {
      if (e.repeat) return
      const keyComboPressed = e.key === '?' && e.shiftKey
      const target = e.target as HTMLElement
      if (keyComboPressed && target.nodeName !== 'INPUT' && target.nodeName !== 'TEXTAREA') {
        e.preventDefault()
        setIsOpen(!isOpen)
      }
    },
    [isOpen],
  )

  useEffect(() => {
    document.addEventListener('keydown', handleKeydown)
    return () => {
      document.removeEventListener('keydown', handleKeydown)
    }
  }, [handleKeydown])

  return (
    <Modal
      data-canvas-component={true}
      open={isOpen}
      label={I18n.t('Keyboard Shortcuts')}
      onDismiss={closeModal}
    >
      <Modal.Body>
        <div className="keyboard_navigation">
          <ScreenReaderContent>
            {I18n.t(
              'Users of screen readers may need to turn off the virtual cursor in order to use these keyboard shortcuts',
            )}
          </ScreenReaderContent>
          <ul className="navigation_list">
            {shortcuts.map(shortcut => (
              <li key={shortcut.keycode}>
                <span className="keycode">{shortcut.keycode}</span>
                <span className="colon">:</span>
                <span className="description">{shortcut.description}</span>
              </li>
            ))}
          </ul>
        </div>
      </Modal.Body>
    </Modal>
  )
}

export default KeyboardShortcutModal
