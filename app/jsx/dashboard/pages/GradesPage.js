/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
 *
 */

import React, {useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!k5_dashboard'

import {fetchGrades} from '../utils'
import {showFlashError} from 'jsx/shared/FlashAlert'
import {Spinner} from '@instructure/ui-spinner'
import GradesSummary from './GradesSummary'

export const GradesPage = ({visible}) => {
  const [courses, setCourses] = useState(null)
  const [loading, setLoading] = useState(false)

  const loadCourses = () => {
    setLoading(true)
    fetchGrades()
      .then(results => results.filter(c => !c.isHomeroom))
      .then(results => {
        setCourses(results)
        setLoading(false)
      })
      .catch(err => {
        showFlashError(I18n.t('Failed to load the grades tab'))(err)
        setLoading(false)
      })
  }
  useEffect(() => {
    if (!courses && visible) {
      loadCourses()
    }
  }, [courses, visible])

  return (
    <section
      id="dashboard_page_grades"
      style={{display: visible ? 'block' : 'none'}}
      aria-hidden={!visible}
    >
      {loading && <Spinner renderTitle={I18n.t('Loading grades...')} size="large" />}
      {courses && <GradesSummary courses={courses} loading={loading} />}
    </section>
  )
}

GradesPage.displayName = 'GradesPage'
GradesPage.propTypes = {
  visible: PropTypes.bool.isRequired
}

export default GradesPage
