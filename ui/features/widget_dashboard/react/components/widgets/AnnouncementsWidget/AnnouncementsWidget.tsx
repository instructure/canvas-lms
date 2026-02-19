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

import React, {useEffect, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {List} from '@instructure/ui-list'
import {SimpleSelect} from '@instructure/ui-simple-select'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import AnnouncementItem from './AnnouncementItem'
import type {BaseWidgetProps, Announcement} from '../../../types'
import {useAnnouncementsPaginated} from '../../../hooks/useAnnouncements'
import {useWidgetDashboard} from '../../../hooks/useWidgetDashboardContext'
import {FilterOption} from './utils'
import {useWidgetConfig} from '../../../hooks/useWidgetConfig'

const I18n = createI18nScope('widget_dashboard')

const AnnouncementsWidget: React.FC<BaseWidgetProps> = ({
  widget,
  isEditMode = false,
  dragHandleProps,
}) => {
  const {sharedCourseData} = useWidgetDashboard()

  const [filter, setFilter] = useWidgetConfig<FilterOption>(widget.id, 'filter', 'unread')

  const {
    currentPage,
    currentPageIndex,
    totalPages,
    goToPage,
    resetPagination,
    isLoading,
    error,
    refetch,
  } = useAnnouncementsPaginated({
    limit: 3,
    filter,
  })

  useEffect(() => {
    resetPagination()
  }, [filter, resetPagination])

  const handleFilterChange = (newFilter: FilterOption) => {
    setFilter(newFilter)
  }

  const enrichedAnnouncements = useMemo(() => {
    const filteredAnnouncements = currentPage?.announcements || []

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
  }, [currentPage, sharedCourseData])

  const renderFilterSelect = () => (
    <SimpleSelect
      renderLabel={I18n.t('Read filter:')}
      value={filter}
      onChange={(_event, {value}) => handleFilterChange(value as FilterOption)}
      size="small"
      width="7rem"
      data-testid="announcement-filter-select"
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
          <Text color="secondary" size="medium" data-testid="no-announcements-message">
            {message}
          </Text>
        </View>
      )
    }

    return (
      <View as="div">
        <List isUnstyled margin="0">
          {enrichedAnnouncements.map(announcement => (
            <List.Item
              key={`${announcement.id}-${announcement.isRead ? 'read' : 'unread'}`}
              margin="0"
            >
              <AnnouncementItem announcementItem={announcement} filter={filter} />
            </List.Item>
          ))}
        </List>
      </View>
    )
  }

  return (
    <TemplateWidget
      widget={widget}
      isEditMode={isEditMode}
      dragHandleProps={dragHandleProps}
      isLoading={isLoading}
      error={error ? I18n.t('Failed to load announcements. Please try again.') : null}
      onRetry={refetch}
      loadingText={I18n.t('Loading announcements...')}
      pagination={{
        currentPage: currentPageIndex + 1,
        totalPages,
        onPageChange: goToPage,
        isLoading,
        ariaLabel: I18n.t('Announcements pagination'),
      }}
    >
      <Flex direction="column" gap="small">
        <Flex.Item overflowX="visible" overflowY="visible">
          {renderFilterSelect()}
        </Flex.Item>
        <Flex.Item overflowY="visible" shouldGrow>
          {renderContent()}
        </Flex.Item>
      </Flex>
    </TemplateWidget>
  )
}

export default AnnouncementsWidget
