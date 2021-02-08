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
    name="Outcomes"
    heading={I18n.t('Outcomes')}
    subheading={I18n.t('Observe student mastery')}
    image="/images/tutorial-tray-images/Panda_Teacher.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/t5/Instructor-Guide/tkb-p/Instructor`
    }}
    links={[
      {
        label: I18n.t('How do I use the outcomes page in a course?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-use-the-outcomes-page-in-a-course/ta-p/645'
      },
      {
        label: I18n.t('How do I create an outcome for a course?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-create-an-outcome-for-a-course/ta-p/862'
      },
      {
        label: I18n.t('How do I create outcome groups for a course?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-create-outcome-groups-for-a-course/ta-p/1128'
      },
      {
        label: I18n.t('How do I import outcomes for a course?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-import-outcomes-for-a-course/ta-p/702'
      },
      {
        label: I18n.t(
          'How do I use the Learning Mastery Gradebook to view outcome results in a course from the Gradebook?'
        ),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-use-the-Learning-Mastery-Gradebook-to-view-outcome/ta-p/775'
      }
    ]}
  >
    {I18n.t(
      `Set up outcomes in your course as measured by pedagogical goals or desired objectives.
      Help students learn skills and activities, rather than just focusing on grades as a measure of their success.
      Assess student progress through calculation methods, and measure progress directly in the Learning Mastery Gradebook.
      Import existing account, state, and Common Core Standards outcomes to your course. You can also align outcomes in course rubrics.`
    )}
  </TutorialTrayContent>
)

export default HomeTray
