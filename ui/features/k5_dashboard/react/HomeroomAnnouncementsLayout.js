/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import I18n from 'i18n!homeroom_announcements_layout'
import {array, bool} from 'prop-types'

import {View} from '@instructure/ui-view'

import K5Announcement from '@canvas/k5/react/K5Announcement'
import EmptyHomeroomAnnouncement from './EmptyHomeroomAnnouncement'
import LoadingSkeleton from '@canvas/k5/react/LoadingSkeleton'
import LoadingWrapper from '@canvas/k5/react/LoadingWrapper'

export default function HomeroomAnnouncementsLayout({homeroomAnnouncements, loading}) {
  const loadingMask = props => (
    <div {...props}>
      <LoadingSkeleton
        screenReaderLabel={I18n.t('Loading Homeroom Course Name')}
        margin="medium 0 small"
        width="20em"
        height="1.5em"
      />
      <LoadingSkeleton
        screenReaderLabel={I18n.t('Loading Homeroom Announcement Title')}
        margin="small 0"
        width="15em"
        height="1.5em"
      />
      <LoadingSkeleton
        screenReaderLabel={I18n.t('Loading Homeroom Announcement Content')}
        margin="small 0"
        width="100%"
        height="8em"
      />
    </div>
  )

  return (
    <LoadingWrapper
      id="homeroom-announcements"
      isLoading={loading}
      renderCustomSkeleton={loadingMask}
      skeletonsNum={homeroomAnnouncements?.filter(h => h.announcement || h.canEdit)?.length} // if there is no homeroom course set, this loading mask shouldn't appear
    >
      <View>
        {homeroomAnnouncements?.map(homeroom => {
          if (homeroom.announcement) {
            return (
              <View key={homeroom.courseId}>
                <K5Announcement
                  courseName={homeroom.courseName}
                  courseUrl={homeroom.courseUrl}
                  canEdit={homeroom.canEdit}
                  title={homeroom.announcement.title}
                  message={homeroom.announcement.message}
                  url={homeroom.announcement.url}
                  attachment={homeroom.announcement.attachment}
                  published={homeroom.published}
                  showCourseDetails
                />
              </View>
            )
          } else if (homeroom.canEdit) {
            return (
              <View key={homeroom.courseId}>
                <EmptyHomeroomAnnouncement {...homeroom} />
              </View>
            )
          }
          return null
        })}
      </View>
    </LoadingWrapper>
  )
}

HomeroomAnnouncementsLayout.propTypes = {
  homeroomAnnouncements: array.isRequired,
  loading: bool.isRequired
}
