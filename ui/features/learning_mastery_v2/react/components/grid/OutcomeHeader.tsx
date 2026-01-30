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
import useModal from '@canvas/outcomes/react/hooks/useModal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SortBy, SortOrder} from '@canvas/outcomes/react/utils/constants'
import {Outcome} from '@canvas/outcomes/react/types/rollup'
import {Sorting} from '@canvas/outcomes/react/types/shapes'
import {OutcomeDescriptionModal} from '../modals/OutcomeDescriptionModal'
import {OutcomeDistributionPopover} from '../popovers/OutcomeDistributionPopover'
import {DragDropConnectorProps} from './DragDropWrapper'
import {ContributingScoresForOutcome} from '@canvas/outcomes/react/hooks/useContributingScores'
import {ColumnHeader} from './ColumnHeader'

const I18n = createI18nScope('learning_mastery_gradebook')

export interface OutcomeHeaderProps extends DragDropConnectorProps {
  outcome: Outcome
  sorting: Sorting
  contributingScoresForOutcome: ContributingScoresForOutcome
  scores: (number | undefined)[]
}

export const OutcomeHeader: React.FC<OutcomeHeaderProps> = ({
  outcome,
  sorting,
  contributingScoresForOutcome,
  scores,
}) => {
  // OD => OutcomeDescription
  const [isODModalOpen, openODModal, closeODModal] = useModal() as [boolean, () => void, () => void]
  // ODP => OutcomeDistributionPopover
  const [isODPOpen, openODP, closeODP] = useModal() as [boolean, () => void, () => void]

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

  const sortMenuGroup = (
    <Menu.Group label={I18n.t('Sort')} key="sort">
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
    </Menu.Group>
  )

  const displayMenuGroup = (
    <Menu.Group label={I18n.t('Display')} key="display">
      <Menu.Item onClick={contributingScoresForOutcome.toggleVisibility}>
        {contributingScoresForOutcome.isVisible()
          ? I18n.t('Hide Contributing Scores')
          : I18n.t('Show Contributing Scores')}
      </Menu.Item>
      <Menu.Item onClick={openODModal}>{I18n.t('Outcome Info')}</Menu.Item>
      <Menu.Item onClick={openODP}>{I18n.t('Show Outcome Distribution')}</Menu.Item>
    </Menu.Group>
  )

  return (
    <>
      <ColumnHeader
        title={outcome.title}
        optionsMenuTriggerLabel={I18n.t('%{outcome} options', {outcome: outcome.title})}
        optionsMenuItems={[sortMenuGroup, <Menu.Separator key="separator" />, displayMenuGroup]}
      />

      <OutcomeDescriptionModal
        outcome={outcome}
        isOpen={isODModalOpen}
        onCloseHandler={closeODModal}
      />

      {isODPOpen && (
        <OutcomeDistributionPopover
          outcome={outcome}
          scores={scores}
          isOpen={isODPOpen}
          onCloseHandler={closeODP}
          renderTrigger={<span />}
        />
      )}
    </>
  )
}
