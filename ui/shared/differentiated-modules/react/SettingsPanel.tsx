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
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
// @ts-expect-error
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import Footer from './Footer'
import DateTimeInput from '@canvas/datetime/react/components/DateTimeInput'
import {defaultState, actions, reducer} from './settingsReducer'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {convertModuleSettingsForApi, updateModuleUI} from '../utils/moduleHelpers'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item: FlexItem} = Flex as any

export interface SettingsPanelProps {
  height: string
  onDismiss: () => void
  moduleElement: HTMLDivElement
  moduleId: string
  moduleName?: string
  unlockAt?: string
}

export default function SettingsPanel({
  moduleElement,
  height,
  onDismiss,
  moduleId,
  moduleName,
  unlockAt,
}: SettingsPanelProps) {
  const [state, dispatch] = useReducer(reducer, {
    ...defaultState,
    moduleName: moduleName ?? '',
    unlockAt: unlockAt ?? new Date().toISOString(),
    lockUntilChecked: !!unlockAt,
  })

  function handleUpdate() {
    if (state.moduleName.length === 0) {
      dispatch({
        type: actions.SET_NAME_INPUT_MESSAGES,
        payload: [{type: 'error', text: I18n.t('Module Name is required.')}],
      })
      return
    }

    doFetchApi({
      path: `/courses/${ENV.COURSE_ID}/modules/${moduleId}`,
      method: 'PUT',
      body: convertModuleSettingsForApi(state),
    })
      .then(() => {
        onDismiss()
        updateModuleUI(moduleElement, state)
        showFlashAlert({
          type: 'success',
          message: I18n.t('%{moduleName} settings updated successfully.', {
            moduleName: state.moduleName,
          }),
        })
      })
      .catch((e: Error) =>
        showFlashAlert({
          err: e,
          message: I18n.t('Error updating %{moduleName} settings.', {moduleName: state.moduleName}),
        })
      )
  }

  return (
    <Flex direction="column" justifyItems="space-between" height={height}>
      <FlexItem shouldGrow={true} padding="small">
        <View as="div" padding="small">
          <TextInput
            renderLabel={I18n.t('Module Name')}
            value={state.moduleName}
            messages={state.nameInputMessages}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => {
              const newValue = e.target.value.trim()
              dispatch({type: actions.SET_MODULE_NAME, payload: newValue})
              if (newValue.length > 0) {
                dispatch({type: actions.SET_NAME_INPUT_MESSAGES, payload: []})
              }
            }}
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
      </FlexItem>
      <FlexItem>
        <Footer
          onDismiss={onDismiss}
          onUpdate={handleUpdate}
          disableUpdate={state.nameInputMessages.length > 0}
        />
      </FlexItem>
    </Flex>
  )
}
