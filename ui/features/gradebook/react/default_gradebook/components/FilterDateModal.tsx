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
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import moment from 'moment'
import {MomentInput} from 'moment-timezone'
import tz from '@canvas/timezone'
import {View} from '@instructure/ui-view'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

const formatDate = date => tz.format(date, 'date.formats.medium')

const useResetState = initialState => {
  const [value, setValue] = React.useState(initialState)
  React.useEffect(() => {
    setValue(initialState)
  }, [initialState])

  return [value, setValue]
}

export default function FilterNavDateModal({
  startDate,
  endDate,
  isOpen,
  onCloseDateModal,
  onSelectDates
}) {
  const [startDateValue, setStartDateValue] = useResetState(startDate)
  const [endDateValue, setEndDateValue] = useResetState(endDate)

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
            display="block"
            width="100%"
            dataTestid="start-date-input"
            renderLabel={I18n.t('Start Date')}
            selectedDate={startDateValue}
            formatDate={formatDate}
            interaction="enabled"
            onSelectedDateChange={(inputObj: MomentInput) => {
              if (inputObj instanceof Date) {
                setStartDateValue(moment(inputObj).toISOString())
              } else {
                setStartDateValue('')
              }
            }}
          />
        </View>

        <View as="div">
          <CanvasDateInput
            display="block"
            width="100%"
            dataTestid="end-date-input"
            renderLabel={I18n.t('End Date')}
            selectedDate={endDateValue}
            formatDate={formatDate}
            interaction="enabled"
            onSelectedDateChange={(inputObj: MomentInput) => {
              if (inputObj instanceof Date) {
                setEndDateValue(moment(inputObj).toISOString())
              } else {
                setEndDateValue('')
              }
            }}
          />
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onCloseDateModal} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button color="primary" type="submit">
          {I18n.t('Apply')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
