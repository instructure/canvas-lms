/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useReducer} from 'react'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
// @ts-expect-error
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import DateTimeInput from '@canvas/datetime/react/components/DateTimeInput'
import {actions, reducer} from './settingsReducer'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

export interface SettingsPanelProps {
  moduleId?: string
  moduleName?: string
  unlockAt?: string
}

export default function SettingsPanel({moduleName, unlockAt}: SettingsPanelProps) {
  const [state, dispatch] = useReducer(reducer, {
    moduleName: moduleName ?? '',
    unlockAt: unlockAt ?? new Date().toISOString(),
    lockUntilChecked: !!unlockAt,
  })

  return (
    <View as="div">
      <View as="div" padding="small">
        <TextInput
          renderLabel={I18n.t('Module Name')}
          value={state.moduleName}
          onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
            dispatch({type: actions.SET_MODULE_NAME, payload: e.target.value})
          }
        />
      </View>
      <View as="div" padding="x-small small">
        <Checkbox
          label={I18n.t('Lock Until')}
          checked={state.lockUntilChecked}
          onChange={() =>
            dispatch({type: actions.SET_LOCK_UNTIL_CHECKED, payload: !state.lockUntilChecked})
          }
        />
      </View>
      {state.lockUntilChecked && (
        <View as="div" padding="small">
          <DateTimeInput
            value={state.unlockAt}
            layout="columns"
            colSpacing="small"
            onChange={dateTimeString =>
              dispatch({type: actions.SET_UNLOCK_AT, payload: dateTimeString})
            }
            description={
              <ScreenReaderContent>
                {I18n.t('Unlock Date for %{moduleName}', {moduleName: state.moduleName})}
              </ScreenReaderContent>
            }
          />
        </View>
      )}
      <hr />
    </View>
  )
}
