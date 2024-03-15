/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'

import {DateTimeInput} from '@instructure/ui-date-time-input'
import {NumberInput} from '@instructure/ui-number-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Checkbox} from '@instructure/ui-checkbox'

const I18n = useI18nScope('discussion_create')

const peerReviewOptions = [
  {value: 'off', label: I18n.t('Off'), testid: 'peer_review_off'},
  {value: 'manually', label: I18n.t('Assign manually'), testid: 'peer_review_manual'},
  {value: 'automatically', label: I18n.t('Automatically assign'), testid: 'peer_review_auto'},
]

export const PeerReviewOptions = ({
  peerReviewAssignment,
  setPeerReviewAssignment,
  peerReviewsPerStudent,
  setPeerReviewsPerStudent,
  peerReviewDueDate,
  setPeerReviewDueDate,
  intraGroupPeerReviews,
  setIntraGroupPeerReviews,
}) => {
  return (
    <View as="div">
      <Text as="h3" weight="bold">
        {I18n.t('Peer Reviews')}
      </Text>
      <View as="div" margin="small 0">
        <RadioInputGroup
          onChange={(_event, value) => setPeerReviewAssignment(value)}
          name="peer_review_radio_group"
          value={peerReviewAssignment}
          description={<ScreenReaderContent>{I18n.t('Peer review options')}</ScreenReaderContent>}
        >
          {peerReviewOptions.map(option => (
            <RadioInput
              key={option.value}
              value={option.value}
              label={option.label}
              data-testid={option.testid}
            />
          ))}
        </RadioInputGroup>
      </View>
      {peerReviewAssignment === 'automatically' && (
        <>
          <View as="div" margin="small 0 small large">
            <NumberInput
              data-testid="peer-review-count-input"
              renderLabel={I18n.t('Reviews Per Student')}
              onIncrement={() => setPeerReviewsPerStudent(peerReviewsPerStudent + 1)}
              onDecrement={() => setPeerReviewsPerStudent(peerReviewsPerStudent - 1)}
              value={peerReviewsPerStudent}
              onChange={event => {
                // don't allow non-numeric values
                if (!/^\d*\.?\d*$/.test(event.target.value)) return
                setPeerReviewsPerStudent(Number.parseInt(event.target.value, 10))
              }}
            />
          </View>
          <View as="div" margin="small 0 small large" data-testid="peer-review-due-date-container">
            <DateTimeInput
              timezone={ENV.TIMEZONE}
              description={I18n.t('Reviews Due')}
              prevMonthLabel={I18n.t('previous')}
              nextMonthLabel={I18n.t('next')}
              onChange={(_event, newDate) => setPeerReviewDueDate(newDate)}
              value={peerReviewDueDate}
              invalidDateTimeMessage={I18n.t('Invalid date and time')}
              layout="columns"
              datePlaceholder={I18n.t('Select Date')}
              dateRenderLabel=""
              timeRenderLabel=""
            />
            <Text as="p" size="small">
              {I18n.t('If left blank, uses due date')}
            </Text>
          </View>
          <View as="div" margin="small 0">
            <Checkbox
              label={I18n.t('Allow intra-group peer reviews')}
              value="intra_group_peer_reviews"
              checked={intraGroupPeerReviews}
              onChange={() => setIntraGroupPeerReviews(!intraGroupPeerReviews)}
            />
          </View>
        </>
      )}
    </View>
  )
}
