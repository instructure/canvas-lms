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

const AssignmentsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Assignments')}
    subheading={I18n.t('Reinforce student understanding')}
    image="/images/tutorial-tray-images/Panda_Assignments.svg"
    imageWidth="11rem"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/docs/DOC-10460-canvas-
      instructor-guide-table-of-contents#jive_content_id_Assignments`
    }}
    links={[
      {
        label: I18n.t('How do I create an assignment?'),
        href: 'https://community.canvaslms.com/docs/DOC-9873-415267003'
      },
      {
        label: I18n.t('How do I publish or unpublish an assignment as an instructor?'),
        href: 'https://community.canvaslms.com/docs/DOC-10101-4152180493'
      },
      {
        label: I18n.t('What assignment types can I create in a course?'),
        href: 'https://community.canvaslms.com/docs/DOC-10092-415254365'
      },
      {
        label: I18n.t('How do I add or edit details in an assignment?'),
        href: 'https://community.canvaslms.com/docs/DOC-10113-415241285'
      }
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
