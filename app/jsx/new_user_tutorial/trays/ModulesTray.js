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

const ModulesTray = () => (
  <TutorialTrayContent
    name="Modules"
    heading={I18n.t('Modules')}
    subheading={I18n.t('Organize course content')}
    image="/images/tutorial-tray-images/Panda_Modules.svg"
    imageWidth="9rem"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: `https://community.canvaslms.com/docs/DOC-10460-canvas-instructor-guide-
      table-of-contents#jive_content_id_Modules`
    }}
    links={[
      {
        label: I18n.t('How do I add a module?'),
        href: 'https://community.canvaslms.com/docs/DOC-13129-415241424'
      },
      {
        label: I18n.t('How do I publish or unpublish a module as an instructor?'),
        href: 'https://community.canvaslms.com/docs/DOC-10114-4152180497'
      },
      {
        label: I18n.t('How do I add assignment types, pages, and files as module items?'),
        href: 'https://community.canvaslms.com/docs/DOC-12689-415241427'
      },
      {
        label: I18n.t('How do I move or reorder a module?'),
        href: 'https://community.canvaslms.com/docs/DOC-12697-415241425'
      }
    ]}
  >
    {I18n.t(`Use modules to organize your content and create a linear flow for
      what students should do in the course. Modules can be used to organize
      content by weeks, units, or a different organization structure.
      Add files, discussions, assignments, quizzes, and other learning materials.
      Require prerequisites to be completed before moving to a module or next
      module item, or lock an entire module until a specific date.`)}
  </TutorialTrayContent>
)

export default ModulesTray
