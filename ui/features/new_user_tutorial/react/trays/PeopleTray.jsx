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

const PeopleTray = () => (
  <TutorialTrayContent
    heading={I18n.t('People')}
    subheading={I18n.t('Know your users')}
    image="/images/tutorial-tray-images/Panda_People.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: I18n.t('#community.instructor_guide'),
    }}
    links={[
      {
        label: I18n.t('How do I use the People page in a course as an instructor?'),
        href: I18n.t('#community.instructor_use_people_page'),
      },
      {
        label: I18n.t('How do I add users to a course?'),
        href: I18n.t('#community.instructor_add_users'),
      },
      {
        label: I18n.t('How do I view a context card for a student in a course?'),
        href: I18n.t('#community.instructor_view_student_context_card'),
      },
      {
        label: I18n.t('How do I view user details for an enrollment in a course?'),
        href: I18n.t('#community.instructor_view_enrollment_details'),
      },
    ]}
  >
    {I18n.t(
      `What's a class without people to take and lead it? The People page
      shows the list of users in your course. Depending on your permissions,
      you may be able to add students, teacher assistants, and observers to
      your course. You can also create student groups to house group assignments,
      discussions, and files.`
    )}
  </TutorialTrayContent>
)

export default PeopleTray
