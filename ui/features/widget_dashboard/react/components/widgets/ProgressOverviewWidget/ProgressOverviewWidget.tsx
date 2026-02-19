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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import CourseProgressItem from './CourseProgressItem'
import ProgressLegend from './ProgressLegend'
import {useProgressOverviewPaginated} from '../../../hooks/useProgressOverview'
import type {BaseWidgetProps} from '../../../types'

const I18n = createI18nScope('widget_dashboard')

const ProgressOverviewWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isEditMode = false,
  dragHandleProps,
}) => {
  const {
    data: courses,
    currentPageIndex,
    totalPages,
    goToPage,
    isLoading,
    error,
    refetch,
  } = useProgressOverviewPaginated()

  const hasNoCourses = !isLoading && !error && courses && courses.length === 0

  return (
    <TemplateWidget
      widget={widget}
      isEditMode={isEditMode}
      dragHandleProps={dragHandleProps}
      isLoading={isLoading}
      error={error ? I18n.t('Failed to load progress overview. Please try again.') : null}
      onRetry={refetch}
      loadingText={I18n.t('Loading progress overview...')}
      pagination={{
        currentPage: currentPageIndex + 1,
        totalPages,
        onPageChange: goToPage,
        isLoading,
        ariaLabel: I18n.t('Progress overview pagination'),
      }}
    >
      <>
        {hasNoCourses ? (
          <View as="div" padding="medium" textAlign="center">
            <Text size="medium" data-testid="no-courses-message">
              {I18n.t('No courses found')}
            </Text>
          </View>
        ) : (
          <View as="div">
            {courses?.map(course => (
              <CourseProgressItem key={course.courseId} course={course} />
            ))}
          </View>
        )}
        <View as="div" padding="small 0 0 small">
          <ProgressLegend />
        </View>
      </>
    </TemplateWidget>
  )
}

export default ProgressOverviewWidget
