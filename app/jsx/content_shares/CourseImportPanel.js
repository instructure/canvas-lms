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

import I18n from 'i18n!direct_share_course_import_panel'
import React, {useState} from 'react'
import {func} from 'prop-types'
import doFetchApi from 'jsx/shared/effects/doFetchApi'
import contentShareShape from 'jsx/shared/proptypes/contentShare'
import DirectShareOperationStatus from 'jsx/shared/direct_share/DirectShareOperationStatus'
import ConfirmActionButtonBar from 'jsx/shared/components/ConfirmActionButtonBar'
import CourseAndModulePicker from 'jsx/shared/direct_share/CourseAndModulePicker'

CourseImportPanel.propTypes = {
  contentShare: contentShareShape.isRequired,
  onClose: func,
  onImport: func
}

export default function CourseImportPanel({contentShare, onClose, onImport}) {
  const [selectedCourse, setSelectedCourse] = useState(null)
  const [selectedModule, setSelectedModule] = useState(null)
  const [selectedPosition, setSelectedPosition] = useState(null)
  const [startImportOperationPromise, setStartImportOperationPromise] = useState(null)

  function startImportOperation() {
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
            insert_into_module_position: selectedPosition
          }
        }
      })
    )
    onImport(contentShare)
  }

  function handleSelectedCourse(course) {
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
