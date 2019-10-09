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

import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-layout'
import {Spinner} from '@instructure/ui-elements'

import doFetchApi from 'jsx/shared/effects/doFetchApi'
import contentSelectionShape from 'jsx/shared/proptypes/contentSelection'
import ManagedCourseSelector from '../components/ManagedCourseSelector'

// eventually this will have options for where to place the item in the new course.
// for now, it just has the selector plus some buttons

DirectShareCoursePanel.propTypes = {
  sourceCourseId: string,
  contentSelection: contentSelectionShape,
  onCancel: func
}

function getLiveRegion() {
  return document.querySelector('#flash_screenreader_holder')
}

export default function DirectShareCoursePanel({sourceCourseId, contentSelection, onCancel}) {
  const [selectedCourse, setSelectedCourse] = useState(null)
  const [postStatus, setPostStatus] = useState(null)

  function startCopyOperation() {
    return doFetchApi({
      method: 'POST',
      path: `/api/v1/courses/${selectedCourse.id}/content_migrations`,
      body: {
        migration_type: 'course_copy_importer',
        select: contentSelection,
        settings: {source_course_id: sourceCourseId}
      },
    })
  }


  function handleStart() {
    setPostStatus('starting')
    startCopyOperation()
    .then(() => {
      setPostStatus('success')
    })
    .catch(err => {
      console.error(err) // eslint-disable-line no-console
      if (err.response) console.error(err.response) // eslint-disable-line no-console
      setPostStatus('error')
    })
  }

  let alert = null
  const alertProps = {
    margin: 'small 0',
    liveRegion: getLiveRegion
  }
  if (postStatus === 'error') {
    alert = (
      <Alert variant="error" {...alertProps}>
        {I18n.t('There was a problem starting the copy operation')}
      </Alert>
    )
  } else if (postStatus === 'success') {
    alert = (
      <Alert variant="success" {...alertProps}>
        {I18n.t('Copy operation started successfully')}
      </Alert>
    )
  } else if (postStatus === 'starting') {
    alert = (
      <Alert variant="info" {...alertProps}>
        {I18n.t('Starting copy operation')}
        <Spinner renderTitle="" size="x-small" />
      </Alert>
    )
  }

  const copyButtonDisabled = selectedCourse === null || postStatus !== null

  return (
    <>
      {alert}
      <ManagedCourseSelector onCourseSelected={setSelectedCourse} />
      <Flex justifyItems="end" padding="small 0 0 0">
        <Flex.Item>
          <Button variant="primary" disabled={copyButtonDisabled} onClick={handleStart}>
            {I18n.t('Copy')}
          </Button>
          <Button margin="0 0 0 x-small" onClick={onCancel}>
            {I18n.t('Cancel')}
          </Button>
        </Flex.Item>
      </Flex>
    </>
  )
}
