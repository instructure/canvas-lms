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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState, useCallback} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {NumberInput} from '@instructure/ui-number-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import useNumberInputDriver from '../hooks/useNumberInputDriver'

const I18n = useI18nScope('assignments_bulk_edit')

export default function MoveDatesModal({onShiftDays, onRemoveDates, onCancel, ...otherModalProps}) {
  const [mode, setMode] = useState('shift')
  const [datesToRemove, setDatesToRemove] = useState(['dueDates'])
  const [shiftDaysState, shiftDaysProps] = useNumberInputDriver({
    initialNumberValue: 1,
    minNumberValue: 1,
    maxNumberValue: 999,
  })

  const handleOk = useCallback(() => {
    if (mode === 'shift' && shiftDaysState.numberValue) onShiftDays(shiftDaysState.numberValue)
    if (mode === 'remove') {
      const outputDatesToRemove = []
      if (datesToRemove.includes('dueDates')) outputDatesToRemove.push('due_at')
      if (datesToRemove.includes('lockDates')) {
        outputDatesToRemove.push('unlock_at')
        outputDatesToRemove.push('lock_at')
      }
      if (outputDatesToRemove.length) onRemoveDates(outputDatesToRemove)
    }
    // else, unrecognized mode or bad data, so do nothing
  }, [datesToRemove, mode, onShiftDays, onRemoveDates, shiftDaysState.numberValue])

  const handleModeChange = useCallback(e => {
    setMode(e.target.value)
  }, [])

  const handleDatesToRemoveChange = useCallback(newValue => {
    setDatesToRemove(newValue)
  }, [])

  const okDisabled = (function () {
    if (mode === 'shift' && shiftDaysState.numberValue === null) return true
    if (mode === 'remove' && datesToRemove.length === 0) return true
    return false
  })()

  const renderFooter = useCallback(() => {
    return (
      <>
        <Button onClick={onCancel} data-testid="cancel-batch-edit">
          {I18n.t('Cancel')}
        </Button>
        <Button
          margin="0 0 0 small"
          color="primary"
          onClick={handleOk}
          interaction={okDisabled ? 'disabled' : 'enabled'}
        >
          {I18n.t('Ok')}
        </Button>
      </>
    )
  }, [handleOk, okDisabled, onCancel])

  function renderShiftDaysInput() {
    if (mode === 'shift') {
      return <NumberInput width="200px" renderLabel="Days" {...shiftDaysProps} />
    }
    return null
  }

  function renderRemoveCheckboxes() {
    if (mode === 'remove') {
      return (
        <CheckboxGroup
          name="remove"
          value={datesToRemove}
          onChange={handleDatesToRemoveChange}
          description={
            <ScreenReaderContent>{I18n.t('Select dates to remove')}</ScreenReaderContent>
          }
        >
          <Checkbox label={I18n.t('Due Dates')} value="dueDates" />
          <Checkbox label={I18n.t('Availability Dates')} value="lockDates" />
        </CheckboxGroup>
      )
    }
    return null
  }

  return (
    <CanvasModal
      label={I18n.t('Batch Edit Dates')}
      footer={renderFooter}
      onDismiss={onCancel}
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
                'Shift due dates and assignment availability dates forward by a number of days.'
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
          {renderRemoveCheckboxes()}
        </View>
      </RadioInputGroup>
    </CanvasModal>
  )
}
