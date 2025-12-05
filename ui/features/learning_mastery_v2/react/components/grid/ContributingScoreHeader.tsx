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
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenDownLine, IconArrowUpLine, IconArrowDownLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {TruncateText} from '@instructure/ui-truncate-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {openWindow} from '@canvas/util/globalUtils'
import {CELL_HEIGHT, COLUMN_WIDTH, SortBy, SortOrder} from '../../utils/constants'
import {ContributingScoreAlignment} from '../../hooks/useContributingScores'
import {Sorting} from '../../types/shapes'

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

  return (
    <View
      background="secondary"
      as="div"
      width={COLUMN_WIDTH}
      borderWidth="large 0 medium 0"
      data-testid="outcome-header"
    >
      <Flex alignItems="center" justifyItems="space-between" height={CELL_HEIGHT}>
        <Flex.Item size="80%" padding="0 0 0 small">
          <TruncateText>
            <Text weight="bold">{alignment.associated_asset_name}</Text>
          </TruncateText>
        </Flex.Item>
        <Flex.Item padding="0 small 0 0">
          <Menu
            placement="bottom"
            trigger={
              <IconButton
                withBorder={false}
                withBackground={false}
                size="small"
                screenReaderLabel={I18n.t('Contributing Score Menu')}
              >
                <IconArrowOpenDownLine />
              </IconButton>
            }
          >
            <Menu.Item
              onClick={() =>
                openWindow(
                  `/courses/${courseId}/gradebook/speed_grader?assignment_id=${alignment.associated_asset_id}`,
                  '_blank',
                )
              }
            >
              {I18n.t('Open in Speedgrader')}
            </Menu.Item>
            <Menu.Group label={I18n.t('Sort')}>
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
          </Menu>
        </Flex.Item>
      </Flex>
    </View>
  )
}
