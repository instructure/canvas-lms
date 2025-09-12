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
import {useScope as createI18nScope} from '@canvas/i18n'
import {SettingsTray} from './SettingsTray'
import {useBlockContentEditorContext} from '../BlockContentEditorContext'
import React, {ReactElement, useEffect, useState} from 'react'

const I18n = createI18nScope('block_content_editor')

export const SettingsTrayRenderer = () => {
  const {query} = useEditor()
  const {settingsTray} = useBlockContentEditorContext()

  const [currentSettings, setCurrentSettings] = useState<{
    title: string
    settings: ReactElement | null
  }>({
    title: '',
    settings: null,
  })

  useEffect(() => {
    if (settingsTray.isOpen && settingsTray.blockId) {
      const node = query.node(settingsTray.blockId).get()
      const title = I18n.t('%{blockDisplayName} block settings', {
        blockDisplayName: node.data.displayName,
      })

      setCurrentSettings({
        title,
        settings: React.createElement(node.related.settings),
      })
    }
  }, [settingsTray.isOpen, settingsTray.isOpen && settingsTray.blockId, query])

  const onDismiss = () => {
    settingsTray.close()
  }

  const onClose = () => {
    setCurrentSettings({
      title: '',
      settings: null,
    })
  }

  return (
    <SettingsTray
      title={currentSettings.title}
      open={settingsTray.isOpen}
      onDismiss={onDismiss}
      onClose={onClose}
    >
      {currentSettings.settings}
    </SettingsTray>
  )
}
