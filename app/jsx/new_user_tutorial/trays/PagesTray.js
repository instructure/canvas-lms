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

const PagesTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Pages')}
    subheading={I18n.t('Create interactive course content')}
    image="/images/tutorial-tray-images/Panda_Pages.svg"
    imageWidth="14.5rem"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/docs/DOC-10460-
      canvas-instructor-guide-table-of-contents#jive_content_id_Pages`
    }}
    links={[
      {
        label: I18n.t('How do I create a new page in a course?'),
        href: 'https://community.canvaslms.com/docs/DOC-13018-4152724253'
      },
      {
        label: I18n.t('How do I publish or unpublish a page as an instructor?'),
        href: 'https://community.canvaslms.com/docs/DOC-12796-4152180494'
      },
      {
        label: I18n.t('How do I use the Pages Index Page?'),
        href: 'https://community.canvaslms.com/docs/DOC-12776-4152322017'
      },
      {
        label: I18n.t('How do I set a Front Page in a course?'),
        href: 'https://community.canvaslms.com/docs/DOC-12784-415241445'
      }
    ]}
  >
    {I18n.t(`Pages let you create interactive content directly in Canvas,
      whether it's a weekly update, a collaborative course wiki, or a
      list of educational resources. Pages can include text, multimedia,
      and links to files and other course content or pages. You can also
      allow students to contribute to specific pages in the course.`)}
  </TutorialTrayContent>
)

export default PagesTray
