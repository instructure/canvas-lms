/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('SpeedGraderSettingsMenu')

// We're foregoing the use of InstUI buttons or instructure-icons icons here to be consistent
// with the look/styling of this button's siblings. When those siblings have been updated to
// use InstUI + instructure-icons, we can do the same here
const menuTrigger = (
  <button
    type="button"
    className="Button Button--icon-action-rev gradebookActions__Button"
    title={I18n.t('Settings')}
  >
    <i className="icon-settings" aria-hidden="true" />
    <span className="screenreader-only" aria-hidden="true">
      {I18n.t('SpeedGrader Settings')}
    </span>
  </button>
)

interface SpeedGraderSettingsMenuProps {
  assignmentID: string
  courseID: string
  helpURL: string
  menuContentRef?: (ref: HTMLElement | null) => void
  onMenuShow?: () => void
  openOptionsModal: () => void
  openKeyboardShortcutsModal: () => void
  showHelpMenuItem: boolean
  showModerationMenuItem: boolean
  showKeyboardShortcutsMenuItem: boolean
}

export default function SpeedGraderSettingsMenu({
  assignmentID,
  courseID,
  helpURL,
  menuContentRef = undefined,
  onMenuShow = () => {},
  openOptionsModal,
  openKeyboardShortcutsModal,
  showHelpMenuItem,
  showModerationMenuItem,
  showKeyboardShortcutsMenuItem,
}: SpeedGraderSettingsMenuProps) {
  function handleModerationPageSelect() {
    const url = `/courses/${courseID}/assignments/${assignmentID}/moderate`
    window.open(url, '_blank')
  }

  function handleHelpSelect() {
    SpeedGraderSettingsMenu.setURL(helpURL)
  }

  function handleToggle(isOpen: boolean) {
    if (isOpen) {
      onMenuShow()
    }
  }

  return (
    <Menu
      menuRef={menuContentRef}
      onToggle={handleToggle}
      placement="bottom end"
      trigger={menuTrigger}
    >
      <Menu.Item name="options" onSelect={openOptionsModal} value="options">
        <Text>{I18n.t('Options')}</Text>
      </Menu.Item>

      {showModerationMenuItem && (
        <Menu.Item
          name="moderationPage"
          onSelect={handleModerationPageSelect}
          value="moderationPage"
        >
          <Text>{I18n.t('Moderation Page')}</Text>
        </Menu.Item>
      )}

      {showKeyboardShortcutsMenuItem && (
        <Menu.Item
          name="keyboardShortcuts"
          onSelect={openKeyboardShortcutsModal}
          value="keyboardShortcuts"
        >
          <Text>{I18n.t('Keyboard Shortcuts')}</Text>
        </Menu.Item>
      )}

      {showHelpMenuItem && (
        <Menu.Item name="help" onSelect={handleHelpSelect} value="help">
          <Text>{I18n.t('Help')}</Text>
        </Menu.Item>
      )}
    </Menu>
  )
}

SpeedGraderSettingsMenu.setURL = function (url: string) {
  window.location.href = url
}
