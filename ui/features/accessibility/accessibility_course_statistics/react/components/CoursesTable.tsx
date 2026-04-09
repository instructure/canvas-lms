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
import {Responsive} from '@instructure/ui-responsive'
import {Tooltip} from '@instructure/ui-tooltip'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {responsiveQuerySizes} from '@canvas/breakpoints'
import {CoursesTableRow} from './CoursesTableRow'
import type {Course, SortOrder} from '../../types/course'

const I18n = createI18nScope('accessibility_course_statistics')

interface CoursesTableProps {
  courses: Course[]
  sort?: string
  order?: SortOrder
  onChangeSort: (columnId: string) => void
}

function sortDirection(
  columnId: string,
  currentSort: string,
  currentOrder: SortOrder,
): 'ascending' | 'descending' | 'none' {
  if (currentSort !== columnId) return 'none'
  return currentOrder === 'asc' ? 'ascending' : 'descending'
}

function sortTip(
  columnId: string,
  label: string,
  currentSort: string,
  currentOrder: SortOrder,
): string {
  const isActive = currentSort === columnId
  const nextOrder = isActive && currentOrder === 'asc' ? 'descending' : 'ascending'
  return I18n.t('Click to sort by %{label} %{order}', {label, order: nextOrder})
}

const SortLabel: React.FC<{tip: string; label: string}> = ({tip, label}) => (
  <Tooltip renderTip={tip}>
    <Link as="span" isWithinText={false} display="inline-flex">
      <Text weight="bold">{label}</Text>
    </Link>
  </Tooltip>
)

export const CoursesTable: React.FC<CoursesTableProps> = ({
  courses,
  sort = 'course_name',
  order = 'asc',
  onChangeSort,
}) => {
  const showSISIds = courses.some(course => course.sis_course_id)

  const colHeader = (id: string, label: string, isMobile: boolean) => (
    <Table.ColHeader
      id={id}
      sortDirection={sortDirection(id, sort, order)}
      onRequestSort={() => onChangeSort(id)}
      stackedSortByLabel={label}
    >
      {isMobile ? (
        <Text weight="bold">{label}</Text>
      ) : (
        <SortLabel tip={sortTip(id, label, sort, order)} label={label} />
      )}
    </Table.ColHeader>
  )

  return (
    <Responsive
      query={responsiveQuerySizes({mobile: true, tablet: true, desktop: true})}
      props={{
        mobile: {isMobile: true},
        tablet: {isMobile: false},
        desktop: {isMobile: false},
      }}
    >
      {props => {
        const isMobile = props?.isMobile ?? false
        return (
          <Table
            margin="small 0"
            caption={I18n.t('Course Accessibility Report')}
            layout={isMobile ? 'stacked' : 'auto'}
          >
            <Table.Head renderSortLabel={I18n.t('Sort by')}>
              <Table.Row>
                {colHeader('course_status', I18n.t('Status'), isMobile)}
                {colHeader('course_name', I18n.t('Course'), isMobile)}
                {colHeader('a11y_active_issue_count', I18n.t('Issues'), isMobile)}
                {colHeader('a11y_resolved_issue_count', I18n.t('Resolved'), isMobile)}
                {showSISIds && colHeader('sis_course_id', I18n.t('SIS ID'), isMobile)}
                {colHeader('term', I18n.t('Term'), isMobile)}
                {colHeader('teacher', I18n.t('Teacher'), isMobile)}
                {colHeader('subaccount', I18n.t('Sub-Account'), isMobile)}
                <Table.ColHeader id="students" width="1">
                  <Text weight="bold">{I18n.t('Students')}</Text>
                </Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {courses.map(course => (
                <CoursesTableRow
                  key={course.id}
                  course={course}
                  showSISIds={showSISIds}
                  isMobile={isMobile}
                />
              ))}
            </Table.Body>
          </Table>
        )
      }}
    </Responsive>
  )
}
