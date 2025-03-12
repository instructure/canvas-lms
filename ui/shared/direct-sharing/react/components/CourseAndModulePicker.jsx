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

import {useScope as createI18nScope} from '@canvas/i18n'

import React, {useRef} from 'react'
import {func, string, bool, object} from 'prop-types'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'

import SearchItemSelector from '@canvas/search-item-selector/react/SearchItemSelector'
import useManagedCourseSearchApi, {
  MINIMUM_SEARCH_LENGTH,
  isSearchableTerm,
} from '../effects/useManagedCourseSearchApi'
import useModuleCourseSearchApi from '../effects/useModuleCourseSearchApi'
import ModulePositionPicker from './ModulePositionPicker'
import AssignmentPicker from './AssignmentPicker'

const I18n = createI18nScope('course_and_module_picker')

CourseAndModulePicker.propTypes = {
  selectedCourseId: string,
  setSelectedCourse: func,
  selectedCourseError: bool,
  courseSelectInputRef: func,
  isCourseRequired: bool,
  selectedModuleId: string,
  setSelectedModule: func,
  setSelectedAssignment: func,
  setModuleItemPosition: func,
  disableModuleInsertion: bool,
  showAssignments: bool,
  moduleFilteringOpts: object,
  courseFilteringOpts: object,
}

CourseAndModulePicker.defaultProps = {
  showAssignments: false,
  moduleFilteringOpts: {per_page: 50},
  courseFilteringOpts: {
    include: '',
    enforce_manage_grant_requirement: '',
  },
}

export default function CourseAndModulePicker({
  selectedCourseId,
  setSelectedCourse,
  selectedCourseError,
  courseSelectInputRef,
  isCourseRequired,
  selectedModuleId,
  setSelectedModule,
  setSelectedAssignment,
  setModuleItemPosition,
  disableModuleInsertion,
  showAssignments,
  moduleFilteringOpts,
  courseFilteringOpts,
}) {
  const trayRef = useRef(null)

  moduleFilteringOpts.include = moduleFilteringOpts.include ? 'concluded' : ''
  moduleFilteringOpts.enforce_manage_grant_requirement = moduleFilteringOpts.include ? true : ''

  const messages = selectedCourseError
    ? [{text: I18n.t('Please select a course'), type: 'newError'}]
    : []

  return (
    <div ref={trayRef}>
      <View as="div" padding="0 0 small 0">
        <SearchItemSelector
          onItemSelected={setSelectedCourse}
          renderLabel={I18n.t('Select a Course')}
          itemSearchFunction={useManagedCourseSearchApi}
          additionalParams={courseFilteringOpts}
          mountNodeRef={trayRef}
          minimumSearchLength={MINIMUM_SEARCH_LENGTH}
          id={'direct-share-course-select'}
          isRequired={isCourseRequired}
          messages={messages}
          inputRef={courseSelectInputRef}
          isSearchableTerm={isSearchableTerm}
          renderOption={item => {
            return (
              <View>
                <TruncateText maxLines={2} truncate="word">
                  <Text weight="bold">{item.name}</Text>
                </TruncateText>
                <View as="p" margin="xx-small none none" padding="none">
                  <TruncateText maxLines={2}>
                    <Text>{item.course_code}</Text>
                  </TruncateText>
                </View>
                <View as="p" margin="none" padding="none">
                  <TruncateText maxLines={2}>
                    <Text size="small">{item.term}</Text>
                  </TruncateText>
                </View>
              </View>
            )
          }}
        />
      </View>
      <View as="div" padding="0 0 small 0">
        {selectedCourseId && !disableModuleInsertion && (
          <SearchItemSelector
            onItemSelected={setSelectedModule}
            renderLabel={I18n.t('Select a Module (optional)')}
            itemSearchFunction={useModuleCourseSearchApi}
            contextId={selectedCourseId || null}
            mountNodeRef={trayRef}
            minimumSearchLength={MINIMUM_SEARCH_LENGTH}
            isSearchableTerm={isSearchableTerm}
            additionalParams={moduleFilteringOpts}
            renderOption={item => {
              return (
                <View>
                  {item.name}
                  <View as="p" margin="none" padding="none">
                    <Text size="small">{item.course_code}</Text>
                  </View>
                </View>
              )
            }}
          />
        )}
      </View>
      {selectedCourseId && selectedModuleId && !disableModuleInsertion && (
        <ModulePositionPicker
          courseId={selectedCourseId || null}
          moduleId={selectedModuleId || null}
          setModuleItemPosition={setModuleItemPosition}
        />
      )}
      <View as="div" padding="0 0 small 0">
        {selectedCourseId && showAssignments && (
          <AssignmentPicker
            courseId={selectedCourseId}
            onAssignmentSelected={setSelectedAssignment}
          />
        )}
      </View>
    </div>
  )
}
