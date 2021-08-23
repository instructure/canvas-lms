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
import {Tabs} from '@instructure/ui-tabs'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import AnnouncementFactory from './AnnouncementFactory'
import I18n from 'i18n!past_global_announcements'

const PastGlobalAnnouncements = () => {
  const [selectedIndex, setSelectedIndex] = useState(0)
  const activeAnnouncements = AnnouncementFactory(ENV.global_notifications.current, 'Current')
  const pastAnnouncements = AnnouncementFactory(ENV.global_notifications.past, 'Past')

  return (
    <>
      <Tabs
        margin="0 auto"
        padding="medium"
        onRequestTabChange={(event, {index}) => {setSelectedIndex(index)}}
      >
        <Tabs.Panel
          id="currentTab"
          renderTitle={I18n.t('Current')}
          isSelected={selectedIndex === 0}
          data-testid="GlobalAnnouncementCurrentTab"
        >
          <View margin="0 0 small 0" display="block">
            <Text size="medium" lineHeight="double">
              {I18n.t('Active Announcements')}
            </Text>
          </View>
          {activeAnnouncements}
        </Tabs.Panel>
        <Tabs.Panel
          id="pastTab"
          renderTitle={I18n.t('Recent')}
          isSelected={selectedIndex === 1}
          data-testid="GlobalAnnouncementPastTab"
        >
          <View margin="0 0 small 0" display="block">
            <Text size="medium" lineHeight="double">
              {I18n.t('Announcements from the past four months')}
            </Text>
          </View>
          {pastAnnouncements}
        </Tabs.Panel>
      </Tabs>
    </>
  )
}

export default PastGlobalAnnouncements
