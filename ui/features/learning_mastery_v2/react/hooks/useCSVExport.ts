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

import {useState} from 'react'
import {exportCSV} from '../apiClient'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('Learning Mastery Gradebook')

export const EXPORT_NOT_STARTED = 'EXPORT_NOT_STARTED'
export const EXPORT_PENDING = 'EXPORT_PENDING'
export const EXPORT_COMPLETE = 'EXPORT_COMPLETE'
export const EXPORT_FAILED = 'EXPORT_FAILED'

export type ExportState =
  | typeof EXPORT_NOT_STARTED
  | typeof EXPORT_PENDING
  | typeof EXPORT_COMPLETE
  | typeof EXPORT_FAILED

interface CSVExportProps {
  courseId: string | number
  gradebookFilters: string[]
}

interface CSVExportHook {
  exportGradebook: () => void
  exportState: ExportState
  exportData: any[]
}

export default function useCSVExport({courseId, gradebookFilters}: CSVExportProps): CSVExportHook {
  const [exportState, setExportState] = useState<ExportState>(EXPORT_NOT_STARTED)
  const [exportData, setExportData] = useState<any[]>([])

  const exportGradebook = (): void => {
    ;(async () => {
      try {
        setExportState(EXPORT_PENDING)
        const response = await exportCSV(courseId, gradebookFilters)
        setExportData(response.data)
        setExportState(EXPORT_COMPLETE)
      } catch {
        setExportData([])
        setExportState(EXPORT_FAILED)
        showFlashAlert({
          message: I18n.t('Error exporting gradebook'),
          type: 'error',
        })
      }
    })()
  }

  return {
    exportGradebook,
    exportState,
    exportData,
  }
}
