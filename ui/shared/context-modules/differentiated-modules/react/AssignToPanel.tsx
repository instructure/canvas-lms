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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import Footer from './Footer'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import ModuleAssignments, {type AssigneeOption} from './ModuleAssignments'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import {generateAssignmentOverridesPayload, updateModuleUI} from '../utils/assignToHelper'
import type {AssignmentOverride} from './types'
import LoadingOverlay from './LoadingOverlay'
import type {FormMessage} from '@instructure/ui-form-field'

const I18n = useI18nScope('differentiated_modules')

export type AssignToPanelProps = {
  bodyHeight: string
  footerHeight: string
  courseId: string
  moduleId: string
  moduleElement: HTMLDivElement
  onDismiss: () => void
  mountNodeRef: React.RefObject<HTMLElement>
  updateParentData?: (
    data: {selectedOption: OptionValue; selectedAssignees: AssigneeOption[]},
    changed: boolean
  ) => void
  defaultOption?: OptionValue
  defaultAssignees?: AssigneeOption[]
  onDidSubmit?: () => void
}

export type OptionValue = 'everyone' | 'custom'

type Option = {
  value: OptionValue
  getLabel: () => string
  getDescription: () => string
}

const EVERYONE_OPTION: Option = {
  value: 'everyone',
  getLabel: () => I18n.t('Everyone'),
  getDescription: () => I18n.t('This module is visible to everyone.'),
}

const CUSTOM_OPTION: Option = {
  value: 'custom',
  getLabel: () => I18n.t('Assign To'),
  getDescription: () => I18n.t('Assign module to individuals or sections.'),
}

const EMPTY_ASSIGNEE_ERROR_MESSAGE: FormMessage = {
  text: I18n.t('A student or section must be selected'),
  type: 'error',
}

export const updateModuleAssignees = ({
  courseId,
  moduleId,
  moduleElement,
  selectedAssignees,
}: {
  courseId: string
  moduleId: string
  moduleElement: HTMLDivElement
  selectedAssignees: AssigneeOption[]
}) => {
  const payload = generateAssignmentOverridesPayload(selectedAssignees)
  return doFetchApi({
    path: `/api/v1/courses/${courseId}/modules/${moduleId}/assignment_overrides`,
    method: 'PUT',
    body: payload,
  })
    .then(() => {
      showFlashAlert({
        type: 'success',
        message: I18n.t('Module access updated successfully.'),
      })
      updateModuleUI(moduleElement, payload)
    })
    .catch((err: Error) => {
      showFlashAlert({
        err,
        message: I18n.t('Error updating module access.'),
      })
    })
}

export default function AssignToPanel({
  bodyHeight,
  footerHeight,
  courseId,
  moduleId,
  moduleElement,
  mountNodeRef,
  onDismiss,
  updateParentData,
  defaultOption,
  defaultAssignees,
  onDidSubmit,
}: AssignToPanelProps) {
  const [selectedOption, setSelectedOption] = useState<OptionValue>(
    defaultOption || EVERYONE_OPTION.value
  )
  const [selectedAssignees, setSelectedAssignees] = useState<AssigneeOption[]>(
    defaultAssignees || []
  )
  const [isLoading, setIsLoading] = useState(false)
  const changed = useRef(false)
  const [suppressEmptyAssigneeError, setSuppressEmptyAssigneeError] = useState(true)
  const [errors, setErrors] = useState<FormMessage[]>([])
  const assigneeSelectorRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    // If defaultOption and defaultAssignees are passed, there is no need to fetch the data again.
    if (defaultOption && Array.isArray(defaultAssignees)) {
      setSelectedOption(defaultOption)
      return
    }

    setIsLoading(true)
    doFetchApi({
      path: `/api/v1/courses/${courseId}/modules/${moduleId}/assignment_overrides`,
    })
      .then((data: any) => {
        if (data.json === undefined) return
        const json = data.json as AssignmentOverride[]
        const parsedOptions = json.reduce((acc: AssigneeOption[], override: AssignmentOverride) => {
          const overrideOptions =
            override.students?.map(({id, name}: {id: string; name: string}) => ({
              id: `student-${id}`,
              overrideId: override.id,
              value: name,
              group: I18n.t('Students'),
            })) ?? []
          if (override.course_section !== undefined) {
            const sectionId = `section-${override.course_section.id}`
            overrideOptions.push({
              id: sectionId,
              overrideId: override.id,
              value: override.course_section.name,
              group: I18n.t('Sections'),
            })
          }
          return [...acc, ...overrideOptions]
        }, [])
        setSelectedAssignees(parsedOptions)

        // If the user manually selected an option, we should keep it after switching tabs.
        if (!defaultOption && parsedOptions.length > 0) {
          setSelectedOption(CUSTOM_OPTION.value)
        }
      })
      .catch(showFlashError())
      .finally(() => {
        setIsLoading(false)
      })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const visibleErrors = errors.filter(error => {
    // hide empty assignee error on initial load
    if (error === EMPTY_ASSIGNEE_ERROR_MESSAGE) {
      return !suppressEmptyAssigneeError
    }
    return true
  })
  const hasErrors = errors.length > 0
  const hasVisibleErrors = visibleErrors.length > 0

  const handleSave = useCallback(() => {
    setSuppressEmptyAssigneeError(false)
    if (hasErrors) {
      assigneeSelectorRef.current?.focus()
      return
    }
    setIsLoading(true)
    // eslint-disable-next-line promise/catch-or-return
    updateModuleAssignees({courseId, moduleId, moduleElement, selectedAssignees})
      .finally(() => setIsLoading(false))
      .then(() => (onDidSubmit ? onDidSubmit() : onDismiss()))
  }, [hasErrors, courseId, moduleId, moduleElement, selectedAssignees, onDidSubmit, onDismiss])

  const handleChange = useCallback((event: React.ChangeEvent<HTMLInputElement>) => {
    const value = (event.target as HTMLInputElement).value
    if (value === EVERYONE_OPTION.value) {
      setSelectedAssignees([])
    }
    setSelectedOption(value as OptionValue)
    changed.current = true
  }, [])

  // Sends data to parent when unmounting
  useEffect(
    () => () => updateParentData?.({selectedOption, selectedAssignees}, changed.current),
    [selectedOption, selectedAssignees, updateParentData]
  )

  // cannot handle in onSelect because of infinite rerenders due to messages prop
  useEffect(() => {
    const newErrors = []
    if (selectedOption === CUSTOM_OPTION.value && selectedAssignees.length === 0) {
      newErrors.push(EMPTY_ASSIGNEE_ERROR_MESSAGE)
    }
    setErrors(newErrors)
  }, [selectedAssignees, selectedOption])

  const handleBlur = () => {
    setSuppressEmptyAssigneeError(false)
  }

  return (
    <Flex direction="column">
      <LoadingOverlay showLoadingOverlay={isLoading} mountNode={mountNodeRef.current} />
      <Flex.Item padding="medium medium small" size={bodyHeight}>
        <Flex direction="column">
          <Flex.Item>
            <Text>{I18n.t('By default, this module is visible to everyone.')}</Text>
          </Flex.Item>
          <Flex.Item overflowX="hidden" margin="small 0 0 0">
            <RadioInputGroup description={I18n.t('Set Visibility')} name="access_type">
              {[EVERYONE_OPTION, CUSTOM_OPTION].map(option => (
                <Flex key={option.value} margin="0 xx-small 0 0">
                  <Flex.Item align="start">
                    <View as="div" margin="xx-small">
                      <RadioInput
                        data-testid={`${option.value}-option`}
                        value={option.value}
                        checked={selectedOption === option.value}
                        onChange={handleChange}
                        label={<ScreenReaderContent>{option.getLabel()}</ScreenReaderContent>}
                      />
                    </View>
                  </Flex.Item>
                  <Flex.Item shouldGrow={true} shouldShrink={true}>
                    <View as="div">
                      <Text>{option.getLabel()}</Text>
                    </View>
                    <View as="div">
                      <Text color="secondary" size="small">
                        {option.getDescription()}
                      </Text>
                    </View>
                    {option.value === CUSTOM_OPTION.value &&
                      selectedOption === CUSTOM_OPTION.value && (
                        <View as="div" margin="small 0 0">
                          <ModuleAssignments
                            inputRef={el => (assigneeSelectorRef.current = el)}
                            messages={visibleErrors}
                            courseId={courseId}
                            onSelect={assignees => {
                              // i.e., if there's existing assignees and the user is removing all of them
                              if (selectedAssignees.length > 0 && assignees.length === 0) {
                                setSuppressEmptyAssigneeError(false)
                              }
                              setSelectedAssignees(assignees)
                              changed.current = true
                            }}
                            defaultValues={selectedAssignees}
                            onDismiss={onDismiss}
                            onBlur={handleBlur}
                          />
                        </View>
                      )}
                  </Flex.Item>
                </Flex>
              ))}
            </RadioInputGroup>
          </Flex.Item>
        </Flex>
      </Flex.Item>
      <Flex.Item margin="auto none none none" size={footerHeight}>
        <Footer
          hasErrors={hasVisibleErrors}
          saveButtonLabel={moduleId ? I18n.t('Save') : I18n.t('Add Module')}
          onDismiss={onDismiss}
          onUpdate={handleSave}
        />
      </Flex.Item>
    </Flex>
  )
}
