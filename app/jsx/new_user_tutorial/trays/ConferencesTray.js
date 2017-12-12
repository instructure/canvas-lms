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

const ConferencesTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Conferences')}
    subheading={I18n.t('Virtual lectures in real-time')}
    image="/images/tutorial-tray-images/conferences.svg"
  >
    <Text as="p">
      {
        I18n.t(`Conduct virtual lectures, virtual office hours, and student
          groups. Broadcast real-time audio and video, share presentation
          slides, give demonstrations of applications and online resources,
          and more.`)
      }
    </Text>
  </TutorialTrayContent>
);

export default ConferencesTray;
