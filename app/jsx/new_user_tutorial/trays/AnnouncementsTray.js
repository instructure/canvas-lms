/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const AnnouncementsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Announcements')}
    subheading={I18n.t('Share important updates with users')}
    image="/images/tutorial-tray-images/announcements.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Share important information with all users in your course.
          Choose to get a copy of your own announcements in Notifications.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default AnnouncementsTray
