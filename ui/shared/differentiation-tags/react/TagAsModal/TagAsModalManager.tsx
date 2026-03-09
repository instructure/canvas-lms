/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import TagAsModal from './TagAsModal'
import {useDifferentiationTagCategoriesIndex} from '../hooks/useDifferentiationTagCategoriesIndex'
import type {Course} from '../types.d'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'

declare const ENV: GlobalEnv & Course

export interface TagAsModalManagerProps {
  isOpen: boolean
  onClose: () => void
  onCreationSuccess?: (groupId: number) => void
  courseId?: number
}

function TagAsModalContainer(props: TagAsModalManagerProps) {
  const {isOpen, onClose, onCreationSuccess, courseId} = props

  const courseID = Number(courseId ?? ENV?.course?.id)
  const hasValidCourseID = typeof courseID === 'number' && !isNaN(courseID)

  const {data} = useDifferentiationTagCategoriesIndex(courseID, {
    includeDifferentiationTags: true,
    enabled: hasValidCourseID,
  })

  const categories = data ?? []

  return (
    <TagAsModal
      isOpen={isOpen}
      onClose={onClose}
      onCreationSuccess={onCreationSuccess}
      categories={categories}
      courseId={courseID}
    />
  )
}

export default function TagAsModalManager(props: TagAsModalManagerProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <TagAsModalContainer {...props} />
    </QueryClientProvider>
  )
}
