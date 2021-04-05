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

const PeopleTray = () => (
  <TutorialTrayContent
    heading={I18n.t('People')}
    subheading={I18n.t('Know your users')}
    image="/images/tutorial-tray-images/Panda_People.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/t5/Instructor-Guide/tkb-p/Instructor`
    }}
    links={[
      {
        label: I18n.t('How do I use the People page in a course as an instructor?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-use-the-People-page-in-a-course-as-an-instructor/ta-p/667'
      },
      {
        label: I18n.t('How do I add users to a course?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-add-users-to-a-course/ta-p/1119'
      },
      {
        label: I18n.t('How do I view a context card for a student in a course?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-view-a-context-card-for-a-student-in-a-course/ta-p/608'
      },
      {
        label: I18n.t('How do I view user details for an enrollment in a course?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-view-user-details-for-an-enrollment-in-a-course/ta-p/1216'
      }
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
