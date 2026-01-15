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
import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {IconArrowUpLine, IconArrowDownLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {useScope as createI18nScope} from '@canvas/i18n'
import {openWindow} from '@canvas/util/globalUtils'
import {SortBy, SortOrder} from '@canvas/outcomes/react/utils/constants'
import {ContributingScoreAlignment} from '../../hooks/useContributingScores'
import {Sorting} from '@canvas/outcomes/react/types/shapes'
import {ColumnHeader} from './ColumnHeader'

const I18n = createI18nScope('learning_mastery_gradebook')

export interface ContributingScoreHeaderProps {
  alignment: ContributingScoreAlignment
  courseId: string
  sorting: Sorting
}

export const ContributingScoreHeader: React.FC<ContributingScoreHeaderProps> = ({
  alignment,
  courseId,
  sorting,
}) => {
  const isCurrentlySelected =
    sorting.sortBy === SortBy.ContributingScore &&
    sorting.sortAlignmentId === alignment.alignment_id

  const handleSortAscending = () => {
    sorting.setSortBy(SortBy.ContributingScore)
    sorting.setSortAlignmentId(alignment.alignment_id)
    sorting.setSortOrder(SortOrder.ASC)
  }

  const handleSortDescending = () => {
    sorting.setSortBy(SortBy.ContributingScore)
    sorting.setSortAlignmentId(alignment.alignment_id)
    sorting.setSortOrder(SortOrder.DESC)
  }

  const speedGraderMenuItem = (
    <Menu.Item
      key="speedgrader"
      onClick={() =>
        openWindow(
          `/courses/${courseId}/gradebook/speed_grader?assignment_id=${alignment.associated_asset_id}`,
          '_blank',
        )
      }
    >
      {I18n.t('Open in Speedgrader')}
    </Menu.Item>
  )

  const sortMenuGroup = (
    <Menu.Group key="sort" label={I18n.t('Sort')}>
      <Menu.Item
        onSelect={handleSortAscending}
        selected={isCurrentlySelected && sorting.sortOrder === SortOrder.ASC}
      >
        <Flex gap="x-small">
          <IconArrowUpLine spacing="small" />
          {I18n.t('Ascending scores')}
        </Flex>
      </Menu.Item>
      <Menu.Item
        onSelect={handleSortDescending}
        selected={isCurrentlySelected && sorting.sortOrder === SortOrder.DESC}
      >
        <Flex gap="x-small">
          <IconArrowDownLine spacing="small" />
          {I18n.t('Descending scores')}
        </Flex>
      </Menu.Item>
    </Menu.Group>
  )

  return (
    <ColumnHeader
      title={alignment.associated_asset_name}
      optionsMenuTriggerLabel={I18n.t('Contributing Score Menu')}
      optionsMenuItems={[speedGraderMenuItem, sortMenuGroup]}
    />
  )
}
