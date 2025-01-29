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
import DifferentiationTagModalForm from './DifferentiationTagModalForm'
import {useDifferentiationTagSet} from '../hooks/useDifferentiationTagSet'

export interface DifferentiationTagModalManagerProps {
  isOpen: boolean
  onClose: () => void
  mode: 'create' | 'edit'
  differentiationTagCategoryId?: number
}

function DifferentiationTagModalContainer(props: DifferentiationTagModalManagerProps) {
  const {isOpen, onClose, mode, differentiationTagCategoryId} = props

  const {data: tagSet} = useDifferentiationTagSet(differentiationTagCategoryId, true)

  return (
    <DifferentiationTagModalForm
      isOpen={isOpen}
      onClose={onClose}
      mode={mode}
      differentiationTagSet={tagSet}
    />
  )
}

export default function DifferentiationTagModalManager(props: DifferentiationTagModalManagerProps) {
  return (
    <QueryProvider>
      <DifferentiationTagModalContainer {...props} />
    </QueryProvider>
  )
}
