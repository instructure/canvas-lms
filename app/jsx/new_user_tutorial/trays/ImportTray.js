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
import Text from '@instructure/ui-elements/lib/components/Text'
import TutorialTrayContent from './TutorialTrayContent'

const ImportTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Import')}
    subheading={I18n.t('Bring your content into your course')}
    image="/images/tutorial-tray-images/import.svg"
  >
    <Text as="p">
      {
        I18n.t(`Bring existing content from another course or course
          management system into your Canvas course.`)
      }
    </Text>
  </TutorialTrayContent>
);

export default ImportTray;
