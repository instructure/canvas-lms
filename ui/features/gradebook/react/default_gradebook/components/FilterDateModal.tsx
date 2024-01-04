// @ts-nocheck
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
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import moment from 'moment'
import {MomentInput} from 'moment-timezone'
import type {Moment} from 'moment-timezone'
import * as tz from '@canvas/datetime'
import {View} from '@instructure/ui-view'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

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
          <CanvasDateInput
            dataTestid="start-date-input"
            dateIsDisabled={(date: Moment) =>
              Boolean(endDateValue && date.toISOString() > endDateValue)
            }
            display="block"
            formatDate={formatDate}
            interaction="enabled"
            messages={startDateMessages}
            onSelectedDateChange={(inputObj: MomentInput) => {
              if (inputObj instanceof Date) {
                const startDate_ = moment(inputObj).toISOString()
                if (endDateValue && startDate_ > endDateValue) {
                  setStartDateMessages([
                    {
                      text: I18n.t('Start date must be before end date'),
                      type: 'error',
                    },
                  ])
                } else {
                  setStartDateMessages([])
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
          <CanvasDateInput
            dataTestid="end-date-input"
            dateIsDisabled={(date: Moment) =>
              Boolean(startDateValue && date.toISOString() < startDateValue)
            }
            display="block"
            formatDate={formatDate}
            interaction="enabled"
            messages={endDateMessages}
            onSelectedDateChange={(inputObj: MomentInput) => {
              if (inputObj instanceof Date) {
                const endDate_ = moment(inputObj).toISOString()
                if (startDateValue && endDate_ < startDateValue) {
                  setEndDateMessages([
                    {
                      text: I18n.t('End date must be after start date'),
                      type: 'error',
                    },
                  ])
                } else {
                  setEndDateMessages([])
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
        <Button color="primary" type="submit" data-testid="apply-date-filter">
          {I18n.t('Apply')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
