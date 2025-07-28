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

import {forwardRef, useCallback, useImperativeHandle, useRef, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import useManagedCourseSearchApi, {
  isSearchableTerm,
  MINIMUM_SEARCH_LENGTH,
} from '@canvas/direct-sharing/react/effects/useManagedCourseSearchApi'
import SearchItemSelector from '../../../components/shared/SearchItemSelector'
import useModuleCourseSearchApi from '@canvas/direct-sharing/react/effects/useModuleCourseSearchApi'
import ModulePositionPicker from './ModulePositionPicker'
import {type Module, type Course} from './DirectShareCourseTray'

const I18n = createI18nScope('files_v2')

type DirectShareCoursePanelProps = {
  selectedCourseId?: string | null
  onSelectCourse: (course: Course | null) => void
  selectedModuleId?: string | null
  onSelectModule: (module: Module | null) => void
  onSelectPosition?: (position: number | null) => void
}

export type DirectShareCoursePanelPropsRef = {
  validate: () => boolean
}

const DirectShareCoursePanel = forwardRef<
  DirectShareCoursePanelPropsRef,
  DirectShareCoursePanelProps
>(({selectedCourseId, onSelectCourse, selectedModuleId, onSelectModule, onSelectPosition}, ref) => {
  const courseInputRef = useRef<HTMLInputElement | null>(null)
  const [error, setError] = useState<string | null>(null)

  useImperativeHandle(ref, () => ({
    validate: () => {
      let valid = true
      if (!selectedCourseId) {
        valid = false
        courseInputRef.current?.focus()
        setError(I18n.t('A course needs to be selected'))
      }
      return valid
    },
  }))

  const handleInputChanged = useCallback(() => setError(null), [])

  const handleSelectCourse = useCallback(
    (course: Course | null) => {
      onSelectCourse?.(course)
      setError(null)
    },
    [onSelectCourse],
  )

  const handleSelectPosition = useCallback(
    (position: number | null) => onSelectPosition?.(position),
    [onSelectPosition],
  )

  const handleInputRef = useCallback((inputElement: HTMLInputElement | null) => {
    courseInputRef.current = inputElement
    // Removes the canvas default styles for invalid inputs
    inputElement?.removeAttribute('required')
  }, [])

  const renderCourseOption = useCallback(
    (item: Course) => (
      <View>
        <TruncateText maxLines={2} truncate="word">
          <Text weight="bold">{item.name}</Text>
        </TruncateText>
        <View as="p" margin="xxx-small none none" padding="none">
          <TruncateText>
            <Text size="small" color="secondary">
              {item.course_code} | {item.term}
            </Text>
          </TruncateText>
        </View>
      </View>
    ),
    [],
  )

  return (
    <>
      <View as="div" margin="0 0 small 0">
        <SearchItemSelector<Course>
          isRequired={true}
          messages={error ? [{text: error, type: 'newError'}] : []}
          inputRef={handleInputRef}
          onInputChanged={handleInputChanged}
          onItemSelected={handleSelectCourse}
          renderLabel={I18n.t('Select a Course')}
          // eslint-disable-next-line react-compiler/react-compiler
          itemSearchFunction={useManagedCourseSearchApi}
          additionalParams={{include: '', enforce_manage_grant_requirement: true}}
          minimumSearchLength={MINIMUM_SEARCH_LENGTH}
          isSearchableTerm={isSearchableTerm}
          renderOption={renderCourseOption}
          fetchErrorMessage={I18n.t('Error retrieving courses')}
        />
      </View>

      {selectedCourseId && (
        <View as="div" margin="0 0 small 0">
          <SearchItemSelector<Module>
            onItemSelected={onSelectModule}
            renderLabel={I18n.t('Select a Module (optional)')}
            // eslint-disable-next-line react-compiler/react-compiler
            itemSearchFunction={useModuleCourseSearchApi}
            contextId={selectedCourseId}
            minimumSearchLength={MINIMUM_SEARCH_LENGTH}
            isSearchableTerm={isSearchableTerm}
            additionalParams={{include: '', enforce_manage_grant_requirement: true, per_page: 50}}
            fetchErrorMessage={I18n.t('Error retrieving modules')}
          />
        </View>
      )}

      {selectedCourseId && selectedModuleId && (
        <ModulePositionPicker
          courseId={selectedCourseId}
          moduleId={selectedModuleId}
          onSelectPosition={handleSelectPosition}
        />
      )}
    </>
  )
})

export default DirectShareCoursePanel
