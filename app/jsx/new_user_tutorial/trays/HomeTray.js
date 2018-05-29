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

const HomeTray = () => (
  <TutorialTrayContent
    name="Home"
    heading={I18n.t('Home')}
    subheading={I18n.t('This is your course landing page')}
    image="/images/tutorial-tray-images/publish.png"
  >
    <Text as="p">
      {
        I18n.t(`When people visit your course, this is the first page they'll see.
          We've set your homepage to Modules, but you have the option to change it.`)
      }
    </Text>
    <Text as="p">
      {
        I18n.t(`You can publish your course from the home page whenever you’re ready
          to share it with students. Until your course is published, only instructors will be able to access it.`)
      }
    </Text>
  </TutorialTrayContent>
);

export default HomeTray
