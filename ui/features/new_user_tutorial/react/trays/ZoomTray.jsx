/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

const ZoomTray = () => (
  <TutorialTrayContent
    name="Zoom"
    heading={I18n.t('Zoom')}
    subheading={I18n.t('Enable face-to-face connection')}
    image="/images/tutorial-tray-images/Panda_Conferences.svg"
    links={[
      {
        label: I18n.t('How do I add Zoom to a course?'),
        href: I18n.t('#community.admin_zoom_meetings_faq_add'),
      },
      {
        label: I18n.t('How do I schedule a Zoom video meeting?'),
        href: I18n.t('#community.admin_zoom_meetings_faq_schedule'),
      },
      {
        label: I18n.t('How do I invite others to join a meeting?'),
        href: I18n.t('#community.admin_zoom_meetings_faq_invite'),
      },
      {
        label: I18n.t('How do I start a meeting?'),
        href: I18n.t('#community.admin_zoom_meetings_faq_start'),
      },
      {
        label: I18n.t('How do I record a meeting?'),
        href: I18n.t('#community.admin_zoom_meetings_faq_record'),
      },
      {
        label: I18n.t('How do I know if students have joined the meeting?'),
        href: I18n.t('#community.admin_zoom_meetings_faq_participants'),
      },
      {
        label: I18n.t('How do I mute and unmute all participants?'),
        href: I18n.t('#community.admin_zoom_meetings_faq_mute'),
      },
      {
        label: I18n.t('How do I turn my camera on or off and use Zoom controls?'),
        href: I18n.t('#community.admin_zoom_meetings_faq_camera'),
      },
      {
        label: I18n.t('How do I share my screen?'),
        href: I18n.t('#community.admin_zoom_meetings_faq_screenshare'),
      },
      {
        label: I18n.t('How do I manage and share the recording?'),
        href: I18n.t('#community.admin_zoom_meetings_faq_share_record'),
      },
      {
        label: I18n.t('What storage options do I have in Zoom?'),
        href: I18n.t('#community.admin_zoom_meetings_faq_storage'),
      },
    ]}
  >
    {I18n.t(`Zoom is a real-time video conferencing tool that brings
    teachers and students together. You can schedule and run
    video meetings directly within Canvas by adding a Zoom link
    in a Canvas Course, Course Announcement, Module, or via Calendar.`)}
  </TutorialTrayContent>
)

export default ZoomTray
