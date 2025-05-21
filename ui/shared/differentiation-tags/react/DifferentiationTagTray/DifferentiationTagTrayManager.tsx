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
import DifferentiationTagTray from './DifferentiationTagTray'
import {useDifferentiationTagCategoriesIndex} from '../hooks/useDifferentiationTagCategoriesIndex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'

const I18n = createI18nScope('differentiation_tags')

interface DifferentiationTagTrayManagerProps {
  isOpen: boolean
  onClose: () => void
  courseID: number
}

function DifferentiationTagTrayContainer(props: DifferentiationTagTrayManagerProps) {
  const {isOpen, onClose, courseID} = props
  const hasValidCourseID = typeof courseID === 'number' && !isNaN(courseID)

  const {
    data: differentiationTagCategories,
    isLoading: isHookLoading,
    error: hookError,
  } = useDifferentiationTagCategoriesIndex(courseID, {
    includeDifferentiationTags: true,
    enabled: hasValidCourseID,
  })

  const error = hasValidCourseID ? hookError : new Error(I18n.t('A valid course ID is required.'))
  const isLoading = hasValidCourseID ? isHookLoading : false

  return (
    <DifferentiationTagTray
      isOpen={isOpen}
      onClose={onClose}
      differentiationTagCategories={differentiationTagCategories || []}
      isLoading={isLoading}
      error={error}
    />
  )
}

export default function DifferentiationTagTrayManager({
  isOpen,
  onClose,
  courseID,
}: DifferentiationTagTrayManagerProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <DifferentiationTagTrayContainer
        isOpen={isOpen}
        onClose={onClose}
        courseID={Number(courseID)}
      />
    </QueryClientProvider>
  )
}
