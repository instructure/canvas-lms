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

import I18n from 'i18n!direct_share_course_panel'

import React, {useState} from 'react'
import {func, string} from 'prop-types'

import doFetchApi from 'jsx/shared/effects/doFetchApi'
import contentSelectionShape from 'jsx/shared/proptypes/contentSelection'
import ConfirmActionButtonBar from '../components/ConfirmActionButtonBar'
import ManagedCourseSelector from '../components/ManagedCourseSelector'
import DirectShareOperationStatus from './DirectShareOperationStatus'

// eventually this will have options for where to place the item in the new course.
// for now, it just has the selector plus some buttons

DirectShareCoursePanel.propTypes = {
  sourceCourseId: string,
  contentSelection: contentSelectionShape,
  onCancel: func
}

export default function DirectShareCoursePanel({sourceCourseId, contentSelection, onCancel}) {
  const [selectedCourse, setSelectedCourse] = useState(null)
  const [startCopyOperationPromise, setStartCopyOperationPromise] = useState(null)

  function startCopyOperation() {
    setStartCopyOperationPromise(
      doFetchApi({
        method: 'POST',
        path: `/api/v1/courses/${selectedCourse.id}/content_migrations`,
        body: {
          migration_type: 'course_copy_importer',
          select: contentSelection,
          settings: {source_course_id: sourceCourseId}
        }
      })
    )
  }

  return (
    <>
      <DirectShareOperationStatus
        promise={startCopyOperationPromise}
        startingMsg={I18n.t('Starting copy operation')}
        successMsg={I18n.t('Copy operation started successfully')}
        errorMsg={I18n.t('There was a problem starting the copy operation')}
      />
      <ManagedCourseSelector onCourseSelected={setSelectedCourse} />
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
