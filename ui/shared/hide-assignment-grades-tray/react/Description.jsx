/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('hide_assignment_grades_tray')

export default function Description() {
  return (
    <>
      <View as="p" margin="0 0 small">
        <Text>
          {I18n.t(
            'While grades for an assignment are hidden, students cannot see any grades or comments that were entered ',
          )}
        </Text>
        <Text weight="weightImportant">{I18n.t('before')}</Text>
        <Text>{I18n.t(' grades were hidden. However, any grades or comments added ')}</Text>
        <Text weight="weightImportant">{I18n.t('after')}</Text>
        <Text>
          {I18n.t(
            " the grades are hidden will follow the assignment's posting policy and may be visible to students immediately.",
          )}
        </Text>
      </View>
      <View as="p" margin="0 0 small">
        <Text>{I18n.t('Students will still see that grades for this assignment are hidden.')}</Text>
      </View>
    </>
  )
}
