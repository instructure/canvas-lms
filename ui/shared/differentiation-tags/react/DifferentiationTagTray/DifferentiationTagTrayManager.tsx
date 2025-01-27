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
import {QueryProvider} from '@canvas/query'
import DifferentiationTagTray from './DifferentiationTagTray'
import {useDifferentiationTagCategoriesIndex} from '../hooks/useDifferentiationTagCategoriesIndex'

interface DifferentiationTagTrayManagerProps {
  isOpen: boolean
  onClose: () => void
  courseID: number
}

function DifferentiationTagTrayContainer({
  isOpen,
  onClose,
  courseID,
}: DifferentiationTagTrayManagerProps) {
  const {
    data: differentiationTagCategories,
    isLoading,
    error,
  } = useDifferentiationTagCategoriesIndex(courseID, true)

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
    <QueryProvider>
      <DifferentiationTagTrayContainer isOpen={isOpen} onClose={onClose} courseID={courseID} />
    </QueryProvider>
  )
}
