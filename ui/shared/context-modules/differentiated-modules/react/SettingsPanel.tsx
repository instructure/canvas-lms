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

import React, {useReducer, useMemo, useState, useEffect, useCallback, useRef} from 'react'
import _ from 'lodash'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import PrerequisiteForm from './PrerequisiteForm'
import RequirementForm from './RequirementForm'
import Footer from './Footer'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {defaultState, actions, reducer, type SettingsPanelState} from './settingsReducer'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {convertModuleSettingsForApi} from '../utils/miscHelpers'
import {updateModuleUI} from '../utils/moduleHelpers'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import type {Module, ModuleItem, Requirement} from './types'
import RelockModulesDialog from '@canvas/relock-modules-dialog'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingOverlay from './LoadingOverlay'

const I18n = useI18nScope('differentiated_modules')

export type SettingsPanelProps = {
  bodyHeight: string
  footerHeight: string
  onDismiss: () => void
  moduleElement: HTMLDivElement
  moduleId?: string
  moduleName?: string
  unlockAt?: string
  lockUntilChecked?: boolean
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
  updateParentData?: (data: SettingsPanelState, changed: boolean) => void
  onDidSubmit?: () => void
}

const doRequest = (
  path: string,
  method: string,
  data: any,
  onSuccess: (res: Record<string, any>) => void,
  successMessage: string,
  errorMessage: string
) =>
  doFetchApi({
    path,
    method,
    body: convertModuleSettingsForApi(data),
  })
    .then((response: {json: Record<string, any>}) => {
      onSuccess(response.json)
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

export const updateModule = ({moduleId, moduleElement, data}: any) => {
  if (!moduleId) return Promise.reject(I18n.t('Invalid module id.'))

  return doRequest(
    `/courses/${ENV.COURSE_ID}/modules/${moduleId}`,
    'PUT',
    data,
    responseData => {
      updateModuleUI(moduleElement, data)
      const dialog = new RelockModulesDialog()
      dialog.renderIfNeeded({
        relock_warning: responseData?.context_module?.relock_warning ?? false,
        id: moduleId,
      })
    },
    I18n.t('%{moduleName} settings updated successfully.', {
      moduleName: data.moduleName,
    }),
    I18n.t('Error updating %{moduleName} settings.', {moduleName: data.moduleName})
  )
}

export const createModule = ({moduleElement, addModuleUI, data}: any) =>
  doRequest(
    `/courses/${ENV.COURSE_ID}/modules/`,
    'POST',
    data,
    res => addModuleUI(res, moduleElement),
    I18n.t('%{moduleName} created successfully.', {
      moduleName: data.moduleName,
    }),
    I18n.t('Error creating %{moduleName}.', {moduleName: data.moduleName})
  )

export default function SettingsPanel({
  moduleElement,
  bodyHeight,
  footerHeight,
  onDismiss,
  moduleId,
  moduleName,
  unlockAt,
  lockUntilChecked,
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
  updateParentData,
  onDidSubmit,
}: SettingsPanelProps) {
  const [state, dispatch] = useReducer(reducer, {
    ...defaultState,
    moduleName: moduleName ?? '',
    unlockAt: unlockAt ?? new Date().toISOString(),
    lockUntilChecked: lockUntilChecked ?? !!unlockAt,
    prerequisites: prerequisites ?? [],
    requirements: requirements ?? [],
    requirementCount: requirementCount ?? 'all',
    requireSequentialProgress: requireSequentialProgress ?? false,
    publishFinalGrade: publishFinalGrade ?? false,
  })
  const initialState = useRef(_.cloneDeep(state))
  const nameInputRef = useRef<HTMLInputElement | null>(null)
  const dateInputRef = useRef<HTMLInputElement | null>(null)

  const [loading, setLoading] = useState(false)
  const [validDate, setValidDate] = useState(true)

  const hasErrors = () => {
    return (
      state.nameInputMessages.length > 0 ||
      (state.lockUntilChecked && (state.lockUntilInputMessages.length > 0 || !validDate))
    )
  }
  const availableModules = useMemo(() => {
    const cutoffIndex = moduleList.findIndex(module => module.name === moduleName)
    return cutoffIndex === -1 ? moduleList : moduleList.slice(0, cutoffIndex)
  }, [moduleList, moduleName])

  const handleLockUntilError = useCallback(() => {
    if (state.lockUntilInputMessages.length > 0) return
    dispatch({
      type: actions.SET_LOCK_UNTIL_INPUT_MESSAGES,
      payload: [
        {
          type: 'error',
          text: I18n.t('Unlock date can’t be blank'),
        },
      ],
    })
  }, [state.lockUntilInputMessages])

  const handleNameError = useCallback(() => {
    if (state.nameInputMessages.length > 0) return
    dispatch({
      type: actions.SET_NAME_INPUT_MESSAGES,
      payload: [
        {
          type: 'error',
          text: I18n.t('Module name can’t be blank'),
        },
      ],
    })
  }, [state.nameInputMessages])

  const handleSave = useCallback(() => {
    // check for errors
    if (state.moduleName.trim().length === 0) {
      handleNameError()
      nameInputRef.current?.focus()
      return
    }
    if (state.lockUntilChecked && state.unlockAt === undefined) {
      dateInputRef.current?.focus()
      return
    }

    const handleRequest = moduleId ? updateModule : createModule

    setLoading(true)
    // eslint-disable-next-line promise/catch-or-return
    handleRequest({moduleId, moduleElement, addModuleUI, data: state})
      .finally(() => setLoading(false))
      .then(() => (onDidSubmit ? onDidSubmit() : onDismiss()))
  }, [state, moduleId, moduleElement, addModuleUI, handleNameError, onDidSubmit, onDismiss])

  function customOnDismiss() {
    if (!moduleId) {
      // remove the temp module element on cancel
      moduleElement?.remove()
    }
    onDismiss()
  }

  // Sends data to parent when unmounting
  useEffect(
    () => () => updateParentData?.(state, !_.isEqual(initialState.current, state)),
    [state, updateParentData]
  )

  return (
    <Flex direction="column" justifyItems="space-between">
      <LoadingOverlay showLoadingOverlay={loading} mountNode={mountNodeRef.current} />
      <Flex.Item shouldGrow={true} padding="small" size={bodyHeight}>
        <View as="div" padding="small">
          <TextInput
            data-testid="module-name-input"
            renderLabel={I18n.t('Module Name')}
            inputRef={el => (nameInputRef.current = el)}
            value={state.moduleName}
            messages={state.nameInputMessages}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
              const {value} = e.target
              dispatch({type: actions.SET_MODULE_NAME, payload: value})
              if (value.trim().length > 0) {
                dispatch({type: actions.SET_NAME_INPUT_MESSAGES, payload: []})
              }
            }}
            onBlur={() => {
              if (state.moduleName.trim().length === 0) {
                handleNameError()
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
              locale={ENV.LOCALE || 'en'}
              timezone={ENV.TIMEZONE || 'UTC'}
              dateRenderLabel={I18n.t('Date')}
              timeRenderLabel={I18n.t('Time')}
              invalidDateTimeMessage={I18n.t('Invalid date')}
              messages={state.lockUntilInputMessages}
              dateInputRef={el => (dateInputRef.current = el)}
              layout="columns"
              colSpacing="small"
              prevMonthLabel={I18n.t('Previous month')}
              nextMonthLabel={I18n.t('Next month')}
              allowNonStepInput={true}
              onChange={(e, dateTimeString) => {
                dispatch({type: actions.SET_UNLOCK_AT, payload: dateTimeString})
                if (dateTimeString) {
                  setValidDate(true)
                  dispatch({type: actions.SET_LOCK_UNTIL_INPUT_MESSAGES, payload: []})
                } else {
                  setValidDate(false)
                }
              }}
              onBlur={e => {
                const target = e.target as HTMLInputElement
                if (!target) return
                if (target.value.length > 0) {
                  setTimeout(() => {
                    dispatch({type: actions.SET_LOCK_UNTIL_INPUT_MESSAGES, payload: []})
                  }, 1)
                } else {
                  handleLockUntilError()
                }
              }}
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
          saveButtonLabel={moduleId ? I18n.t('Save') : I18n.t('Add Module')}
          onDismiss={customOnDismiss}
          onUpdate={handleSave}
          hasErrors={hasErrors()}
        />
      </Flex.Item>
    </Flex>
  )
}
