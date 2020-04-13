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
import I18n from 'i18n!new_user_tutorial'
import TutorialTrayContent from './TutorialTrayContent'

const ZoomTray = () => (
  <TutorialTrayContent
    name="Zoom"
    heading={I18n.t('Zoom')}
    subheading={I18n.t('Enable face-to-face connection')}
    image="/images/tutorial-tray-images/Panda_Conferences.svg"
    links={[
      {
        label: I18n.t('How do I add Zoom to a course?'),
        href:
          'https://community.canvaslms.com/docs/DOC-23893#jive_content_id_How_do_I_add_Zoom_to_a_Canvas_course'
      },
      {
        label: I18n.t('How do I schedule a Zoom video meeting?'),
        href:
          'https://community.canvaslms.com/docs/DOC-23893#jive_content_id_How_do_I_schedule_a_Zoom_video_meeting'
      },
      {
        label: I18n.t('How do I start a meeting?'),
        href:
          'https://community.canvaslms.com/docs/DOC-23893#jive_content_id_How_do_I_start_a_meeting'
      },
      {
        label: I18n.t('How do I record a meeting?'),
        href:
          'https://community.canvaslms.com/docs/DOC-23893#jive_content_id_How_do_I_record_a_meeting'
      },
      {
        label: I18n.t('How do I know if students have joined the meeting?'),
        href:
          'https://community.canvaslms.com/docs/DOC-23893#jive_content_id_How_do_I_know_if_students_have_joined_the_meeting'
      },
      {
        label: I18n.t('How do I mute and unmute all participants?'),
        href:
          'https://community.canvaslms.com/docs/DOC-23893#jive_content_id_How_do_I_mute_and_unmute_all_participants'
      },
      {
        label: I18n.t('How do I turn my camera on or off and use Zoom controls?'),
        href:
          'https://community.canvaslms.com/docs/DOC-23893#jive_content_id_How_do_I_turn_my_camera_on_and_off_and_use_the_Zoom_controls'
      },
      {
        label: I18n.t('How do I share my screen?'),
        href:
          'https://community.canvaslms.com/docs/DOC-23893#jive_content_id_How_do_I_share_my_screen'
      },
      {
        label: I18n.t('How do I manage and share the recording?'),
        href:
          'https://community.canvaslms.com/docs/DOC-23893#jive_content_id_How_do_I_manage_and_share_the_recording'
      }
    ]}
  >
    {I18n.t(`Zoom is a real-time video conferencing tool that brings
    teachers and students together. You can schedule and run
    video meetings directly within Canvas by adding a Zoom link
    in a Canvas Course, Course Announcement, Module, or via Calendar.`)}
  </TutorialTrayContent>
)

export default ZoomTray
