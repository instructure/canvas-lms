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

const ImportTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Import')}
    subheading={I18n.t('Bring existing content into your course')}
    image="/images/tutorial-tray-images/Panda_Map.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/docs/DOC-10460-canvas-instructor-
      guide-table-of-contents#jive_content_id_Course_Import_Tool`
    }}
    links={[
      {
        label: I18n.t('How do I copy a Canvas course into a new course shell?'),
        href: 'https://community.canvaslms.com/docs/DOC-13035-4152239683'
      },
      {
        label: I18n.t('How do I import a Canvas course export package?'),
        href: 'https://community.canvaslms.com/docs/DOC-12783-415241324'
      },
      {
        label: I18n.t('How do I select specific content as part of a course import?'),
        href: 'https://community.canvaslms.com/docs/DOC-13101-4152497985'
      },
      {
        label: I18n.t('How do I adjust events and due dates in a course import?'),
        href: 'https://community.canvaslms.com/docs/DOC-13099-4152497986'
      }
    ]}
  >
    {I18n.t(`Easily import or copy content from another Canvas course into
        your course, or import content from other formats, such as Moodle or QTI.`)}
  </TutorialTrayContent>
)

export default ImportTray
