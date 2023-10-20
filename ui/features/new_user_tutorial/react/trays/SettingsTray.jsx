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

const AssignmentsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Settings')}
    subheading={I18n.t('Customize course details')}
    image="/images/tutorial-tray-images/Panda_Map.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: I18n.t('#community.instructor_guide'),
    }}
    links={[
      {
        label: I18n.t('How do I use course settings?'),
        href: I18n.t('#community.instructor_use_course_settings'),
      },
      {
        label: I18n.t('How do I set details for a course?'),
        href: I18n.t('#community.instructor_set_course_details'),
      },
      {
        label: I18n.t('How do I change a course name and course code?'),
        href: I18n.t('#community.instructor_change_name_code'),
      },
      {
        label: I18n.t('How do I add an image to a course card in the Dashboard?'),
        href: I18n.t('#community.instructor_add_dashboard_image'),
      },
    ]}
  >
    {I18n.t(`Make your course your own! Upload an image to represent your
      course, allow students to manage course content areas, and hide grade
      details from students. You may also be able to adjust the course name and code.`)}
  </TutorialTrayContent>
)

export default AssignmentsTray
