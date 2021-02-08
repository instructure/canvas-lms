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

const SyllabusTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Syllabus')}
    subheading={I18n.t('Communicate course objectives')}
    image="/images/tutorial-tray-images/Panda_Syllabus.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/t5/Instructor-Guide/tkb-p/Instructor`
    }}
    links={[
      {
        label: I18n.t('How do I use the Syllabus as an instructor?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-use-the-Syllabus-as-an-instructor/ta-p/638'
      },
      {
        label: I18n.t('How do I edit the Syllabus description in a course?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-edit-the-Syllabus-in-a-course/ta-p/1178'
      }
    ]}
  >
    {I18n.t(`The Syllabus lets you welcome your course users and share expectations
      with your students. Use the Syllabus description to clarify course objectives,
      preferred contact methods, and other details, or upload a PDF of an existing
      Syllabus. The Syllabus page can also display all assignments and events
      within the course.`)}
  </TutorialTrayContent>
)

export default SyllabusTray
