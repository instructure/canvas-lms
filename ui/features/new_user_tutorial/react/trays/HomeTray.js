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

const HomeTray = () => (
  <TutorialTrayContent
    name="Home"
    heading={I18n.t('Home')}
    subheading={I18n.t('Welcome your students')}
    image="/images/tutorial-tray-images/Panda_Home.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: I18n.t('#community.instructor_guide'),
    }}
    links={[
      {
        label: I18n.t('How do I use the Course Home Page as an instructor?'),
        href: I18n.t('#community.instructor_use_course_homepage'),
      },
      {
        label: I18n.t(
          'What layout options are available in the Course Home Page as an instructor?'
        ),
        href: I18n.t('#community.instructor_homepage_layout_options'),
      },
      {
        label: I18n.t('How do I change the Course Home Page?'),
        href: I18n.t('#community.instructor_change_course_home'),
      },
    ]}
  >
    {I18n.t(`The Course Home Page is the first page students see when they open
      your course. The Home Page can display the course participation activity
      stream, the Course Modules page, the Course Assignments list, Syllabus,
      or a page you design as the front page.`)}
  </TutorialTrayContent>
)

export default HomeTray
