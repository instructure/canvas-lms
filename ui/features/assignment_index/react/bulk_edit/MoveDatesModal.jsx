/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useState, useCallback} from 'react'
import {Button} from '@instructure/ui-buttons'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {NumberInput} from '@instructure/ui-number-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import CanvasModal from '@canvas/instui-bindings/react/Modal'

const I18n = createI18nScope('assignments_bulk_edit')

export const SHIFT_DAYS_MIN = 1
export const SHIFT_DAYS_MAX = 999

export default function MoveDatesModal({onShiftDays, onRemoveDates, onCancel, ...otherModalProps}) {
  const DUE_DATES = 'dueDates'
  const LOCK_DATES = 'lockDates'
  const DUE_AND_LOCK_DATES = 'dueAndLockDates'
  const [mode, setMode] = useState('shift')
  const [datesToRemove, setDatesToRemove] = useState(DUE_DATES)
  const [shiftDaysMessages, setShiftDaysMessages] = useState([])
  const [shiftDays, setShiftDays] = useState(`${SHIFT_DAYS_MIN}`)
  const removeInputs = [
    {value: DUE_DATES , label: I18n.t('Remove Due Dates')},
    {value: LOCK_DATES, label: I18n.t('Remove Availability Dates')},
    {value: DUE_AND_LOCK_DATES, label: I18n.t('Remove Both')},
  ]

  const handleShiftDaysChange = useCallback((event, value) => {
    setShiftDays(value)
    setShiftDaysMessages([])
  }, [])

  const handleShiftDaysIncrement = useCallback(() => {
    if(isNaN(shiftDays)) return

    setShiftDays(`${Number(shiftDays) + 1}`)
    setShiftDaysMessages([])
  }, [shiftDays])

  const handleShiftDaysDecrement = useCallback(() => {
    if(isNaN(shiftDays)) return

    setShiftDays(`${Number(shiftDays) - 1}`)
    setShiftDaysMessages([])
  }, [shiftDays])

  const generateShiftDaysMessages = () => {

    if(shiftDays.trim() === '') 
      return [{type: 'newError', text: I18n.t('Number of days is required')}]
    
    const shiftDaysValue = Number(shiftDays)
    if(isNaN(shiftDaysValue))
      return [{type: 'newError', text: I18n.t('You must use a number')}]

    if(!Number.isInteger(shiftDaysValue))
      return [{type: 'newError', text: I18n.t('You must use an integer')}]
    
    if(shiftDaysValue < SHIFT_DAYS_MIN || shiftDaysValue > SHIFT_DAYS_MAX)
      return [{
        type: 'newError',
        text: I18n.t('Must be between %{minValue} and %{maxValue}', {
          minValue: SHIFT_DAYS_MIN,
          maxValue: SHIFT_DAYS_MAX
        })
      }]
    
    return []
  }

  const handleOk = useCallback(() => {
    if (mode === 'shift'){
      const shiftDaysValidationMessages = generateShiftDaysMessages()
      if(shiftDaysValidationMessages.length > 0){
        setShiftDaysMessages(shiftDaysValidationMessages)
        return
      }
      onShiftDays(shiftDays)
    } 
    if (mode === 'remove') {
      const outputDatesToRemove = []
      if(datesToRemove === DUE_DATES){
        outputDatesToRemove.push('due_at')
      }
      else if(datesToRemove === LOCK_DATES){
        outputDatesToRemove.push('unlock_at')
        outputDatesToRemove.push('lock_at')
      }
      else if(datesToRemove === DUE_AND_LOCK_DATES){
        outputDatesToRemove.push('due_at')
        outputDatesToRemove.push('unlock_at')
        outputDatesToRemove.push('lock_at')
      }
      if (outputDatesToRemove.length) onRemoveDates(outputDatesToRemove)
    }
    // else, unrecognized mode or bad data, so do nothing
  }, [datesToRemove, mode, onShiftDays, onRemoveDates, shiftDays])

  const handleModeChange = useCallback(e => {
    setMode(e.target.value)
    setShiftDaysMessages([])
  }, [])

  const handleDatesToRemoveChange = useCallback(e => {
    setDatesToRemove(e.target.value)
  }, [])

  const handleCancel = useCallback(() => {
    setShiftDaysMessages([])
    onCancel()
  }, [])

  const renderFooter = useCallback(() => {
    return (
      <>
        <Button onClick={handleCancel} data-testid="cancel-batch-edit">
          {I18n.t('Cancel')}
        </Button>
        <Button
          margin="0 0 0 small"
          color="primary"
          onClick={handleOk}
        >
          {I18n.t('Confirm')}
        </Button>
      </>
    )
  }, [handleOk, handleCancel])

  function renderShiftDaysInput() {
    if (mode === 'shift') {
      return (
        <NumberInput
          allowStringValue={true}
          width="200px"
          renderLabel={I18n.t("Days")}
          onChange={handleShiftDaysChange}
          messages={shiftDaysMessages}
          value={shiftDays}
          onIncrement={handleShiftDaysIncrement}
          onDecrement={handleShiftDaysDecrement}
        />
      )
    }
    return null
  }

  function renderRemoveRadioButtons() {
    if (mode === 'remove') {
      return (
        <RadioInputGroup
          name="remove"
          value={datesToRemove}
          onChange={handleDatesToRemoveChange}
          description={
            <ScreenReaderContent>{I18n.t('Select dates to remove')}</ScreenReaderContent>
          }
        >
           {removeInputs.map(input => <RadioInput key={input.value} value={input.value} label={input.label} />)}
        </RadioInputGroup>
      )
    }
    return null
  }

  return (
    <CanvasModal
      label={I18n.t('Batch Edit Dates')}
      footer={renderFooter}
      onDismiss={handleCancel}
      size="small"
      padding="medium"
      {...otherModalProps}
    >
      <RadioInputGroup
        name="operation"
        description={
          <ScreenReaderContent>{I18n.t('Select an edit operation')}</ScreenReaderContent>
        }
        value={mode}
        onChange={handleModeChange}
      >
        <RadioInput value="shift" label={I18n.t('Shift Dates')} />
        <View as="div" margin="0 0 large large">
          <Text>
            <p>
              {I18n.t(
                'Shift due dates and assignment availability dates forward by a number of days.',
              )}
            </p>
          </Text>
          {renderShiftDaysInput()}
        </View>
        <RadioInput value="remove" label={I18n.t('Remove Dates')} />
        <View as="div" margin="0 0 0 large">
          <Text>
            <p>{I18n.t('Remove due dates and assignment availability dates.')}</p>
          </Text>
          {renderRemoveRadioButtons()}
        </View>
      </RadioInputGroup>
    </CanvasModal>
  )
}
