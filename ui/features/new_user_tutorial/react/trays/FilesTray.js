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

const FilesTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Files')}
    subheading={I18n.t('Store and share course assets')}
    image="/images/tutorial-tray-images/Panda_Files.svg"
    seeAllLink={{
      label: I18n.t('See more in Canvas Guides'),
      href: I18n.t('#community.instructor_guide'),
    }}
    links={[
      {
        label: I18n.t('How do I use Files as an instructor?'),
        href: I18n.t('#community.instructor_use_files'),
      },
      {
        label: I18n.t('How do I upload a file to a course?'),
        href: I18n.t('#community.instructor_upload_course_file'),
      },
      {
        label: I18n.t('How do I bulk upload files to a course?'),
        href: I18n.t('#community.instructor_bulk_upload'),
      },
      {
        label: I18n.t('How do I move and organize my files as an instructor?'),
        href: I18n.t('#community.instructor_organize_files'),
      },
    ]}
  >
    {I18n.t(`Upload and store course files, or any other files you need to keep
      on hand. When you save assets in Files, they're easy to insert directly into
      modules, assignments, discussions, or pages! Distribute files to students
      from your course folder, or lock files until you're ready for the class
      to download them.`)}
  </TutorialTrayContent>
)

export default FilesTray
