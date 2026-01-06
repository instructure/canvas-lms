/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {Table} from '@instructure/ui-table'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CoursesTableRow} from './CoursesTableRow'
import type {Course} from '../../types/course'

const I18n = createI18nScope('accessibility_course_statistics')

interface CoursesTableProps {
  courses: Course[]
}

export const CoursesTable: React.FC<CoursesTableProps> = ({courses}) => {
  const showSISIds = courses.some(course => course.sis_course_id)

  return (
    <Table margin="small 0" caption={I18n.t('Courses')}>
      <Table.Head>
        <Table.Row>
          <Table.ColHeader id="header-course-status">{I18n.t('Status')}</Table.ColHeader>
          <Table.ColHeader id="header-course-name">{I18n.t('Course')}</Table.ColHeader>
          {showSISIds && <Table.ColHeader id="header-sis-id">{I18n.t('SIS ID')}</Table.ColHeader>}
          <Table.ColHeader id="header-term">{I18n.t('Term')}</Table.ColHeader>
          <Table.ColHeader id="header-teacher">{I18n.t('Teacher')}</Table.ColHeader>
          <Table.ColHeader id="header-sub-account">{I18n.t('Sub-Account')}</Table.ColHeader>
          <Table.ColHeader id="header-students">{I18n.t('Students')}</Table.ColHeader>
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {courses.map(course => (
          <CoursesTableRow key={course.id} course={course} showSISIds={showSISIds} />
        ))}
      </Table.Body>
    </Table>
  )
}
