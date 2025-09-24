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

import {useEditor} from '@craftjs/core'
import {SettingsTray} from './SettingsTray'
import {useBlockContentEditorContext} from '../BlockContentEditorContext'
import React, {ReactElement, useEffect, useState} from 'react'

export const SettingsTrayRenderer = () => {
  const {query} = useEditor()
  const {settingsTray} = useBlockContentEditorContext()

  const [currentSettings, setCurrentSettings] = useState<{
    blockDisplayName: string
    settings: ReactElement | null
  }>({
    blockDisplayName: '',
    settings: null,
  })

  useEffect(() => {
    if (settingsTray.isOpen && settingsTray.blockId) {
      const node = query.node(settingsTray.blockId).get()
      const blockDisplayName = node.data.displayName

      setCurrentSettings({
        blockDisplayName,
        settings: React.createElement(node.related.settings),
      })
    }
  }, [settingsTray.isOpen, settingsTray.isOpen && settingsTray.blockId, query])

  const onDismiss = () => {
    settingsTray.close()
  }

  const onClose = () => {
    setCurrentSettings({
      blockDisplayName: '',
      settings: null,
    })
  }

  return (
    <SettingsTray
      blockDisplayName={currentSettings.blockDisplayName}
      open={settingsTray.isOpen}
      onDismiss={onDismiss}
      onClose={onClose}
    >
      {currentSettings.settings}
    </SettingsTray>
  )
}
