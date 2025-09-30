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

import React, {useState, useEffect, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import AnnouncementItem from './AnnouncementItem'
import type {BaseWidgetProps, Announcement} from '../../../types'
import {usePaginatedAnnouncements} from '../../../hooks/useAnnouncements'
import {usePagination} from '../../../hooks/usePagination'
import {useWidgetDashboard} from '../../../hooks/useWidgetDashboardContext'
import {FilterOption} from './utils'

const I18n = createI18nScope('widget_dashboard')

const AnnouncementsWidget: React.FC<BaseWidgetProps> = ({widget}) => {
  const [filter, setFilter] = useState<FilterOption>('unread')

  const {data, fetchNextPage, hasNextPage, isLoading, error, refetch} = usePaginatedAnnouncements({
    limit: 3,
    filter,
  })

  const {currentPageIndex, paginationProps, resetPagination} = usePagination({
    hasNextPage: !!hasNextPage,
    totalPagesLoaded: data?.pages?.length || 0,
    fetchNextPage,
  })

  useEffect(() => {
    resetPagination()
  }, [filter, resetPagination])

  const handleFilterChange = (newFilter: FilterOption) => {
    setFilter(newFilter)
  }

  const {sharedCourseData} = useWidgetDashboard()

  const enrichedAnnouncements = useMemo(() => {
    const currentPageData = data?.pages[currentPageIndex] as
      | {announcements: Announcement[]}
      | undefined
    const filteredAnnouncements = currentPageData?.announcements || []

    return filteredAnnouncements.map(announcement => {
      if (!announcement.course) return announcement

      const courseId = announcement.course.id
      const matchedCourse = sharedCourseData.find(
        course => course.courseId === courseId || course.courseId === String(courseId),
      )

      return {
        ...announcement,
        course: {
          ...announcement.course,
          courseCode: matchedCourse?.courseCode || undefined,
        },
      }
    })
  }, [data?.pages, currentPageIndex, sharedCourseData])

  const renderFilterSelect = () => (
    <SimpleSelect
      renderLabel={
        <ScreenReaderContent>{I18n.t('Filter announcements by read status')}</ScreenReaderContent>
      }
      value={filter}
      onChange={(_event, {value}) => handleFilterChange(value as FilterOption)}
      size="small"
      width="6rem"
    >
      <SimpleSelect.Option id="unread" value="unread">
        {I18n.t('Unread')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="read" value="read">
        {I18n.t('Read')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="all" value="all">
        {I18n.t('All')}
      </SimpleSelect.Option>
    </SimpleSelect>
  )

  const renderContent = () => {
    if (enrichedAnnouncements.length === 0) {
      const message =
        filter === 'unread'
          ? I18n.t('No unread announcements')
          : filter === 'read'
            ? I18n.t('No read announcements')
            : I18n.t('No recent announcements')

      return (
        <View as="div" margin="large 0">
          <Text color="secondary" size="medium">
            {message}
          </Text>
        </View>
      )
    }

    return (
      <View as="div" height="100%" width="100%">
        {enrichedAnnouncements.map(announcement => (
          <AnnouncementItem
            key={`${announcement.id}-${announcement.isRead ? 'read' : 'unread'}`}
            announcementItem={announcement}
            filter={filter}
          />
        ))}
      </View>
    )
  }

  return (
    <TemplateWidget
      widget={widget}
      isLoading={isLoading}
      error={error ? I18n.t('Failed to load announcements. Please try again.') : null}
      onRetry={refetch}
      loadingText={I18n.t('Loading announcements...')}
      headerActions={renderFilterSelect()}
      pagination={{
        ...paginationProps,
        ariaLabel: I18n.t('Announcements pagination'),
      }}
    >
      {renderContent()}
    </TemplateWidget>
  )
}

export default AnnouncementsWidget
