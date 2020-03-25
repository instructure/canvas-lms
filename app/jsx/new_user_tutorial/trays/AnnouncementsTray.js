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
import TutorialTrayContent from './TutorialTrayContent'

const AnnouncementsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Announcements')}
    subheading={I18n.t('Keep students informed')}
    image="/images/tutorial-tray-images/Panda_Announcements.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/docs/DOC-10460-canvas-instructor
      -guide-table-of-contents#jive_content_id_Announcements`
    }}
    links={[
      {
        label: I18n.t('What are announcements?'),
        href: 'https://community.canvaslms.com/docs/DOC-10736-67952724136'
      },
      {
        label: I18n.t('How do I add an announcement in a course?'),
        href: 'https://community.canvaslms.com/docs/DOC-10405-415250731'
      },
      {
        label: I18n.t('How do I edit an announcement in a course?'),
        href: 'https://community.canvaslms.com/docs/DOC-10407-415250732'
      },
      {
        label: I18n.t('How do I use the Announcements Index Page?'),
        href: 'https://community.canvaslms.com/docs/DOC-10214-415276768'
      }
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
