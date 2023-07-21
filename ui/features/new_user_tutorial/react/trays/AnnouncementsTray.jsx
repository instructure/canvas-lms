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
import {useScope as useI18nScope} from '@canvas/i18n'
import TutorialTrayContent from './TutorialTrayContent'

const I18n = useI18nScope('new_user_tutorial')

const AnnouncementsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Announcements')}
    subheading={I18n.t('Keep students informed')}
    image="/images/tutorial-tray-images/Panda_Announcements.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: I18n.t('#community.instructor_guide'),
    }}
    links={[
      {
        label: I18n.t('What are announcements?'),
        href: I18n.t('#community.basics_announcements'),
      },
      {
        label: I18n.t('How do I add an announcement in a course?'),
        href: I18n.t('#community.instructor_add_announcement'),
      },
      {
        label: I18n.t('How do I edit an announcement in a course?'),
        href: I18n.t('#community.instructor_edit_announcement'),
      },
      {
        label: I18n.t('How do I use the Announcements Index Page?'),
        href: I18n.t('#community.instructor_use_announcements_index'),
      },
    ]}
  >
    {I18n.t(`Share important information about your course with all users.
      Use announcements to remind students of important dates and tasks,
      point students to internal and external resources to help them achieve
      course outcomes, celebrate student success, and highlight events of interest.
      Announcements can include text, multimedia, and files.`)}
  </TutorialTrayContent>
)

export default AnnouncementsTray
