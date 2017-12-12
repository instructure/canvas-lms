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
import Text from '@instructure/ui-core/lib/components/Text'
import TutorialTrayContent from './TutorialTrayContent'

const SyllabusTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Syllabus')}
    subheading={I18n.t('An auto-generated chronological summary of your course')}
    image="/images/tutorial-tray-images/syllabus.svg"
  >
    <Text as="p">
      {
        I18n.t(`Communicate to your students exactly what will be required
          of them throughout the course in chronological order. Generate a
          built-in Syllabus based on Assignments and Events that you've created.`)
      }
    </Text>
  </TutorialTrayContent>
);

export default SyllabusTray;
