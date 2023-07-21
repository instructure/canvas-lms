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

import {useScope as useI18nScope} from '@canvas/i18n'

import React, {useState} from 'react'
import {func, string} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'

import doFetchApi from '@canvas/do-fetch-api-effect'
import contentSelectionShape from '../proptypes/contentSelection'
import ConfirmActionButtonBar from './ConfirmActionButtonBar'
import CourseAndModulePicker from './CourseAndModulePicker'
import DirectShareOperationStatus from './DirectShareOperationStatus'

const I18n = useI18nScope('direct_share_course_panel')

// eventually this will have options for where to place the item in the new course.
// for now, it just has the selector plus some buttons

DirectShareCoursePanel.propTypes = {
  sourceCourseId: string,
  contentSelection: contentSelectionShape,
  onCancel: func,
}

export default function DirectShareCoursePanel({sourceCourseId, contentSelection, onCancel}) {
  const [selectedCourse, setSelectedCourse] = useState(null)
  const [startCopyOperationPromise, setStartCopyOperationPromise] = useState(null)
  const [selectedModule, setSelectedModule] = useState(null)
  const [selectedPosition, setSelectedPosition] = useState(null)

  function startCopyOperation() {
    setStartCopyOperationPromise(
      doFetchApi({
        method: 'POST',
        path: `/api/v1/courses/${selectedCourse.id}/content_migrations`,
        body: {
          migration_type: 'course_copy_importer',
          select: contentSelection,
          settings: {
            source_course_id: sourceCourseId,
            insert_into_module_id: selectedModule?.id || null,
            insert_into_module_type: contentSelection ? Object.keys(contentSelection)[0] : null,
            insert_into_module_position: selectedPosition,
          },
        },
      })
    )
  }

  function handleSelectedCourse(course) {
    setSelectedModule(null)
    setSelectedCourse(course)
  }

  return (
    <>
      <DirectShareOperationStatus
        promise={startCopyOperationPromise}
        startingMsg={I18n.t('Starting copy operation')}
        successMsg={I18n.t('Copy operation started successfully')}
        errorMsg={I18n.t('There was a problem starting the copy operation')}
      />
      <CourseAndModulePicker
        selectedCourseId={selectedCourse?.id}
        setSelectedCourse={handleSelectedCourse}
        selectedModuleId={selectedModule?.id || null}
        setSelectedModule={setSelectedModule}
        setModuleItemPosition={setSelectedPosition}
        disableModuleInsertion={contentSelection && 'modules' in contentSelection}
        moduleFilteringOpts={{per_page: 50}}
        courseFilteringOpts={{enforce_manage_grant_requirement: true}}
      />
      <Alert variant="warning" hasShadow={false}>
        {I18n.t(
          'Importing the same course content more than once will overwrite any existing content in the course.'
        )}
      </Alert>
      <ConfirmActionButtonBar
        padding="small 0 0 0"
        primaryLabel={startCopyOperationPromise ? null : I18n.t('Copy')}
        primaryDisabled={selectedCourse === null}
        secondaryLabel={startCopyOperationPromise ? I18n.t('Close') : I18n.t('Cancel')}
        onPrimaryClick={startCopyOperation}
        onSecondaryClick={onCancel}
      />
    </>
  )
}
