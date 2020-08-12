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
          'https://community.canvaslms.com/t5/Admin-Group/Using-Zoom-with-Canvas-FAQ/ba-p/261826#toc-hId--1295024148'
      },
      {
        label: I18n.t('How do I schedule a Zoom video meeting?'),
        href:
          'https://community.canvaslms.com/t5/Admin-Group/Using-Zoom-with-Canvas-FAQ/ba-p/261826#toc-hId-447786187'
      },
      {
        label: I18n.t('How do I invite others to join a meeting?'),
        href:
          'https://community.canvaslms.com/t5/Admin-Group/Using-Zoom-with-Canvas-FAQ/ba-p/261826#toc-hId--361560439'
      },
      {
        label: I18n.t('How do I start a meeting?'),
        href:
          'https://community.canvaslms.com/t5/Admin-Group/Using-Zoom-with-Canvas-FAQ/ba-p/261826#toc-hId--1170907065'
      },
      {
        label: I18n.t('How do I record a meeting?'),
        href:
          'https://community.canvaslms.com/t5/Admin-Group/Using-Zoom-with-Canvas-FAQ/ba-p/261826#toc-hId--1980253691'
      },
      {
        label: I18n.t('How do I know if students have joined the meeting?'),
        href:
          'https://community.canvaslms.com/t5/Admin-Group/Using-Zoom-with-Canvas-FAQ/ba-p/261826#toc-hId--237443356'
      },
      {
        label: I18n.t('How do I mute and unmute all participants?'),
        href:
          'https://community.canvaslms.com/t5/Admin-Group/Using-Zoom-with-Canvas-FAQ/ba-p/261826#toc-hId--810232164'
      },
      {
        label: I18n.t('How do I turn my camera on or off and use Zoom controls?'),
        href:
          'https://community.canvaslms.com/t5/Admin-Group/Using-Zoom-with-Canvas-FAQ/ba-p/261826#toc-hId--1619578790'
      },
      {
        label: I18n.t('How do I share my screen?'),
        href:
          'https://community.canvaslms.com/t5/Admin-Group/Using-Zoom-with-Canvas-FAQ/ba-p/261826#toc-hId-123231545'
      },
      {
        label: I18n.t('How do I manage and share the recording?'),
        href:
          'https://community.canvaslms.com/t5/Admin-Group/Using-Zoom-with-Canvas-FAQ/ba-p/261826#toc-hId-1866041880'
      },
      {
        label: I18n.t('What storage options do I have in Zoom?'),
        href:
          'https://community.canvaslms.com/t5/Admin-Group/Using-Zoom-with-Canvas-FAQ/ba-p/261826#toc-hId--1387179659'
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
