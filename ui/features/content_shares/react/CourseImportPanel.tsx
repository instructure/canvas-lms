/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import DirectShareOperationStatus from '@canvas/direct-sharing/react/components/DirectShareOperationStatus'
import ConfirmActionButtonBar from '@canvas/direct-sharing/react/components/ConfirmActionButtonBar'
import CourseAndModulePicker from '@canvas/direct-sharing/react/components/CourseAndModulePicker'
import type {ContentShare} from '../types'

const I18n = createI18nScope('direct_share_course_import_panel')

interface Course {
  id: string
}

interface Module {
  id: string
}

export interface CourseImportPanelProps {
  contentShare: ContentShare
  onClose?: () => void
  onImport?: (share: ContentShare) => void
}

export default function CourseImportPanel({
  contentShare,
  onClose,
  onImport,
}: CourseImportPanelProps): React.JSX.Element {
  const [selectedCourse, setSelectedCourse] = useState<Course | null>(null)
  const [selectedModule, setSelectedModule] = useState<Module | null>(null)
  const [selectedPosition, setSelectedPosition] = useState<number | null>(null)
  const [startImportOperationPromise, setStartImportOperationPromise] =
    useState<Promise<unknown> | null>(null)

  function startImportOperation(): void {
    if (!selectedCourse || !contentShare.content_export) return

    setStartImportOperationPromise(
      doFetchApi({
        method: 'POST',
        path: `/api/v1/courses/${selectedCourse.id}/content_migrations`,
        body: {
          migration_type: 'canvas_cartridge_importer',
          settings: {
            content_export_id: contentShare.content_export.id,
            insert_into_module_id: selectedModule?.id || null,
            insert_into_module_type: contentShare.content_type,
            insert_into_module_position: selectedPosition,
            importer_skips: ['all_course_settings', 'folders'],
          },
        },
      }),
    )
    onImport?.(contentShare)
  }

  function handleSelectedCourse(course: Course): void {
    setSelectedModule(null)
    setSelectedCourse(course)
  }

  return (
    <>
      <DirectShareOperationStatus
        promise={startImportOperationPromise}
        startingMsg={I18n.t('Starting import operation')}
        successMsg={I18n.t('Import started successfully')}
        errorMsg={I18n.t('There was a problem starting import operation')}
      />
      <CourseAndModulePicker
        selectedCourseId={selectedCourse?.id}
        setSelectedCourse={handleSelectedCourse}
        selectedModuleId={selectedModule?.id || null}
        setSelectedModule={setSelectedModule}
        setModuleItemPosition={setSelectedPosition}
        disableModuleInsertion={contentShare.content_type === 'module'}
        moduleFilteringOpts={{per_page: 50}}
        courseFilteringOpts={{enforce_manage_grant_requirement: true}}
      />
      <ConfirmActionButtonBar
        padding="small 0 0 0"
        primaryLabel={startImportOperationPromise ? null : I18n.t('Import')}
        primaryDisabled={selectedCourse === null}
        secondaryLabel={startImportOperationPromise ? I18n.t('Close') : I18n.t('Cancel')}
        onPrimaryClick={startImportOperation}
        onSecondaryClick={onClose}
      />
    </>
  )
}
