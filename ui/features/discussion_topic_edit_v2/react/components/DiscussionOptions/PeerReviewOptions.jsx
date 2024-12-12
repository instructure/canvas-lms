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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'

import {DateTimeInput} from '@instructure/ui-date-time-input'
import {NumberInput} from '@instructure/ui-number-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Checkbox} from '@instructure/ui-checkbox'
import moment from 'moment'

const I18n = createI18nScope('discussion_create')

const peerReviewOptions = [
  {value: 'off', label: I18n.t('Off'), testid: 'peer_review_off'},
  {value: 'manually', label: I18n.t('Assign manually'), testid: 'peer_review_manual'},
  {value: 'automatically', label: I18n.t('Automatically assign'), testid: 'peer_review_auto'},
]

const fancyMidnightDueTime = '23:59:00'

function isFancyMidnightNeeded(value) {
  const chosenDueTime = moment
    .utc(value)
    .tz(ENV.TIMEZONE || 'UTC')
    .format('HH:mm:00')

  return chosenDueTime === '00:00:00'
}

function setTimeToStringDate(time, date) {
  const [hour, minute, second] = time.split(':').map(Number)
  const chosenDate = moment.utc(date).tz(ENV.TIMEZONE || 'UTC')
  chosenDate.set({hour, minute, second})
  return chosenDate.isValid() ? chosenDate.utc().toISOString() : date
}

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
  const [reviewsDueDateRef, setReviewsDueDateRef] = useState(null)
  const [reviewsDueTimeRef, setReviewsDueTimeRef] = useState(null)

  reviewsDueDateRef?.setAttribute('data-testid', 'reviews-due-date')
  reviewsDueTimeRef?.setAttribute('data-testid', 'reviews-due-time')

  return (
    <View as="div">
      <View as="div" margin="small 0">
        <RadioInputGroup
          onChange={(_event, value) => setPeerReviewAssignment(value)}
          name="peer_review_radio_group"
          value={peerReviewAssignment}
          description={I18n.t('Peer Reviews')}
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
              allowStringValue={true}
              data-testid="peer-review-count-input"
              renderLabel={I18n.t('Reviews Per Student')}
              onIncrement={() => setPeerReviewsPerStudent(peerReviewsPerStudent + 1)}
              onDecrement={() => {
                if (peerReviewsPerStudent - 1 > 0) {
                  setPeerReviewsPerStudent(peerReviewsPerStudent - 1)
                }
              }}
              value={peerReviewsPerStudent}
              onChange={event => {
                // don't allow non-numeric values
                if (!/^\d*\.?\d*$/.test(event.target.value)) return
                setPeerReviewsPerStudent(Number.parseInt(event.target.value, 10))
              }}
              onBlur={event => {
                if (event.target.value === '0') {
                  setPeerReviewsPerStudent(1)
                }
              }}
            />
          </View>
          <View as="div" margin="small 0 small large" data-testid="peer-review-due-date-container">
            <DateTimeInput
              timezone={ENV.TIMEZONE}
              description={I18n.t('Assign Reviews')}
              prevMonthLabel={I18n.t('previous')}
              nextMonthLabel={I18n.t('next')}
              onChange={(_event, newDate) => {
                const finalDate = isFancyMidnightNeeded(newDate)
                  ? setTimeToStringDate(fancyMidnightDueTime, newDate)
                  : newDate

                setPeerReviewDueDate(finalDate)
              }}
              value={peerReviewDueDate}
              invalidDateTimeMessage={I18n.t('Invalid date and time')}
              layout="columns"
              datePlaceholder={I18n.t('Select Date')}
              dateRenderLabel=""
              timeRenderLabel=""
              dateInputRef={ref => {
                setReviewsDueDateRef(ref)
              }}
              timeInputRef={ref => {
                setReviewsDueTimeRef(ref)
              }}
              allowNonStepInput={true}
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
