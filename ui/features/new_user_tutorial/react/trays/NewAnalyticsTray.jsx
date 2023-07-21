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

const NewAnalyticsTray = () => (
  <TutorialTrayContent
    name="New-Analytics"
    heading={I18n.t('New Analytics')}
    subheading={I18n.t('Track student performance and activity')}
    image="/images/tutorial-tray-images/Panda_Analytics.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: I18n.t('#community.instructor_guide'),
    }}
    links={[
      {
        label: I18n.t(
          'How do I send a message to all students based on specific course criteria in New Analytics?'
        ),
        href: I18n.t('#community.instructor_message_all_criteria_new_analytics'),
      },
      {
        label: I18n.t('How do I send a message to an individual student in New Analytics?'),
        href: I18n.t('#community.instructor_message_individual_new_analytics'),
      },
      {
        label: I18n.t('How do I view analytics for an individual student?'),
        href: I18n.t('#community.instructor_individual_new_analytics'),
      },
    ]}
  >
    {I18n.t(`New Analytics is an interactive tool that helps you and your students better
    track performance and activity within the course. Learn which students have viewed
    pages and resources and participated in assignments—and which students may need a
    little more encouragement.`)}
  </TutorialTrayContent>
)

export default NewAnalyticsTray
