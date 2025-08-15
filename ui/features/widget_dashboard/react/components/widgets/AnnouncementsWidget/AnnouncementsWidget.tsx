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

import React, {useState, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {SimpleSelect} from '@instructure/ui-simple-select'
import TemplateWidget from '../TemplateWidget/TemplateWidget'
import AnnouncementItem from './AnnouncementItem'
import type {BaseWidgetProps} from '../../../types'
import {useAnnouncements} from '../../../hooks/useAnnouncements'

const I18n = createI18nScope('widget_dashboard')

type FilterOption = 'unread' | 'read' | 'all'

const AnnouncementsWidget: React.FC<BaseWidgetProps> = ({widget}) => {
  const [filter, setFilter] = useState<FilterOption>('unread')
  const {data: announcements = [], isLoading, error, refetch} = useAnnouncements({limit: 8})

  // Filter announcements based on read status
  const filteredAnnouncements = useMemo(() => {
    if (filter === 'all') return announcements
    if (filter === 'unread') return announcements.filter(a => !a.isRead)
    if (filter === 'read') return announcements.filter(a => a.isRead)
    return announcements
  }, [announcements, filter])

  const renderFilterSelect = () => (
    <SimpleSelect
      renderLabel=""
      value={filter}
      onChange={(_event, {value}) => setFilter(value as FilterOption)}
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
    if (filteredAnnouncements.length === 0) {
      const message =
        announcements.length === 0
          ? I18n.t('No recent announcements')
          : filter === 'unread'
            ? I18n.t('No unread announcements')
            : filter === 'read'
              ? I18n.t('No read announcements')
              : I18n.t('No announcements')

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
        {filteredAnnouncements.map(announcement => (
          <AnnouncementItem key={announcement.id} announcement={announcement} />
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
    >
      <View as="div" margin="0 0 small 0">
        {renderFilterSelect()}
      </View>
      {renderContent()}
    </TemplateWidget>
  )
}

export default AnnouncementsWidget
