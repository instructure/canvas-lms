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

const HomeTray = () => (
  <TutorialTrayContent
    name="Home"
    heading={I18n.t('Home')}
    subheading={I18n.t('Course landing page')}
    image="/images/tutorial-tray-images/Panda_Home.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/docs/DOC-10460-
      canvas-instructor-guide-table-of-contents#jive_content_id_Course_Navigation`
    }}
    links={[
      {
        label: I18n.t('How do I use the Course Home Page as an instructor?'),
        href: 'https://community.canvaslms.com/docs/DOC-12947-4152724144'
      },
      {
        label: I18n.t(
          'What layout options are available in the Course Home Page as an instructor?'
        ),
        href: 'https://community.canvaslms.com/docs/DOC-12816-4152719700'
      },
      {
        label: I18n.t('How do I change the Course Home Page?'),
        href: 'https://community.canvaslms.com/docs/DOC-13012-4152724499'
      }
    ]}
  >
    {I18n.t(`The Course Home Page is the first page students see when they open
      your course. The Home Page can display the course participation activity
      stream, the Course Modules page, the Course Assignments list, Syllabus,
      or a page you design as the front page.`)}
  </TutorialTrayContent>
)

export default HomeTray
