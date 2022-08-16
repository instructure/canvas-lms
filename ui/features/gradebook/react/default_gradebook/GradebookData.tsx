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

import React, {useRef, useEffect} from 'react'
import shallow from 'zustand/shallow'
import {camelize} from 'convert-case'
import Gradebook from './Gradebook'
import PerformanceControls from './PerformanceControls'
import {RequestDispatch} from '@canvas/network'
import useStore from './stores/index'

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
  const flashMessages = useStore(state => state.flashMessages)

  const appliedFilters = useStore(state => state.appliedFilters, shallow)
  const isFiltersLoading = useStore(state => state.isFiltersLoading)
  const initializeStagedFilter = useStore(state => state.initializeStagedFilter)
  const fetchFilters = useStore(state => state.fetchFilters)

  const modules = useStore(state => state.modules)
  const isModulesLoading = useStore(state => state.isModulesLoading)
  const fetchModules = useStore(state => state.fetchModules)

  // Initial state
  // We might be able to do this in gradebook/index.tsx instead
  useEffect(() => {
    useStore.setState({
      courseId,
      dispatch: dispatch.current,
      performanceControls: performanceControls.current
    })
  }, [courseId, props.gradebookEnv.enhanced_gradebook_filters])

  // Data loading logic goes here
  useEffect(() => {
    if (props.gradebookEnv.enhanced_gradebook_filters) {
      fetchFilters()
        .then(() => {
          initializeStagedFilter(
            props.gradebookEnv.settings.filter_rows_by || {},
            props.gradebookEnv.settings.filter_columns_by || {}
          )
        })
        .catch(error => {
          // eslint-disable-next-line no-console
          console.error(error)
        })
    }
    if (props.gradebookEnv.has_modules) {
      fetchModules()
    }
  }, [
    fetchFilters,
    fetchModules,
    props.gradebookEnv.enhanced_gradebook_filters,
    props.gradebookEnv.has_modules,
    initializeStagedFilter,
    props.gradebookEnv.settings.filter_rows_by,
    props.gradebookEnv.settings.filter_columns_by
  ])

  return (
    <Gradebook
      {...props}
      flashAlerts={flashMessages}
      hideGrid={false}
      appliedFilters={appliedFilters}
      isFiltersLoading={isFiltersLoading}
      isModulesLoading={isModulesLoading}
      modules={modules}
      // when the rest of DataLoader is moved we can remove these
      performanceControls={performanceControls.current}
      dispatch={dispatch.current}
    />
  )
}
