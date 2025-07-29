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

import {useCallback, useState} from 'react'

type SettingsTrayOpen = {
  isOpen: true
  blockId: string
}

type SettingsTrayClosed = {
  isOpen: false
}

type SettingsTrayFunctions = {
  open: (editedBlockId: string) => void
  close: () => void
}

export type SettingsTray = (SettingsTrayOpen | SettingsTrayClosed) & SettingsTrayFunctions

export const useSettingsTray = (): SettingsTray => {
  const [blockId, setBlockId] = useState<string | null>(null)

  const isOpen = blockId !== null

  const open = useCallback(
    (blockId: string) => {
      setBlockId(blockId)
    },
    [setBlockId],
  )

  const close = useCallback(() => {
    setBlockId(null)
  }, [setBlockId])

  return isOpen
    ? {
        isOpen: true,
        blockId,
        open,
        close,
      }
    : {
        isOpen: false,
        open,
        close,
      }
}
