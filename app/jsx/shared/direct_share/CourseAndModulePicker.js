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

import I18n from 'i18n!course_and_module_picker'

import React from 'react'
import {func, string} from 'prop-types'
import {View} from '@instructure/ui-view'

import useManagedCourseSearchApi from '../effects/useManagedCourseSearchApi'
import useModuleCourseSearchApi from '../effects/useModuleCourseSearchApi'
import SearchItemSelector from 'jsx/shared/components/SearchItemSelector'
import ModulePositionPicker from './ModulePositionPicker'

CourseAndModulePicker.propTypes = {
  selectedCourseId: string,
  setSelectedCourse: func,
  selectedModuleId: string,
  setSelectedModule: func,
  setModuleItemPosition: func
}

export default function CourseAndModulePicker({
  selectedCourseId,
  setSelectedCourse,
  selectedModuleId,
  setSelectedModule,
  setModuleItemPosition
}) {
  return (
    <>
      <View as="div" padding="0 0 small 0">
        <SearchItemSelector
          onItemSelected={setSelectedCourse}
          renderLabel={I18n.t('Select a Course')}
          itemSearchFunction={useManagedCourseSearchApi}
        />
      </View>
      <View as="div" padding="0 0 small 0">
        {selectedCourseId && (
          <SearchItemSelector
            onItemSelected={setSelectedModule}
            renderLabel={I18n.t('Select a Module (optional)')}
            itemSearchFunction={useModuleCourseSearchApi}
            contextId={selectedCourseId || null}
          />
        )}
      </View>
      {selectedCourseId && selectedModuleId && (
        <ModulePositionPicker
          courseId={selectedCourseId || null}
          moduleId={selectedModuleId || null}
          setModuleItemPosition={setModuleItemPosition}
        />
      )}
    </>
  )
}
