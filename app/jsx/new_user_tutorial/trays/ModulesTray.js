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

const ModulesTray = () => (
  <TutorialTrayContent
    name="Modules"
    heading={I18n.t('Modules')}
    subheading={I18n.t('Organize your course content')}
    image="/images/tutorial-tray-images/module_tutorial.svg"
  >
    <Text as="p">
      {
          I18n.t(`Organize and segment your course by topic, unit, chapter,
                  or week. Sequence select modules by defining criteria and
                  prerequisites.`)
        }
    </Text>
  </TutorialTrayContent>
);

export default ModulesTray
