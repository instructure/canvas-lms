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

import React, {useCallback, useEffect, useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import Footer from './Footer'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import ModuleAssignments, {AssigneeOption} from './ModuleAssignments'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Spinner} from '@instructure/ui-spinner'
import {generateAssignmentOverridesPayload, updateModuleUI} from '../utils/assignToHelper'
import {AssignmentOverride} from './types'

const I18n = useI18nScope('differentiated_modules')

export interface AssignToPanelProps {
  bodyHeight: string
  footerHeight: string
  courseId: string
  moduleId: string
  moduleElement: HTMLDivElement
  onDismiss: () => void
}

interface Option {
  value: string
  getLabel: () => string
  getDescription: () => string
}

const OPTIONS: Option[] = [
  {
    value: 'everyone',
    getLabel: () => I18n.t('Everyone'),
    getDescription: () => I18n.t('This module will be visible to everyone.'),
  },
  {
    value: 'custom',
    getLabel: () => I18n.t('Custom Access'),
    getDescription: () =>
      I18n.t('Create custom access and optionally set Lock Until date for each group.'),
  },
]

export default function AssignToPanel({
  bodyHeight,
  footerHeight,
  courseId,
  moduleId,
  moduleElement,
  onDismiss,
}: AssignToPanelProps) {
  const [selectedOption, setSelectedOption] = useState<string>(OPTIONS[0].value)
  const [selectedAssignees, setSelectedAssignees] = useState<AssigneeOption[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [defaultValues, setDefaultValues] = useState<AssigneeOption[]>([])

  useEffect(() => {
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
        setDefaultValues(parsedOptions)
        if (parsedOptions.length > 0) {
          setSelectedOption(OPTIONS[1].value)
        }
      })
      .catch(showFlashError())
      .finally(() => {
        setIsLoading(false)
      })
  }, [courseId, moduleId])

  const handleSelect = useCallback((newSelectedAssignees: AssigneeOption[]) => {
    setSelectedAssignees(newSelectedAssignees)
  }, [])

  const handleSave = useCallback(() => {
    setIsLoading(true)
    const payload = generateAssignmentOverridesPayload(selectedAssignees)
    doFetchApi({
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
        onDismiss()
      })
      .catch((err: Error) => {
        setIsLoading(false)
        showFlashAlert({
          err,
          message: I18n.t('Error updating module access.'),
        })
      })
  }, [courseId, moduleElement, moduleId, onDismiss, selectedAssignees])

  const handleClick = useCallback((event: React.MouseEvent<HTMLInputElement>) => {
    const value = (event.target as HTMLInputElement).value
    if (value === OPTIONS[0].value) {
      setSelectedAssignees([])
    }
    setSelectedOption(value)
  }, [])

  if (isLoading) return <Spinner renderTitle={I18n.t('Loading')} size="small" />

  return (
    <Flex direction="column" justifyItems="start">
      <Flex.Item padding="medium medium small" size={bodyHeight}>
        <Flex direction="column" justifyItems="start">
          <Flex.Item>
            <Text>
              {I18n.t('By default everyone in this course has assigned access to this module.')}
            </Text>
          </Flex.Item>
          <Flex.Item overflowX="hidden">
            <RadioInputGroup description={I18n.t('Select Access Type')} name="access_type">
              {OPTIONS.map(option => (
                <Flex key={option.value}>
                  <Flex.Item align="start">
                    <View as="div" margin="none">
                      <RadioInput
                        data-testid={`${option.value}-option`}
                        value={option.value}
                        checked={selectedOption === option.value}
                        onClick={handleClick}
                        label={<ScreenReaderContent>{option.getLabel()}</ScreenReaderContent>}
                      />
                    </View>
                  </Flex.Item>
                  <Flex.Item>
                    <View as="div" margin="none">
                      <Text>{option.getLabel()}</Text>
                    </View>
                    <View as="div" margin="none">
                      <Text color="secondary" size="small">
                        {option.getDescription()}
                      </Text>
                    </View>
                    {option.value === OPTIONS[1].value && selectedOption === OPTIONS[1].value && (
                      <View as="div" margin="small large none none">
                        <ModuleAssignments
                          courseId={courseId}
                          onSelect={handleSelect}
                          defaultValues={defaultValues}
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
          saveButtonLabel={moduleId ? I18n.t('Update Module') : I18n.t('Add Module')}
          onDismiss={onDismiss}
          onUpdate={handleSave}
        />
      </Flex.Item>
    </Flex>
  )
}
