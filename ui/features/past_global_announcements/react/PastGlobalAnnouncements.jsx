/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {Heading} from '@instructure/ui-heading'
import {Tabs} from '@instructure/ui-tabs'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import AnnouncementFactory from './AnnouncementFactory'
import {useScope as createI18nScope} from '@canvas/i18n'
import WithBreakpoints from '@canvas/with-breakpoints'
import TopNavPortalWithDefaults from '@canvas/top-navigation/react/TopNavPortalWithDefaults'

const I18n = createI18nScope('past_global_announcements')
const instUINavEnabled = () => window.ENV?.FEATURES?.instui_nav

const PastGlobalAnnouncements = ({breakpoints}) => {
  const [selectedIndex, setSelectedIndex] = useState(0)
  const activeAnnouncements = AnnouncementFactory(ENV.global_notifications.current, 'Current')
  const pastAnnouncements = AnnouncementFactory(ENV.global_notifications.past, 'Past')

  const renderTabs = () => {
    return (
      <Tabs
        margin="0 auto"
        padding="medium"
        onRequestTabChange={(_event, {index}) => setSelectedIndex(index)}
        data-testid="GlobalAnnouncementTabs"
      >
        <Tabs.Panel
          id="currentTab"
          renderTitle={I18n.t('Current')}
          isSelected={selectedIndex === 0}
          data-testid="GlobalAnnouncementCurrentTab"
        />
        <Tabs.Panel
          id="pastTab"
          renderTitle={I18n.t('Recent')}
          isSelected={selectedIndex === 1}
          data-testid="GlobalAnnouncementPastTab"
        />
      </Tabs>
    )
  }

  const renderSelect = () => {
    return (
      <Flex margin="medium 0">
        <Flex.Item width="100%">
          <SimpleSelect
            value={selectedIndex}
            onChange={(e, {_id, value}) => setSelectedIndex(value)}
            renderLabel={<ScreenReaderContent>{I18n.t('Select View')}</ScreenReaderContent>}
            margin="0 0 medium 0"
            data-testid="GlobalAnnouncementSelect"
          >
            <SimpleSelect.Group renderLabel="">
              <SimpleSelect.Option id="current_option" value={0}>
                {I18n.t('Current')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id="recent_option" value={1}>
                {I18n.t('Recent')}
              </SimpleSelect.Option>
            </SimpleSelect.Group>
          </SimpleSelect>
        </Flex.Item>
      </Flex>
    )
  }

  const renderTabContent = () => {
    const text =
      selectedIndex === 0
        ? I18n.t('Active Announcements')
        : I18n.t('Announcements from the past four months')
    const announcements = selectedIndex === 0 ? activeAnnouncements : pastAnnouncements

    return (
      <>
        <View margin="0 0 small 0" display="block">
          <Text size="medium" lineHeight="double">
            {text}
          </Text>
        </View>
        {announcements}
      </>
    )
  }
  const headerMargin = breakpoints.desktop ? '0 0 large 0' : '0 0 medium 0'

  return (
    <>
      {!instUINavEnabled() && (
        <>
          <Heading level="h1">
            <ScreenReaderContent>{I18n.t('Global Announcements')}</ScreenReaderContent>
          </Heading>
          {renderTabs()}
        </>
      )}
      {instUINavEnabled() && (
        <>
          <TopNavPortalWithDefaults />
          <Heading margin={headerMargin} as="h1" level={breakpoints.desktop ? 'h1' : 'h2'}>
            {I18n.t('Global Announcements')}
          </Heading>
          {breakpoints.mobileOnly ? renderSelect() : renderTabs()}
        </>
      )}
      {renderTabContent()}
    </>
  )
}

export default WithBreakpoints(PastGlobalAnnouncements)
