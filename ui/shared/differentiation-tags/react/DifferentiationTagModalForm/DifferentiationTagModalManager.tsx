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

import React from 'react'
import DifferentiationTagModalForm from './DifferentiationTagModalForm'
import {useDifferentiationTagCategoriesIndex} from '../hooks/useDifferentiationTagCategoriesIndex'
import type {Course, DifferentiationTagCategory} from '../types.d'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'

declare const ENV: GlobalEnv & Course

export interface DifferentiationTagModalManagerProps {
  isOpen: boolean
  onClose: () => void
  mode: 'create' | 'edit'
  differentiationTagCategoryId?: number
}

function DifferentiationTagModalContainer(props: DifferentiationTagModalManagerProps) {
  const {isOpen, onClose, mode, differentiationTagCategoryId} = props

  const courseID = Number(ENV?.course?.id)
  const hasValidCourseID = typeof courseID === 'number' && !isNaN(courseID)

  const {data} = useDifferentiationTagCategoriesIndex(courseID, {
    includeDifferentiationTags: true,
    enabled: hasValidCourseID,
  })

  const categories: DifferentiationTagCategory[] = data?.map(({id, name}) => ({id, name})) || []
  const tagSet: DifferentiationTagCategory | undefined = data?.find(
    set => set.id === differentiationTagCategoryId,
  )

  return (
    <DifferentiationTagModalForm
      isOpen={isOpen}
      onClose={onClose}
      mode={mode}
      differentiationTagSet={tagSet}
      categories={categories}
      courseId={courseID}
    />
  )
}

export default function DifferentiationTagModalManager(props: DifferentiationTagModalManagerProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <DifferentiationTagModalContainer {...props} />
    </QueryClientProvider>
  )
}
