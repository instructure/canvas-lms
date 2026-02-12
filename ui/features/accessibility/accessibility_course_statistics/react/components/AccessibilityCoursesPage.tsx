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
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Billboard} from '@instructure/ui-billboard'
import {Pagination} from '@instructure/ui-pagination'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useCourses} from '../../hooks/useCourses'
import {useCoursesParams} from '../../hooks/useCoursesParams'
import {CoursesTable} from './CoursesTable'
import {CoursesSearch} from './CoursesSearch'
import {useAccessibilityIssueSummary} from '../../hooks/useAccessibilityIssueSummary'
import {AccessibilityGenericErrorPage} from './AccessibilityGenericErrorPage'
import EmptyDesert from '@canvas/images/react/EmptyDesert'
import type {CoursesResponse} from '../../types/course'
import type {SortOrder} from './SortableTableHeader'
import {Flex} from '@instructure/ui-flex'
import {IssueStatusBarChart} from '../../../shared/react/components/BarChart'

const I18n = createI18nScope('accessibility_course_statistics')

const getAccountId = (): string => {
  return window.ENV?.ACCOUNT_ID?.toString() || ''
}

const LoadingState: React.FC = () => (
  <View as="div" textAlign="center" padding="large">
    <Spinner renderTitle={I18n.t('Loading courses')} />
  </View>
)

const EmptyState: React.FC = () => (
  <Billboard
    size="large"
    heading={I18n.t('No courses found')}
    headingAs="h2"
    hero={<EmptyDesert />}
  />
)

const CoursesContent: React.FC<{
  isLoading: boolean
  isError: boolean
  data: CoursesResponse | undefined
  sort: string
  order: SortOrder
  onChangeSort: (columnId: string) => void
}> = ({isLoading, isError, data, sort, order, onChangeSort}) => {
  if (isError) {
    return <AccessibilityGenericErrorPage />
  }

  if (isLoading && !data) {
    return <LoadingState />
  }

  if (!data || data.courses.length === 0) {
    return <EmptyState />
  }

  return (
    <CoursesTable courses={data.courses} sort={sort} order={order} onChangeSort={onChangeSort} />
  )
}

const CoursesPagination: React.FC<{
  currentPage: number
  pageCount?: number
  onPageChange: (page: number) => void
}> = ({currentPage, pageCount, onPageChange}) => {
  if (!pageCount || pageCount <= 1) {
    return null
  }

  return (
    <Pagination
      data-testid="courses-pagination"
      as="nav"
      variant="compact"
      labelNext={I18n.t('Next Page')}
      labelPrev={I18n.t('Previous Page')}
      margin="small"
      currentPage={currentPage}
      onPageChange={onPageChange}
      totalPageNumber={pageCount}
    />
  )
}

export const AccessibilityCoursesPage: React.FC = () => {
  const accountId = getAccountId()
  const {sort, order, page, search, handleChangeSort, handlePageChange, handleSearchChange} =
    useCoursesParams({
      defaultSort: 'course_name',
      defaultOrder: 'asc',
    })
  const {data, isLoading, isError} = useCourses({accountId, sort, order, page, search})
  const {data: issueSummary} = useAccessibilityIssueSummary({accountId})

  return (
    <View as="div">
      <Heading level="h1" margin="0 0 medium">
        {I18n.t('Accessibility report')}
      </Heading>

      <CoursesSearch value={search} onChange={handleSearchChange} />

      <Flex>
        <IssueStatusBarChart
          open={issueSummary?.active ?? 0}
          resolved={issueSummary?.resolved ?? 0}
        />
      </Flex>

      <CoursesContent
        isLoading={isLoading}
        isError={isError}
        data={data}
        sort={sort}
        order={order}
        onChangeSort={handleChangeSort}
      />

      <CoursesPagination
        currentPage={page}
        pageCount={data?.pageCount}
        onPageChange={handlePageChange}
      />
    </View>
  )
}
