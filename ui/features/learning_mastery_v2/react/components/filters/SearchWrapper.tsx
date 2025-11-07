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
import {StudentSearch} from './StudentSearch'
import {Flex} from '@instructure/ui-flex'

interface SearchWrapperProps {
  courseId: string
  selectedUserIds: number[]
  onSelectedUserIdsChange: (userIds: number[]) => void
}

export const SearchWrapper: React.FC<SearchWrapperProps> = ({
  courseId,
  selectedUserIds,
  onSelectedUserIdsChange,
}) => {
  return (
    <Flex gap="small" margin="small none">
      <StudentSearch
        courseId={courseId}
        selectedUserIds={selectedUserIds}
        onSelectedUserIdsChange={onSelectedUserIdsChange}
      />
    </Flex>
  )
}
