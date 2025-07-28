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

import React, {useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import CanvasDateInput2 from '@canvas/datetime/react/components/DateInput2'
import type {MomentInput} from 'moment-timezone'
import * as tz from '@instructure/moment-utils'
import {View} from '@instructure/ui-view'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {isoDateFromInput} from '../../../util/DateUtils'

const I18n = createI18nScope('gradebook')

const formatDate = (date: Date) => tz.format(date, 'date.formats.medium')

function useResetState<T>(initialState: T): [T, (value: T) => void] {
  const [value, setValue] = useState(initialState)
  React.useEffect(() => {
    setValue(initialState)
  }, [initialState])

  return [value, setValue]
}

type Props = {
  endDate: string | null
  isOpen: boolean
  onCloseDateModal: () => void
  onSelectDates: (startDate: string | null, endDate: string | null) => void
  startDate: string | null
}

export default function FilterNavDateModal({
  endDate,
  isOpen,
  onCloseDateModal,
  onSelectDates,
  startDate,
}: Props) {
  const [startDateValue, setStartDateValue] = useResetState<string | null>(startDate)
  const [endDateValue, setEndDateValue] = useResetState<string | null>(endDate)

  const [startDateMessages, setStartDateMessages] = useState<
    {
      text: string
      type: 'error'
    }[]
  >([])
  const [endDateMessages, setEndDateMessages] = useState<
    {
      text: string
      type: 'error'
    }[]
  >([])

  return (
    <Modal
      as="form"
      open={isOpen}
      onDismiss={onCloseDateModal}
      onSubmit={event => {
        event.preventDefault()
        onSelectDates(startDateValue, endDateValue)
        onCloseDateModal()
      }}
      label={I18n.t('Modal Dialog: Start & End Date')}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onCloseDateModal}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Start & End Dates')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="0 0 medium 0">
          <CanvasDateInput2
            dataTestid="start-date-input"
            disabledDates={(isoDate: string) => Boolean(endDateValue && isoDate > endDateValue)}
            isInline={false}
            // @ts-expect-error
            formatDate={formatDate}
            interaction="enabled"
            messages={startDateMessages}
            onSelectedDateChange={(inputObj: MomentInput) => {
              if (inputObj instanceof Date) {
                const startDate_ = isoDateFromInput('start-date', inputObj, ENV?.TIMEZONE)
                // @ts-expect-error
                if (endDateValue && startDate_ > endDateValue) {
                  setStartDateMessages([
                    {
                      text: I18n.t('Start date must be before end date'),
                      type: 'error',
                    },
                  ])
                } else {
                  setStartDateMessages([])
                  // @ts-expect-error
                  setStartDateValue(startDate_)
                }
              } else {
                setStartDateValue('')
              }
            }}
            renderLabel={I18n.t('Start Date')}
            selectedDate={startDateValue}
            width="100%"
          />
        </View>

        <View as="div">
          <CanvasDateInput2
            dataTestid="end-date-input"
            disabledDates={(isoDate: string) => Boolean(startDateValue && isoDate < startDateValue)}
            isInline={false}
            // @ts-expect-error
            formatDate={formatDate}
            interaction="enabled"
            messages={endDateMessages}
            onSelectedDateChange={(inputObj: MomentInput) => {
              if (inputObj instanceof Date) {
                const endDate_ = isoDateFromInput('end-date', inputObj, ENV?.TIMEZONE)
                // @ts-expect-error
                if (startDateValue && endDate_ < startDateValue) {
                  setEndDateMessages([
                    {
                      text: I18n.t('End date must be after start date'),
                      type: 'error',
                    },
                  ])
                } else {
                  setEndDateMessages([])
                  // @ts-expect-error
                  setEndDateValue(endDate_)
                }
              } else {
                setEndDateValue('')
              }
            }}
            renderLabel={I18n.t('End Date')}
            selectedDate={endDateValue}
            width="100%"
          />
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onCloseDateModal} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button
          id="apply-date-filter" // EVAL-4235
          color="primary"
          type="submit"
          data-testid="apply-date-filter"
        >
          {I18n.t('Apply')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
