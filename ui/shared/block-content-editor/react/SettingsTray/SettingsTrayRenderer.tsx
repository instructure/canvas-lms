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

import React, {ReactElement, useEffect, useState} from 'react'
import {useEditor} from '@craftjs/core'
import {SettingsTray} from './SettingsTray'
import {useSettingsTray} from '../hooks/useSettingsTray'
import {useAppSelector} from '../store'

export const SettingsTrayRenderer = () => {
  const {query} = useEditor()
  const {isOpen, blockId} = useAppSelector(state => ({...state.settingsTray}))
  const {close} = useSettingsTray()

  const [currentSettings, setCurrentSettings] = useState<{
    blockDisplayName: string
    settings: ReactElement | null
  }>({
    blockDisplayName: '',
    settings: null,
  })

  useEffect(() => {
    if (isOpen && blockId) {
      const node = query.node(blockId).get()
      const blockDisplayName = node.data.displayName

      setCurrentSettings({
        blockDisplayName,
        settings: React.createElement(node.related.settings),
      })
    }
  }, [isOpen, blockId, query])

  const onDismiss = () => close()

  const onClose = () => {
    setCurrentSettings({
      blockDisplayName: '',
      settings: null,
    })
  }

  return (
    <SettingsTray
      blockDisplayName={currentSettings.blockDisplayName}
      open={isOpen}
      onDismiss={onDismiss}
      onClose={onClose}
    >
      {currentSettings.settings}
    </SettingsTray>
  )
}
