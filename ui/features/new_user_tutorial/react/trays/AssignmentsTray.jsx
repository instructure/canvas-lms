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
    heading={I18n.t('Assignments')}
    subheading={I18n.t('Reinforce student understanding')}
    image="/images/tutorial-tray-images/Panda_Assignments.svg"
    imageWidth="11rem"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: I18n.t('#community.instructor_guide'),
    }}
    links={[
      {
        label: I18n.t('How do I create an assignment?'),
        href: I18n.t('#community.instructor_create_assignment'),
      },
      {
        label: I18n.t('How do I publish or unpublish an assignment as an instructor?'),
        href: I18n.t('#community.instructor_publish_assignment'),
      },
      {
        label: I18n.t('What assignment types can I create in a course?'),
        href: I18n.t('#community.instructor_assignment_types'),
      },
      {
        label: I18n.t('How do I add or edit details in an assignment?'),
        href: I18n.t('#community.instructor_assignment_details'),
      },
    ]}
  >
    {I18n.t(`Assignments include quizzes, graded discussions, and many types
      of online submissions (files, images, text, URLs, and media). Assign
      them to everyone in a course, or assign different due dates for specific
      sections or users. Create assignment groups to organize your assignments
      and to weight groups by percentage. Enable Peer Review so students can
      review each other's work.`)}
  </TutorialTrayContent>
)

export default AssignmentsTray
