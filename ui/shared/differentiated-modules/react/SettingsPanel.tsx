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

import React, {useReducer, useMemo, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import PrerequisiteForm from './PrerequisiteForm'
import RequirementForm from './RequirementForm'
import Footer from './Footer'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {defaultState, actions, reducer} from './settingsReducer'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {convertModuleSettingsForApi} from '../utils/miscHelpers'
import {updateModuleUI} from '../utils/moduleHelpers'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import type {Module, ModuleItem, Requirement} from './types'
import RelockModulesDialog from '@canvas/context-modules/backbone/views/RelockModulesDialog'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingOverlay from './LoadingOverlay'

const I18n = useI18nScope('differentiated_modules')

export interface SettingsPanelProps {
  bodyHeight: string
  footerHeight: string
  onDismiss: () => void
  moduleElement: HTMLDivElement
  moduleId?: string
  moduleName?: string
  unlockAt?: string
  prerequisites?: Module[]
  moduleList?: Module[]
  requirementCount?: 'all' | 'one'
  requireSequentialProgress?: boolean
  requirements?: Requirement[]
  moduleItems?: ModuleItem[]
  publishFinalGrade?: boolean
  enablePublishFinalGrade?: boolean
  addModuleUI?: (data: Record<string, any>, element: HTMLDivElement) => void
  mountNodeRef: React.RefObject<HTMLElement>
}

export default function SettingsPanel({
  moduleElement,
  bodyHeight,
  footerHeight,
  onDismiss,
  moduleId,
  moduleName,
  unlockAt,
  prerequisites,
  requirementCount,
  requireSequentialProgress,
  requirements,
  publishFinalGrade,
  enablePublishFinalGrade = false,
  moduleList = [],
  moduleItems = [],
  addModuleUI = () => {},
  mountNodeRef,
}: SettingsPanelProps) {
  const [state, dispatch] = useReducer(reducer, {
    ...defaultState,
    moduleName: moduleName ?? '',
    unlockAt: unlockAt ?? new Date().toISOString(),
    lockUntilChecked: !!unlockAt,
    prerequisites: prerequisites ?? [],
    requirements: requirements ?? [],
    requirementCount: requirementCount ?? 'all',
    requireSequentialProgress: requireSequentialProgress ?? false,
    publishFinalGrade: publishFinalGrade ?? false,
  })
  const [loading, setLoading] = useState(false)

  const availableModules = useMemo(() => {
    const cutoffIndex = moduleList.findIndex(module => module.name === moduleName)
    return cutoffIndex === -1 ? moduleList : moduleList.slice(0, cutoffIndex)
  }, [moduleList, moduleName])

  function doRequest(
    path: string,
    method: string,
    onSuccess: (res: Record<string, any>) => void,
    successMessage: string,
    errorMessage: string
  ) {
    setLoading(true)
    doFetchApi({
      path,
      method,
      body: convertModuleSettingsForApi(state),
    })
      .then((data: {json: Record<string, any>}) => {
        setLoading(false)
        onDismiss()
        onSuccess(data.json)
        showFlashAlert({
          type: 'success',
          message: successMessage,
        })
      })
      .catch((e: Error) =>
        showFlashAlert({
          err: e,
          message: errorMessage,
        })
      )
  }

  const handleUpdate = () => {
    if (!moduleId) return

    doRequest(
      `/courses/${ENV.COURSE_ID}/modules/${moduleId}`,
      'PUT',
      responseData => {
        updateModuleUI(moduleElement, state)
        const dialog = new RelockModulesDialog()
        dialog.renderIfNeeded({
          relock_warning: responseData?.context_module?.relock_warning ?? false,
          id: moduleId,
        })
      },
      I18n.t('%{moduleName} settings updated successfully.', {
        moduleName: state.moduleName,
      }),
      I18n.t('Error updating %{moduleName} settings.', {moduleName: state.moduleName})
    )
  }

  const handleCreate = () =>
    doRequest(
      `/courses/${ENV.COURSE_ID}/modules/`,
      'POST',
      res => addModuleUI(res, moduleElement),
      I18n.t('%{moduleName} created successfully.', {
        moduleName: state.moduleName,
      }),
      I18n.t('Error creating %{moduleName}.', {moduleName: state.moduleName})
    )

  const handleSave = () => {
    if (state.moduleName.length === 0) {
      dispatch({
        type: actions.SET_NAME_INPUT_MESSAGES,
        payload: [
          {
            type: 'error',
            text: I18n.t('Module Name is required.'),
          },
        ],
      })
      return
    }

    const callback = moduleId ? handleUpdate : handleCreate

    callback()
  }

  function customOnDismiss() {
    if (!moduleId) {
      // remove the temp module element on cancel
      moduleElement?.remove()
    }
    onDismiss()
  }

  return (
    <Flex direction="column" justifyItems="space-between">
      <LoadingOverlay showLoadingOverlay={loading} mountNode={mountNodeRef.current} />
      <Flex.Item shouldGrow={true} padding="small" size={bodyHeight}>
        <View as="div" padding="small">
          <TextInput
            data-testid="module-name-input"
            renderLabel={I18n.t('Module Name')}
            value={state.moduleName}
            messages={state.nameInputMessages}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
              const {value} = e.target
              dispatch({type: actions.SET_MODULE_NAME, payload: value})
              if (value.trim().length > 0) {
                dispatch({type: actions.SET_NAME_INPUT_MESSAGES, payload: []})
              }
            }}
          />
        </View>
        <View as="div" padding="x-small small">
          <Checkbox
            data-testid="lock-until-checkbox"
            label={I18n.t('Lock Until')}
            checked={state.lockUntilChecked}
            onChange={() =>
              dispatch({type: actions.SET_LOCK_UNTIL_CHECKED, payload: !state.lockUntilChecked})
            }
          />
        </View>
        {state.lockUntilChecked && (
          <View data-testid="lock-until-input" as="div" padding="small">
            <DateTimeInput
              value={state.unlockAt}
              dateRenderLabel={I18n.t('Date')}
              timeRenderLabel={I18n.t('Time')}
              invalidDateTimeMessage={I18n.t('Invalid date!')}
              layout="columns"
              colSpacing="small"
              prevMonthLabel={I18n.t('Previous month')}
              nextMonthLabel={I18n.t('Next month')}
              allowNonStepInput={true}
              onChange={(e, dateTimeString) =>
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
        {availableModules.length > 0 && (
          <View as="div">
            <View as="div" padding="x-small small">
              <PrerequisiteForm
                prerequisites={state.prerequisites}
                availableModules={availableModules}
                onAddPrerequisite={module =>
                  dispatch({
                    type: actions.SET_PREREQUISITES,
                    payload: [...state.prerequisites, module],
                  })
                }
                onDropPrerequisite={index =>
                  dispatch({
                    type: actions.SET_PREREQUISITES,
                    payload: [
                      ...state.prerequisites.slice(0, index),
                      ...state.prerequisites.slice(index + 1),
                    ],
                  })
                }
                onUpdatePrerequisite={(module, index) =>
                  dispatch({
                    type: actions.SET_PREREQUISITES,
                    payload: [
                      ...state.prerequisites.slice(0, index),
                      module,
                      ...state.prerequisites.slice(index + 1),
                    ],
                  })
                }
              />
            </View>
            <hr />
          </View>
        )}
        {moduleItems.length > 0 && (
          <View as="div" padding="x-small small">
            <RequirementForm
              requirements={state.requirements}
              requirementCount={state.requirementCount}
              requireSequentialProgress={state.requireSequentialProgress}
              moduleItems={moduleItems}
              onChangeRequirementCount={type => {
                dispatch({type: actions.SET_REQUIREMENT_COUNT, payload: type})
              }}
              onToggleSequentialProgress={() =>
                dispatch({
                  type: actions.SET_REQUIRE_SEQUENTIAL_PROGRESS,
                  payload: !state.requireSequentialProgress,
                })
              }
              onAddRequirement={requirement => {
                dispatch({
                  type: actions.SET_REQUIREMENTS,
                  payload: [...state.requirements, requirement],
                })
              }}
              onDropRequirement={index => {
                dispatch({
                  type: actions.SET_REQUIREMENTS,
                  payload: [
                    ...state.requirements.slice(0, index),
                    ...state.requirements.slice(index + 1),
                  ],
                })
              }}
              onUpdateRequirement={(requirement, index) => {
                dispatch({
                  type: actions.SET_REQUIREMENTS,
                  payload: [
                    ...state.requirements.slice(0, index),
                    requirement,
                    ...state.requirements.slice(index + 1),
                  ],
                })
              }}
            />
          </View>
        )}
        {enablePublishFinalGrade && (
          <View as="div" padding="small">
            <Checkbox
              label={I18n.t('Publish final grade for the student when this module is completed')}
              checked={state.publishFinalGrade}
              onChange={() =>
                dispatch({type: actions.SET_PUBLISH_FINAL_GRADE, payload: !state.publishFinalGrade})
              }
            />
          </View>
        )}
      </Flex.Item>
      <Flex.Item size={footerHeight}>
        <Footer
          saveButtonLabel={moduleId ? I18n.t('Update Module') : I18n.t('Add Module')}
          onDismiss={customOnDismiss}
          onUpdate={handleSave}
          updateInteraction={state.nameInputMessages.length > 0 ? 'inerror' : 'enabled'}
        />
      </Flex.Item>
    </Flex>
  )
}
