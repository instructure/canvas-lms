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
import React, {useRef, useState, useEffect} from 'react'
import shortid from '@canvas/shortid'
import {FormField} from '@instructure/ui-form-field'
import {NumberInput} from '@instructure/ui-number-input'
import type {FormMessage} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import $ from 'jquery'

const I18n = createI18nScope('allowed_attempts')

interface AllowedAttemptsProps {
  limited: boolean
  attempts?: number | null
  locked?: boolean
  onLimitedChange: (limited: boolean) => void
  onAttemptsChange: (attempts: number | null) => void
  onHideErrors: () => void
}

export default function AllowedAttempts({
  limited,
  attempts = -1,
  locked = false,
  onLimitedChange,
  onAttemptsChange,
  onHideErrors,
}: AllowedAttemptsProps) {
  const selectIdRef = useRef(shortid())
  const limitedValue = limited ? 'limited' : 'unlimited'
  const attemptsValue = limited ? attempts || '' : -1
  const [validationError, setValidationError] = useState(false)
  const attemptsMessages: FormMessage[] = validationError ? [{text: '', type: 'error'}] : []

  useEffect(() => {
    $(document).on('validateAllowedAttempts', (_e: any, data: {error: boolean}) =>
      setValidationError(!!data.error),
    )

    return () => {
      $(document).off('validateAllowedAttempts')
    }
  }, [setValidationError])

  function handleLimitedChange(e: React.ChangeEvent<HTMLSelectElement>) {
    onLimitedChange(e.target.value === 'limited')
    onHideErrors()
  }

  function handleAttemptsChange(e: React.ChangeEvent<HTMLInputElement>) {
    const newValue = parseInt(e.target.value, 10)
    if (e.target.value === '') {
      onAttemptsChange(null)
    } else if (!Number.isNaN(newValue)) {
      onAttemptsChange(newValue)
    } // else don't call it with NaN
    onHideErrors()
  }

  function handleIncrementOrDecrement(step: number) {
    let updatedAttempts
    if (attempts === null) {
      updatedAttempts = 1
    } else {
      updatedAttempts = attempts + step
      if (updatedAttempts < 1) updatedAttempts = 1
    }
    onAttemptsChange(updatedAttempts)
    onHideErrors()
  }

  return (
    <>
      <FormField id={selectIdRef.current} label={I18n.t('Allowed Attempts')}>
        <select
          id={selectIdRef.current}
          value={limitedValue}
          disabled={locked}
          onChange={handleLimitedChange}
          data-testid="allowed_attempts_type"
        >
          <option value="unlimited">{I18n.t('Unlimited')}</option>
          <option value="limited">{I18n.t('Limited')}</option>
        </select>
      </FormField>

      <div hidden={!limited} style={{marginTop: '16px'}}>
        <NumberInput
          allowStringValue={true}
          renderLabel={I18n.t('Number of Attempts')}
          name="allowed_attempts"
          display="inline-block"
          width="220px"
          value={attemptsValue}
          interaction={locked ? 'disabled' : 'enabled'}
          messages={attemptsMessages}
          onChange={handleAttemptsChange}
          onIncrement={() => handleIncrementOrDecrement(1)}
          onDecrement={() => handleIncrementOrDecrement(-1)}
          data-testid="allowed_attempts_input"
          aria-describedby="allowed_attempts_errors"
        />
      </div>
      <View as="div" id="allowed_attempts_errors" padding="small 0 0 0" />
    </>
  )
}
