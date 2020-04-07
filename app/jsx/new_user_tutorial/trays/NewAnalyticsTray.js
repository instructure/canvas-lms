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

const NewAnalyticsTray = () => (
  <TutorialTrayContent
    name="New-Analytics"
    heading={I18n.t('New Analytics')}
    subheading={I18n.t('Track student performance and activity')}
    image="/images/tutorial-tray-images/Panda_Analytics.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/docs/DOC-10460-canvas-instructor-guide-table-of-contents#jive_content_id_New_Analytics`
    }}
    links={[
      {
        label: I18n.t(
          'How do I send a message to all students based on specific course criteria in New Analytics?'
        ),
        href:
          'https://community.canvaslms.com/docs/DOC-10460-canvas-instructor-guide-table-of-contents#jive_content_id_New_Analytics'
      },
      {
        label: I18n.t('How do I send a message to an individual student in New Analytics?'),
        href: 'https://community.canvaslms.com/docs/DOC-18035-4152984805'
      },
      {
        label: I18n.t('How do I view analytics for an individual student?'),
        href: 'https://community.canvaslms.com/docs/DOC-17331-825371113470'
      }
    ]}
  >
    {I18n.t(`New Analytics is an interactive tool that helps you and your students better
    track performance and activity within the course. Learn which students have viewed
    pages and resources and participated in assignments—and which students may need a
    little more encouragement.`)}
  </TutorialTrayContent>
)

export default NewAnalyticsTray
