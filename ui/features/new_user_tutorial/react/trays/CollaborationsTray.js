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

const CollaborationsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Collaborations')}
    subheading={I18n.t('Work and create together')}
    image="/images/tutorial-tray-images/Panda_Collaborations.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/t5/Instructor-Guide/tkb-p/Instructor`
    }}
    links={[
      {
        label: I18n.t('What are collaborations?'),
        href:
          'https://community.canvaslms.com/t5/Canvas-Basics-Guide/What-are-Collaborations/ta-p/61'
      },
      {
        label: I18n.t('How do I use the Collaborations Index Page?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-use-the-Collaborations-Index-Page/ta-p/922'
      },
      {
        label: I18n.t('How do I create a Google Drive collaboration as an instructor?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-create-a-Google-Drive-collaboration-as-an-instructor/ta-p/632'
      },
      {
        label: I18n.t('How do I create a Microsoft Office 365 collaboration as an instructor?'),
        href:
          'https://community.canvaslms.com/t5/Instructor-Guide/How-do-I-create-a-Microsoft-Office-365-collaboration-as-an/ta-p/629'
      }
    ]}
  >
    {I18n.t(`Canvas helps you leverage collaborative technology so multiple
      users can work together on the same document at the same time. Create
      collaborative documents that are saved in real time—a change made by
      any user will be visible to everyone immediately.`)}
  </TutorialTrayContent>
)

export default CollaborationsTray
