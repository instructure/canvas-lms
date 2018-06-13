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

const AssignmentsTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Settings')}
    subheading={I18n.t('Manage your course details')}
    image="/images/tutorial-tray-images/settings.svg"
  >
    <Text as="p">
      {
        I18n.t(`Update and view sections, course details, navigation, feature
                options and external app integrations, all visible only to Instructors.`)
      }
    </Text>
  </TutorialTrayContent>
);

export default AssignmentsTray
