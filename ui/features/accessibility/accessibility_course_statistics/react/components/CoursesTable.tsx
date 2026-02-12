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
import {SortableTableHeader, type SortOrder} from './SortableTableHeader'
import type {Course} from '../../types/course'

const I18n = createI18nScope('accessibility_course_statistics')

interface CoursesTableProps {
  courses: Course[]
  sort?: string
  order?: SortOrder
  onChangeSort: (columnId: string) => void
}

export const CoursesTable: React.FC<CoursesTableProps> = ({
  courses,
  sort = 'course_name',
  order = 'asc',
  onChangeSort,
}) => {
  const showSISIds = courses.some(course => course.sis_course_id)

  return (
    <Table margin="small 0" caption={I18n.t('Courses')}>
      <Table.Head>
        <Table.Row>
          <Table.ColHeader id="header-course-status">
            <SortableTableHeader
              id="course_status"
              label={I18n.t('Status')}
              tipDesc={I18n.t('Click to sort by status ascending')}
              tipAsc={I18n.t('Click to sort by status descending')}
              currentSort={sort}
              currentOrder={order}
              onChangeSort={onChangeSort}
            />
          </Table.ColHeader>
          <Table.ColHeader id="header-course-name">
            <SortableTableHeader
              id="course_name"
              label={I18n.t('Course')}
              tipDesc={I18n.t('Click to sort by name ascending')}
              tipAsc={I18n.t('Click to sort by name descending')}
              currentSort={sort}
              currentOrder={order}
              onChangeSort={onChangeSort}
            />
          </Table.ColHeader>
          <Table.ColHeader id="header-active-issue-count">
            <SortableTableHeader
              id="a11y_active_issue_count"
              label={I18n.t('Issues')}
              tipDesc={I18n.t('Click to sort by issue count ascending')}
              tipAsc={I18n.t('Click to sort by issue count descending')}
              currentSort={sort}
              currentOrder={order}
              onChangeSort={onChangeSort}
            />
          </Table.ColHeader>
          <Table.ColHeader id="header-resolved-issue-count">
            <SortableTableHeader
              id="a11y_resolved_issue_count"
              label={I18n.t('Resolved')}
              tipDesc={I18n.t('Click to sort by resolved issue count ascending')}
              tipAsc={I18n.t('Click to sort by resolved issue count descending')}
              currentSort={sort}
              currentOrder={order}
              onChangeSort={onChangeSort}
            />
          </Table.ColHeader>
          {showSISIds && (
            <Table.ColHeader id="header-sis-id">
              <SortableTableHeader
                id="sis_course_id"
                label={I18n.t('SIS ID')}
                tipDesc={I18n.t('Click to sort by SIS ID ascending')}
                tipAsc={I18n.t('Click to sort by SIS ID descending')}
                currentSort={sort}
                currentOrder={order}
                onChangeSort={onChangeSort}
              />
            </Table.ColHeader>
          )}
          <Table.ColHeader id="header-term">
            <SortableTableHeader
              id="term"
              label={I18n.t('Term')}
              tipDesc={I18n.t('Click to sort by term ascending')}
              tipAsc={I18n.t('Click to sort by term descending')}
              currentSort={sort}
              currentOrder={order}
              onChangeSort={onChangeSort}
            />
          </Table.ColHeader>
          <Table.ColHeader id="header-teacher">
            <SortableTableHeader
              id="teacher"
              label={I18n.t('Teacher')}
              tipDesc={I18n.t('Click to sort by teacher ascending')}
              tipAsc={I18n.t('Click to sort by teacher descending')}
              currentSort={sort}
              currentOrder={order}
              onChangeSort={onChangeSort}
            />
          </Table.ColHeader>
          <Table.ColHeader id="header-sub-account">
            <SortableTableHeader
              id="subaccount"
              label={I18n.t('Sub-Account')}
              tipDesc={I18n.t('Click to sort by sub-account ascending')}
              tipAsc={I18n.t('Click to sort by sub-account descending')}
              currentSort={sort}
              currentOrder={order}
              onChangeSort={onChangeSort}
            />
          </Table.ColHeader>
          <Table.ColHeader id="header-students" width="1">
            {I18n.t('Students')}
          </Table.ColHeader>
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
