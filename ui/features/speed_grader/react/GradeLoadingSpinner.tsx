// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useEffect} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import useStore from '../stores/index'
import type {GradeLoadingData} from '../jquery/speed_grader.d'

const I18n = useI18nScope('speed_grader')

const loadingForStudent = (state: GradeLoadingData) => !!state.gradesLoading[state.currentStudentId]
const loadingStateChanged = (oldState: GradeLoadingData, newState: GradeLoadingData) =>
  loadingForStudent(oldState) === loadingForStudent(newState)

type Props = {
  onLoadingChange: (loading: boolean) => void
}

export default function GradeLoadingSpinner({onLoadingChange}: Props) {
  const {currentStudentId, gradesLoading} = useStore(
    state => ({currentStudentId: state.currentStudentId, gradesLoading: state.gradesLoading}),
    loadingStateChanged
  )

  useEffect(() => {
    const loading = loadingForStudent({currentStudentId, gradesLoading})
    onLoadingChange(loading)
  }, [currentStudentId, gradesLoading, onLoadingChange])

  const isLoading = gradesLoading[currentStudentId]
  return isLoading ? <Spinner renderTitle={I18n.t('Grade Loading')} /> : null
}
