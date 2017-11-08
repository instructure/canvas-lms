/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React from 'react'
import {string, shape, arrayOf, func} from 'prop-types'
import I18n from 'i18n!account_course_user_search'
import CoursesListRow from './CoursesListRow'
import CoursesListHeader from './CoursesListHeader'

export default function CoursesList(props) {
  // if none of the corses have an SIS ID, we don't need to show that column
  const showSISIds = props.courses && props.courses.some(c => c.sis_course_id)

  return (
    <div className="content-box" role="grid">
      <div role="row" className="grid-row border border-b pad-box-mini">
        <div className="col-xs-3">
          <div className="grid-row">
            <div className="col-xs-2" />
            <div className="col-xs-10" role="columnheader">
              <CoursesListHeader
                {...props}
                id="course_name"
                label={I18n.t('Course')}
                tipDesc={I18n.t('Click to sort by name ascending')}
                tipAsc={I18n.t('Click to sort by name descending')}
              />
            </div>
          </div>
        </div>
        {showSISIds &&
          <div role="columnheader" className="col-xs-1">
            <CoursesListHeader
              {...props}
              id="sis_course_id"
              label={I18n.t('SIS ID')}
              tipDesc={I18n.t('Click to sort by SIS ID ascending')}
              tipAsc={I18n.t('Click to sort by SIS ID descending')}
            />
          </div>
        }
        <div role="columnheader" className={`col-xs-${showSISIds ? 1 : 2}`}>
          <CoursesListHeader
            {...props}
            id="term"
            label={I18n.t('Term')}
            tipDesc={I18n.t('Click to sort by term ascending')}
            tipAsc={I18n.t('Click to sort by term descending')}
          />
        </div>
        <div role="columnheader" className="col-xs-2">
          <CoursesListHeader
            {...props}
            id="teacher"
            label={I18n.t('Teacher')}
            tipDesc={I18n.t('Click to sort by teacher ascending')}
            tipAsc={I18n.t('Click to sort by teacher descending')}
          />
        </div>
        <div role="columnheader" className="col-xs-2">
          <CoursesListHeader
            {...props}
            id="subaccount"
            label={I18n.t('Sub-Account')}
            tipDesc={I18n.t('Click to sort by sub-account ascending')}
            tipAsc={I18n.t('Click to sort by sub-account descending')}
          />
        </div>
        <div role="columnheader" className="col-xs-2">
          <CoursesListHeader
            {...props}
            id="enrollments"
            label={I18n.t('Enrollments')}
            tipDesc={I18n.t('Click to sort by enrollments ascending')}
            tipAsc={I18n.t('Click to sort by enrollments descending')}
          />
        </div>
        <div role="columnheader" className="col-xs-1">
          <span className="screenreader-only">{I18n.t('Course option links')}</span>
        </div>
      </div>

      <div className="courses-list" role="rowgroup">
        {(props.courses || []).map(course =>
          <CoursesListRow
            key={course.id}
            courseModel={props.courses}
            roles={props.roles}
            showSISIds={showSISIds}
            {...course}
          />
        )}
      </div>
    </div>
  )
}

CoursesList.propTypes = {
  courses: arrayOf(shape(CoursesListRow.propTypes)).isRequired,
  onChangeSort: func.isRequired,
  roles: arrayOf(shape({id: string.isRequired})),
  sort: string,
  order: string
}

CoursesList.defaultProps = {
  sort: 'sis_course_id',
  order: 'asc',
  roles: []
}
