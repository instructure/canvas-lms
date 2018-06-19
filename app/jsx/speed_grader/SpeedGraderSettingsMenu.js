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
import {bool, func, string} from 'prop-types'
import MenuItem from '@instructure/ui-core/lib/components/Menu/MenuItem'
import PopoverMenu from '@instructure/ui-core/lib/components/PopoverMenu'
import Text from '@instructure/ui-core/lib/components/Text'
import I18n from 'i18n!gradebook'

export default function SpeedGraderSettingsMenu(props) {
  function handleModerationPageSelect () {
    const url = `/courses/${props.courseID}/assignments/${props.assignmentID}/moderate`
    window.open(url, '_blank')
  }

  function handleHelpSelect () {
    SpeedGraderSettingsMenu.setURL(props.helpURL)
  }

  // We're foregoing the use of InstUI buttons or instructure-icons icons here to be consistent
  // with the look/styling of this button's siblings. When those siblings have been updated to
  // use InstUI + instructure-icons, we can do the same here
  const menuTrigger = (
    <button
      type="button"
      className="Button Button--icon-action gradebookActions__Button"
      title={I18n.t('Settings')}
    >
      <i className="icon-settings" aria-hidden="true" />
      <span className="screenreader-only" aria-hidden="true">
        {I18n.t('SpeedGrader Settings')}
      </span>
    </button>
  )

  return (
    <PopoverMenu contentRef={props.menuContentRef} placement="bottom end" trigger={menuTrigger}>
      <MenuItem name="options" onSelect={props.openOptionsModal} value="options">
        <Text>{I18n.t('Options')}</Text>
      </MenuItem>

      {props.showModerationMenuItem && (
        <MenuItem name="moderationPage" onSelect={handleModerationPageSelect} value="moderationPage">
          <Text>{I18n.t('Moderation Page')}</Text>
        </MenuItem>
      )}

      <MenuItem name="keyboardShortcuts" onSelect={props.openKeyboardShortcutsModal} value="keyboardShortcuts">
        <Text>{I18n.t('Keyboard Shortcuts')}</Text>
      </MenuItem>

      {props.showHelpMenuItem && (
        <MenuItem name="help" onSelect={handleHelpSelect} value="help">
          <Text>{I18n.t('Help')}</Text>
        </MenuItem>
      )}
    </PopoverMenu>
  )
}

SpeedGraderSettingsMenu.propTypes = {
  assignmentID: string.isRequired,
  courseID: string.isRequired,
  helpURL: string.isRequired,
  menuContentRef: func,
  openOptionsModal: func.isRequired,
  openKeyboardShortcutsModal: func.isRequired,
  showHelpMenuItem: bool.isRequired,
  showModerationMenuItem: bool.isRequired
}

SpeedGraderSettingsMenu.defaultProps = {
  menuContentRef: null
}

SpeedGraderSettingsMenu.setURL = function (url) {
  window.location.href = url
}