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
import React, {useMemo} from 'react'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenDownLine, IconArrowUpLine, IconArrowDownLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {TruncateText} from '@instructure/ui-truncate-text'
import useModal from '@canvas/outcomes/react/hooks/useModal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CELL_HEIGHT, COLUMN_WIDTH, SortBy, SortOrder} from '../../utils/constants'
import {Outcome} from '../../types/rollup'
import {Sorting} from '../../types/shapes'
import {OutcomeDescriptionModal} from '../modals/OutcomeDescriptionModal'
import {DragDropConnectorProps} from './DragDropWrapper'

const I18n = createI18nScope('learning_mastery_gradebook')

export interface OutcomeHeaderProps extends DragDropConnectorProps {
  outcome: Outcome
  sorting: Sorting
}

export const OutcomeHeader: React.FC<OutcomeHeaderProps> = ({
  outcome,
  sorting,
  connectDragSource,
  connectDropTarget,
  isDragging,
}) => {
  // OD => OutcomeDescription
  const [isODModalOpen, openODModal, closeODModal] = useModal() as [boolean, () => void, () => void]

  const isCurrentlySelected =
    sorting.sortBy === SortBy.Outcome && sorting.sortOutcomeId === String(outcome.id)

  const handleSortAscending = () => {
    sorting.setSortBy(SortBy.Outcome)
    sorting.setSortOutcomeId(String(outcome.id))
    sorting.setSortOrder(SortOrder.ASC)
  }

  const handleSortDescending = () => {
    sorting.setSortBy(SortBy.Outcome)
    sorting.setSortOutcomeId(String(outcome.id))
    sorting.setSortOrder(SortOrder.DESC)
  }

  const headerStyle = useMemo(
    () => ({
      opacity: isDragging ? 0.5 : 1,
      cursor: 'grab',
      transition: 'opacity 0.15s ease-in-out',
    }),
    [isDragging],
  )

  const headerContent = (
    <div style={headerStyle}>
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
              <Text weight="bold">{outcome.title}</Text>
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
                  screenReaderLabel={I18n.t('Sort Outcome Column')}
                >
                  <IconArrowOpenDownLine />
                </IconButton>
              }
            >
              <Menu.Group label={I18n.t('Sort')}></Menu.Group>
              <Menu.Item
                onClick={handleSortAscending}
                selected={isCurrentlySelected && sorting.sortOrder === SortOrder.ASC}
              >
                <Flex gap="x-small">
                  <IconArrowUpLine spacing="small" />
                  {I18n.t('Ascending scores')}
                </Flex>
              </Menu.Item>
              <Menu.Item
                onClick={handleSortDescending}
                selected={isCurrentlySelected && sorting.sortOrder === SortOrder.DESC}
              >
                <Flex gap="x-small">
                  <IconArrowDownLine spacing="small" />
                  {I18n.t('Descending scores')}
                </Flex>
              </Menu.Item>
              <Menu.Separator />
              <Menu.Group label={I18n.t('Display')}>
                <Menu.Item>{I18n.t('Hide Contributing Scores')}</Menu.Item>
                <Menu.Item onClick={openODModal}>{I18n.t('Outcome Info')}</Menu.Item>
                <Menu.Item>{I18n.t('Show Outcome Distribution')}</Menu.Item>
              </Menu.Group>
            </Menu>
          </Flex.Item>
        </Flex>
      </View>
    </div>
  )

  return (
    <>
      {connectDragSource && connectDropTarget
        ? connectDragSource(connectDropTarget(headerContent))
        : headerContent}

      <OutcomeDescriptionModal
        outcome={outcome}
        isOpen={isODModalOpen}
        onCloseHandler={closeODModal}
      />
    </>
  )
}
