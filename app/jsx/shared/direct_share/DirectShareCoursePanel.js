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
import {func} from 'prop-types'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-layout'

import ManagedCourseSelector from '../components/ManagedCourseSelector'

// eventually this will have options for where to place the item in the new course.
// for now, it just has the selector plus some buttons

DirectShareCoursePanel.propTypes = {
  onStart: func, // (course)
  onCancel: func
}

export default function DirectShareCoursePanel(props) {
  const [selectedCourse, setSelectedCourse] = useState(null)

  function handleStart() {
    if (props.onStart) props.onStart(selectedCourse)
    console.log('TODO: start copy on course', selectedCourse)
  }

  return (
    <>
      <ManagedCourseSelector onCourseSelected={setSelectedCourse} />
      <Flex justifyItems="end" padding="small 0 0 0">
        <Flex.Item>
          <Button variant="primary" disabled={selectedCourse === null} onClick={handleStart}>
            {I18n.t('Copy')}
          </Button>
          <Button margin="0 0 0 x-small" onClick={props.onCancel}>
            {I18n.t('Cancel')}
          </Button>
        </Flex.Item>
      </Flex>
    </>
  )
}
