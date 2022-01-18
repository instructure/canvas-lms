/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useRef} from 'react'
import {camelize} from 'convert-case'
import Gradebook from './Gradebook'
import PerformanceControls from './PerformanceControls'
import {RequestDispatch} from '@canvas/network'
import useModules from './hooks/useModules'
import useFilters from './hooks/useFilters'

export default function GradebookData(props) {
  const performanceControls = useRef(
    new PerformanceControls(camelize(props.gradebookEnv.performance_controls))
  )
  const dispatch = useRef(
    new RequestDispatch({
      activeRequestLimit: performanceControls.current.activeRequestLimit
    })
  )
  const courseId = props.gradebookEnv.context_id
  const {
    data: modules,
    errors: modulesErrors,
    loading: isModulesLoading
  } = useModules(
    dispatch.current,
    courseId,
    performanceControls.contextModulesPerPage,
    props.gradebookEnv.has_modules
  )

  const {
    data: filters,
    errors: filtersErrors,
    loading: isFiltersLoading,
    setData: handleFiltersChange
  } = useFilters(courseId, props.gradebookEnv.enhanced_gradebook_filters)

  return (
    <Gradebook
      {...props}
      flashAlerts={[...modulesErrors, ...filtersErrors]}
      filters={filters}
      isFiltersLoading={isFiltersLoading}
      isModulesLoading={isModulesLoading}
      modules={modules}
      // when the rest of DataLoader is moved we can remove these
      performanceControls={performanceControls.current}
      dispatch={dispatch.current}
      onFiltersChange={handleFiltersChange}
    />
  )
}
