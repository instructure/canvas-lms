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
    heading={I18n.t('Settings')}
    subheading={I18n.t('Customize course details')}
    image="/images/tutorial-tray-images/Panda_Map.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/docs/DOC-10460-canvas-instructor-guide-table-of-contents#jive_content_id_Settings`
    }}
    links={[
      {
        label: I18n.t('How do I use course settings?'),
        href: 'https://community.canvaslms.com/docs/DOC-12814-4152724176'
      },
      {
        label: I18n.t('How do I set details for a course?'),
        href: 'https://community.canvaslms.com/docs/DOC-12900-415257087'
      },
      {
        label: I18n.t('How do I change a course name and course code?'),
        href: 'https://community.canvaslms.com/docs/DOC-12851-415241512'
      },
      {
        label: I18n.t('How do I add an image to a course card in the Dashboard?'),
        href: 'https://community.canvaslms.com/docs/DOC-12780-4152626354'
      }
    ]}
  >
    {I18n.t(`Make your course your own! Upload an image to represent your
      course, allow students to manage course content areas, and hide grade
      details from students. You may also be able to adjust the course name and code.`)}
  </TutorialTrayContent>
)

export default AssignmentsTray
