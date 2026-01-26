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

import React, {ReactElement} from 'react'
import {Popover} from '@instructure/ui-popover'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {CloseButton, IconButton} from '@instructure/ui-buttons'
import {IconInfoLine} from '@instructure/ui-icons'
import {TruncateText} from '@instructure/ui-truncate-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Outcome} from '@canvas/outcomes/react/types/rollup'
import {MasteryDistributionChart} from '../charts'

const I18n = createI18nScope('learning_mastery_gradebook')

export interface OutcomeDistributionPopoverProps {
  outcome: Outcome
  scores: (number | undefined)[]
  isOpen: boolean
  onCloseHandler: () => void
  renderTrigger: ReactElement
}

export const OutcomeDistributionPopover: React.FC<OutcomeDistributionPopoverProps> = ({
  outcome,
  scores,
  isOpen,
  onCloseHandler,
  renderTrigger,
}) => {
  return (
    <Popover
      renderTrigger={renderTrigger}
      isShowingContent={isOpen}
      onShowContent={() => {}}
      onHideContent={onCloseHandler}
      on="click"
      screenReaderLabel={I18n.t('Outcome Distribution for %{outcomeName}', {
        outcomeName: outcome.title,
      })}
      shouldContainFocus={true}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={true}
      placement="bottom center"
    >
      <Flex
        as="div"
        direction="column"
        padding="small"
        gap="x-small"
        data-testid="outcome-distribution-popover"
      >
        <Flex as="div" alignItems="start" margin="0 0 small small" justifyItems="space-between">
          <Flex.Item>
            <Heading level="h3">
              <TruncateText>{outcome.title}</TruncateText>
            </Heading>
          </Flex.Item>

          <Flex.Item margin="0 xx-small 0 0">
            <CloseButton
              data-testid="outcome-distribution-popover-close-button"
              onClick={onCloseHandler}
              screenReaderLabel="Close"
              tabIndex={-1}
            />
          </Flex.Item>
        </Flex>

        <View as="div" width="100%">
          <MasteryDistributionChart
            outcome={outcome}
            scores={scores}
            height={280}
            showYAxisGrid={true}
          />
        </View>

        <View as="div" borderWidth="small 0 0 0" borderColor="primary" padding="x-small 0 0 0">
          <Flex justifyItems="start">
            <Flex.Item>
              <IconButton
                data-testid="outcome-distribution-popover-info-button"
                screenReaderLabel={I18n.t('View outcome distribution information')}
                size="small"
                withBackground={false}
                withBorder={true}
                color="primary"
                tabIndex={-1}
              >
                <IconInfoLine />
              </IconButton>
            </Flex.Item>
          </Flex>
        </View>
      </Flex>
    </Popover>
  )
}
