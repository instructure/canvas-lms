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

const ConferencesTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Conferences')}
    subheading={I18n.t('Host virtual lectures in real time')}
    image="/images/tutorial-tray-images/Panda_Conferences.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/docs/DOC-10460-
      canvas-instructor-guide-table-of-contents#jive_content_id_Conferences`
    }}
    links={[
      {
        label: I18n.t('How do I create a conference in a course?'),
        href: 'https://community.canvaslms.com/docs/DOC-12687-415241306'
      },
      {
        label: I18n.t('How do I start a conference?'),
        href: 'https://community.canvaslms.com/docs/DOC-12849-415265960'
      },
      {
        label: I18n.t('How do I conclude a conference?'),
        href: 'https://community.canvaslms.com/docs/DOC-12839-4152299839'
      },
      {
        label: I18n.t('How do I record a conference?'),
        href: 'https://community.canvaslms.com/docs/DOC-13090-4152117864'
      }
    ]}
  >
    {I18n.t(`Conduct lectures, office hours, and student group meetings all
      from your computer. Broadcast real-time audio and video, share presentation
      slides, give demonstrations of applications and online resources,
      and more.`)}
  </TutorialTrayContent>
)

export default ConferencesTray
