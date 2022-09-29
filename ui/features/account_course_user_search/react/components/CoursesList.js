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
import {useScope as useI18nScope} from '@canvas/i18n'
import CoursesListRow from './CoursesListRow'
import CoursesListHeader from './CoursesListHeader'
import {Table} from '@instructure/ui-table'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('account_course_user_search')

export default function CoursesList(props) {
  // The 'sis_course_id' field is only included in the api response if the user has
  // permission to view SIS information. So if it isn't, we can hide that column
  const showSISIds = !props.courses || props.courses.some(c => 'sis_course_id' in c)

  return (
    <Table margin="small 0" caption={I18n.t('Courses')}>
      <Table.Head>
        <Table.Row>
          <Table.ColHeader id="header-published" width="1">
            {I18n.t('Published')}
          </Table.ColHeader>
          <Table.ColHeader id="header-course-name">
            <CoursesListHeader
              {...props}
              id="course_name"
              label={I18n.t('Course')}
              tipDesc={I18n.t('Click to sort by name ascending')}
              tipAsc={I18n.t('Click to sort by name descending')}
            />
          </Table.ColHeader>
          {showSISIds && (
            <Table.ColHeader id="header-sis-id">
              <CoursesListHeader
                {...props}
                id="sis_course_id"
                label={I18n.t('SIS ID')}
                tipDesc={I18n.t('Click to sort by SIS ID ascending')}
                tipAsc={I18n.t('Click to sort by SIS ID descending')}
              />
            </Table.ColHeader>
          )}
          <Table.ColHeader id="header-term">
            <CoursesListHeader
              {...props}
              id="term"
              label={I18n.t('Term')}
              tipDesc={I18n.t('Click to sort by term ascending')}
              tipAsc={I18n.t('Click to sort by term descending')}
            />
          </Table.ColHeader>
          <Table.ColHeader id="header-teacher">
            <CoursesListHeader
              {...props}
              id="teacher"
              label={I18n.t('Teacher')}
              tipDesc={I18n.t('Click to sort by teacher ascending')}
              tipAsc={I18n.t('Click to sort by teacher descending')}
            />
          </Table.ColHeader>
          <Table.ColHeader id="header-sub-account">
            <CoursesListHeader
              {...props}
              id="subaccount"
              label={I18n.t('Sub-Account')}
              tipDesc={I18n.t('Click to sort by sub-account ascending')}
              tipAsc={I18n.t('Click to sort by sub-account descending')}
            />
          </Table.ColHeader>
          <Table.ColHeader id="header-students" width="1">
            {I18n.t('Students')}
          </Table.ColHeader>
          <Table.ColHeader id="header-option-links" width="1">
            <ScreenReaderContent>{I18n.t('Course option links')}</ScreenReaderContent>
          </Table.ColHeader>
        </Table.Row>
      </Table.Head>
      <Table.Body data-automation="courses list">
        {(props.courses || []).map(course => (
          <CoursesListRow
            key={course.id}
            courseModel={props.courses}
            roles={props.roles}
            showSISIds={showSISIds}
            {...course}
          />
        ))}
      </Table.Body>
    </Table>
  )
}

CoursesList.propTypes = {
  courses: arrayOf(shape(CoursesListRow.propTypes)).isRequired,
  onChangeSort: func.isRequired,
  roles: arrayOf(shape({id: string.isRequired})),
  sort: string,
  order: string,
}

CoursesList.defaultProps = {
  sort: 'sis_course_id',
  order: 'asc',
  roles: [],
}
