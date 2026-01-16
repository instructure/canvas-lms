/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import {GradeItem} from './GradeItem'
import CourseFilterSelect from '../../shared/CourseFilterSelect'
import type {BaseWidgetProps} from '../../../types'
import {useRecentGrades} from '../../../hooks/useRecentGrades'

const I18n = createI18nScope('widget_dashboard')

const ITEMS_PER_PAGE = 5

const RecentGradesWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isLoading: isLoadingProp = false,
  error: errorProp = null,
  onRetry,
  isEditMode = false,
  dragHandleProps,
}) => {
  const [selectedCourse, setSelectedCourse] = useState<string>('all')

  const {
    currentPage,
    currentPageIndex,
    totalPages,
    goToPage,
    isLoading: isLoadingData,
    error: errorData,
    refetch,
  } = useRecentGrades({
    pageSize: ITEMS_PER_PAGE,
    courseFilter: selectedCourse === 'all' ? undefined : selectedCourse,
  })

  // External props take precedence over internal query state
  const error = errorProp || (errorData ? errorData.message : null)
  const isLoading = errorProp ? false : isLoadingProp || isLoadingData

  const currentSubmissions = currentPage?.submissions || []

  const handlePageChange = (page: number) => {
    goToPage(page)
  }

  const handleCourseChange = (
    _event: React.SyntheticEvent,
    data: {value?: string | number; id?: string},
  ) => {
    setSelectedCourse(data.value as string)
  }

  const handleRetry = () => {
    if (onRetry) {
      onRetry()
    } else {
      refetch()
    }
  }

  const paginationProps = {
    currentPage: currentPageIndex + 1,
    totalPages,
    onPageChange: handlePageChange,
    ariaLabel: I18n.t('Recent grades pagination'),
  }

  return (
    <TemplateWidget
      widget={widget}
      isEditMode={isEditMode}
      dragHandleProps={dragHandleProps}
      isLoading={isLoading}
      error={error}
      onRetry={handleRetry}
      loadingText={I18n.t('Loading recent grades...')}
      pagination={paginationProps}
      footerActions={
        <View as="div" textAlign="center">
          <Link href="/grades" isWithinText={false} data-testid="view-all-grades-link">
            {I18n.t('View all grades')}
          </Link>
        </View>
      }
    >
      <View as="div" padding="0 0 small 0">
        <CourseFilterSelect
          selectedCourse={selectedCourse}
          onChange={handleCourseChange}
          disabled={isLoading}
        />
      </View>
      <View as="div" data-testid="recent-grades-list">
        {currentSubmissions.length > 0 ? (
          currentSubmissions.map(submission => (
            <GradeItem key={submission._id} submission={submission} />
          ))
        ) : (
          <View as="div" textAlign="center" padding="large">
            {I18n.t('No recent grades available')}
          </View>
        )}
      </View>
    </TemplateWidget>
  )
}

export default RecentGradesWidget
