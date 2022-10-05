/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState, useCallback} from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'

const I18n = useI18nScope('jobs_v2')

export default function DateOptionsModal({open, startDate, endDate, timeZone, onSave, onClose}) {
  const title = I18n.t('Date/Time Options')

  const renderTimeZoneOption = (id, description) => {
    if (!id) return null
    const text = id === description ? id : `${description} (${id})`
    return (
      <CanvasSelect.Option id={description} value={id}>
        {text}
      </CanvasSelect.Option>
    )
  }

  const [newStartDate, setNewStartDate] = useState(startDate)
  const [newEndDate, setNewEndDate] = useState(endDate)
  const [newTimeZone, setNewTimeZone] = useState(timeZone)

  const formatDate = useDateTimeFormat('date.formats.full')

  const onOK = useCallback(() => {
    onSave({start_date: newStartDate, end_date: newEndDate, time_zone: newTimeZone})
    onClose()
  }, [onSave, onClose, newStartDate, newEndDate, newTimeZone])

  return (
    <Modal open={open} onDismiss={onClose} label={title} shouldCloseOnDocumentClick={true}>
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View display="block" margin="0 0 medium 0">
          <CanvasSelect
            value={newTimeZone}
            onChange={(_event, value) => setNewTimeZone(value)}
            label={I18n.t('View timestamps in time zone')}
            id="timezone-select"
          >
            {renderTimeZoneOption('UTC', I18n.t('UTC'))}
            {renderTimeZoneOption(
              Intl.DateTimeFormat().resolvedOptions().timeZone,
              I18n.t('Local')
            )}
            {renderTimeZoneOption(ENV?.TIMEZONE, I18n.t('User'))}
            {renderTimeZoneOption(ENV?.CONTEXT_TIMEZONE, I18n.t('Account'))}
          </CanvasSelect>
        </View>
        <FormFieldGroup
          description={I18n.t('Filter jobs by date')}
          colSpacing="medium"
          layout="columns"
          vAlign="top"
        >
          <CanvasDateInput
            selectedDate={newStartDate}
            renderLabel={I18n.t('After')}
            formatDate={formatDate}
            withRunningValue={true}
            onSelectedDateChange={date => setNewStartDate(date?.toISOString() || '')}
          />
          <CanvasDateInput
            selectedDate={newEndDate}
            renderLabel={I18n.t('Before')}
            formatDate={formatDate}
            withRunningValue={true}
            onSelectedDateChange={date => setNewEndDate(date?.toISOString() || '')}
          />
        </FormFieldGroup>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button onClick={onOK} color="primary" type="submit">
          {I18n.t('Accept')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
