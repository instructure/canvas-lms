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
import {array} from 'prop-types'
import HomeroomAnnouncement from './HomeroomAnnouncement'
import EmptyHomeroomAnnouncement from './EmptyHomeroomAnnouncement'
import {View} from '@instructure/ui-view'

export default function HomeroomAnnouncementsLayout({homeroomAnnouncements}) {
  return (
    <View>
      {homeroomAnnouncements?.length > 0 &&
        homeroomAnnouncements.map(homeroom => {
          if (homeroom.announcement) {
            return (
              <View key={homeroom.courseId}>
                <HomeroomAnnouncement
                  courseName={homeroom.courseName}
                  courseUrl={homeroom.courseUrl}
                  canEdit={homeroom.canEdit}
                  title={homeroom.announcement.title}
                  message={homeroom.announcement.message}
                  url={homeroom.announcement.url}
                  attachment={homeroom.announcement.attachment}
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
  )
}

HomeroomAnnouncementsLayout.propTypes = {
  homeroomAnnouncements: array.isRequired
}
