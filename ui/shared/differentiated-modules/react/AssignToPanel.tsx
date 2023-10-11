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

import React, {useCallback, useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import Footer from './Footer'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import ModuleAssignments, {AssigneeOption} from './ModuleAssignments'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {Spinner} from '@instructure/ui-spinner'
import {generateAssignmentOverridesPayload} from '../utils/assignToHelper'

const I18n = useI18nScope('differentiated_modules')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item: FlexItem} = Flex as any

export interface AssignToPanelProps {
  courseId: string
  moduleId: string
  height: string
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

export default function AssignToPanel({courseId, moduleId, height, onDismiss}: AssignToPanelProps) {
  const [selectedOption, setSelectedOption] = useState<string>(OPTIONS[0].value)
  const [selectedAssignees, setSelectedAssignees] = useState<AssigneeOption[]>([])
  const [isLoading, setIsLoading] = useState(false)

  const handleSelect = useCallback((newSelectedAssignees: AssigneeOption[]) => {
    setSelectedAssignees(newSelectedAssignees)
  }, [])

  const handleSave = useCallback(() => {
    setIsLoading(true)
    doFetchApi({
      path: `/api/v1/courses/${courseId}/modules/${moduleId}/assignment_overrides`,
      method: 'PUT',
      body: generateAssignmentOverridesPayload(selectedAssignees),
    })
      .then(() => {
        showFlashAlert({
          type: 'success',
          message: I18n.t('Module access updated successfully.'),
        })
        onDismiss()
      })
      .catch((err: Error) => {
        setIsLoading(false)
        showFlashAlert({
          err,
          message: I18n.t('Error updating module access.'),
        })
      })
  }, [courseId, moduleId, onDismiss, selectedAssignees])

  const handleClick = useCallback((event: React.MouseEvent<HTMLInputElement>) => {
    const value = (event.target as HTMLInputElement).value
    if (value === OPTIONS[0].value) {
      setSelectedAssignees([])
    }
    setSelectedOption(value)
  }, [])

  if (isLoading) return <Spinner renderTitle="Loading" size="small" />

  return (
    <Flex direction="column" justifyItems="start" height={height}>
      <FlexItem padding="medium medium small">
        <Text>
          {I18n.t('By default everyone in this course has assigned access to this module.')}
        </Text>
      </FlexItem>
      <FlexItem padding="x-small medium" overflowX="hidden">
        <RadioInputGroup description={I18n.t('Select Access Type')} name="access_type">
          {OPTIONS.map(option => (
            <Flex key={option.value}>
              <FlexItem align="start">
                <View as="div" margin="none">
                  <RadioInput
                    data-testid={`${option.value}-option`}
                    value={option.value}
                    checked={selectedOption === option.value}
                    onClick={handleClick}
                    label={<ScreenReaderContent>{option.getLabel()}</ScreenReaderContent>}
                  />
                </View>
              </FlexItem>
              <FlexItem>
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
                      moduleId={moduleId}
                      onSelect={handleSelect}
                    />
                  </View>
                )}
              </FlexItem>
            </Flex>
          ))}
        </RadioInputGroup>
      </FlexItem>
      <FlexItem margin="auto none none none">
        <Footer
          saveButtonLabel={moduleId ? I18n.t('Update Module') : I18n.t('Add Module')}
          onDismiss={onDismiss}
          onUpdate={handleSave}
        />
      </FlexItem>
    </Flex>
  )
}
