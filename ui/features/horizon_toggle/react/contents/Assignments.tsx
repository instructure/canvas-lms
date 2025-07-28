/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useContext} from 'react'
import {HorizonToggleContext} from '../HorizonToggleContext'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {ContentItems} from './ContentItems'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('horizon_toggle_page')

export const Assignments = () => {
  const data = useContext(HorizonToggleContext)
  const assignments = data?.errors?.assignments?.filter(item => !item.errors.workflow_state)
  if (!assignments || assignments.length === 0) {
    return null
  }
  return (
    <View as="div">
      <Heading level="h3">{I18n.t('Assignments')}</Heading>
      <Text as="p">
        {I18n.t(
          'Unsupported submission types will be updated to online text entry. You may choose to change this to another supported submission type after converting your course.',
        )}
      </Text>
      <Text as="p">
        {I18n.t('Group assignments are not supported and the group setting will be removed.')}
      </Text>
      <ContentItems
        label={I18n.t(
          {
            one: 'Assignments with Revisions (%{count} item)',
            other: 'Assignments with Revisions (%{count} items)',
          },
          {count: assignments.length},
        )}
        screenReaderLabel={I18n.t('Assignments with Revisions')}
        contents={assignments}
      />
    </View>
  )
}
