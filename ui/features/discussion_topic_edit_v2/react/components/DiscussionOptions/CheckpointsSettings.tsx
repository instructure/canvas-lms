/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import React, {useContext, useRef} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {NumberInput} from '@instructure/ui-number-input'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconInfoLine} from '@instructure/ui-icons'
import theme from '@instructure/canvas-theme'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {PointsPossible} from './PointsPossible'
import {
  DiscussionDueDatesContext,
  minimumReplyToEntryRequiredCount,
  maximumReplyToEntryRequiredCount,
} from '../../util/constants'

const I18n = useI18nScope('discussion_create')

const replyToEntryRequiredCountToolTip = I18n.t(
  'The number of additional replies required must be between %{minimumReplies} and %{maximumReplies}.',
  {
    minimumReplies: minimumReplyToEntryRequiredCount,
    maximumReplies: maximumReplyToEntryRequiredCount,
  }
)

export const CheckpointsSettings = () => {
  const {
    pointsPossibleReplyToTopic,
    setPointsPossibleReplyToTopic,
    pointsPossibleReplyToEntry,
    setPointsPossibleReplyToEntry,
    replyToEntryRequiredCount,
    setReplyToEntryRequiredCount,
  } = useContext(DiscussionDueDatesContext)

  return (
    <>
      <View as="div" margin="medium 0">
        <Text size="large">{I18n.t('Checkpoint Settings')}</Text>
      </View>
      <View as="div" margin="0 0 medium 0">
        <PointsPossible
          pointsPossible={pointsPossibleReplyToTopic}
          setPointsPossible={setPointsPossibleReplyToTopic}
          pointsPossibleLabel={I18n.t('Points Possible: Reply to Topic')}
          pointsPossibleDataTestId="points-possible-input-reply-to-topic"
        />
      </View>
      <View as="div" margin="0 0 medium 0">
        <NumberInput
          data-testid="reply-to-entry-required-count"
          renderLabel={
            <>
              <View display="inline-block">
                <Text>{I18n.t('Additional Replies Required')}</Text>
              </View>
              <Tooltip
                renderTip={replyToEntryRequiredCountToolTip}
                on={['hover', 'focus']}
                color="primary"
              >
                <div
                  style={{display: 'inline-block', marginLeft: theme.spacing.xxSmall}}
                  // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
                  tabIndex={0}
                >
                  <IconInfoLine />
                  <ScreenReaderContent>{replyToEntryRequiredCountToolTip}</ScreenReaderContent>
                </div>
              </Tooltip>
            </>
          }
          onIncrement={() => {
            if (replyToEntryRequiredCount + 1 <= maximumReplyToEntryRequiredCount) {
              setReplyToEntryRequiredCount(replyToEntryRequiredCount + 1)
            }
          }}
          onDecrement={() => {
            if (replyToEntryRequiredCount - 1 >= minimumReplyToEntryRequiredCount) {
              setReplyToEntryRequiredCount(replyToEntryRequiredCount - 1)
            }
          }}
          onBlur={event => {
            if (event.target.value === '0') {
              setReplyToEntryRequiredCount(minimumReplyToEntryRequiredCount)
            }
          }}
          value={replyToEntryRequiredCount}
          onChange={event => {
            // don't allow non-numeric values
            if (!/^\d*\.?\d*$/.test(event.target.value)) return
            const valueInt = parseInt(event.target.value, 10)
            const isBackspace = Number.isNaN(valueInt)
            if (
              !isBackspace &&
              (valueInt > maximumReplyToEntryRequiredCount ||
                valueInt < minimumReplyToEntryRequiredCount)
            ) {
              return
            }
            setReplyToEntryRequiredCount(isBackspace ? 0 : valueInt)
          }}
        />
      </View>
      <View as="div" margin="0 0 medium 0">
        <PointsPossible
          pointsPossible={pointsPossibleReplyToEntry}
          setPointsPossible={setPointsPossibleReplyToEntry}
          pointsPossibleLabel={I18n.t('Points Possible: Additional Replies')}
          pointsPossibleDataTestId="points-possible-input-reply-to-entry"
        />
      </View>
      <View as="div" margin="0 0 medium 0">
        <Text size="large">
          {I18n.t('Total Points Possible: %{totalPoints}', {
            totalPoints: pointsPossibleReplyToTopic + pointsPossibleReplyToEntry,
          })}
        </Text>
      </View>
    </>
  )
}
