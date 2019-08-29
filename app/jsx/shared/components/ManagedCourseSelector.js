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

import I18n from 'i18n!managed_course_selector'
import React, {useState} from 'react'
// import {func} from 'prop-types'

import Spinner from '@instructure/ui-elements/lib/components/Spinner'

import useManagedCourseSearchApi from '../effects/useManagedCourseSearchApi'

ManagedCourseSelector.propTypes = {
  // courseSelected: func // (course) => {} (see proptypes/course.js)
}

export default function ManagedCourseSelector() {
  const [courses, setCourses] = useState()
  const [error, setError] = useState()
  useManagedCourseSearchApi({success: setCourses, error: setError})

  // If there's an error, throw it to an ErrorBoundary
  if (error !== undefined) throw error

  // if we haven't found any courses, yet then we're loading
  if (courses === undefined) {
    return <Spinner title={I18n.t('Searching for courses...')} />
  }

  const courseElements = courses.map(course => <li key={course.id}>{course.name}</li>)
  return <ul>{courseElements}</ul>
}
