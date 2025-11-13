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
import {OutcomeSearch} from './OutcomeSearch'

interface SearchWrapperProps {
  courseId: string
  selectedUserIds: number[]
  onSelectedUserIdsChange: (userIds: number[]) => void
  selectedOutcomes?: string[]
  onSelectOutcomes: (outcomeIds: string[]) => void
}

export const SearchWrapper: React.FC<SearchWrapperProps> = ({
  courseId,
  selectedUserIds,
  onSelectedUserIdsChange,
  selectedOutcomes,
  onSelectOutcomes,
}) => {
  return (
    <Flex
      width="100%"
      alignItems="center"
      gap="small"
      wrap="no-wrap"
      margin="small none medium none"
    >
      <Flex.Item shouldGrow={true} shouldShrink={true} size="45%">
        <StudentSearch
          courseId={courseId}
          selectedUserIds={selectedUserIds}
          onSelectedUserIdsChange={onSelectedUserIdsChange}
        />
      </Flex.Item>
      <Flex.Item shouldGrow={true} shouldShrink={true} size="45%">
        <OutcomeSearch
          courseId={courseId}
          selectedOutcomes={selectedOutcomes}
          onSelectOutcomes={onSelectOutcomes}
        />
      </Flex.Item>
    </Flex>
  )
}
