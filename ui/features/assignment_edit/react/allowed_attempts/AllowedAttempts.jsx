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
import React, {useRef} from 'react'
import {bool, func, number} from 'prop-types'
import shortid from '@canvas/shortid'
import {FormField} from '@instructure/ui-form-field'
import {NumberInput} from '@instructure/ui-number-input'

const I18n = useI18nScope('allowed_attempts')

AllowedAttempts.propTypes = {
  limited: bool.isRequired,
  attempts: number, // not required, may be null to specify a blank value
  locked: bool,
  onLimitedChange: func.isRequired,
  onAttemptsChange: func.isRequired,
}

AllowedAttempts.defaultProps = {
  attempts: -1,
  locked: false,
}

export default function AllowedAttempts({
  limited,
  attempts,
  locked,
  onLimitedChange,
  onAttemptsChange,
}) {
  const selectIdRef = useRef(shortid())
  const limitedValue = limited ? 'limited' : 'unlimited'
  const attemptsValue = limited ? attempts || '' : -1
  const attemptsMessages =
    attemptsValue !== '' ? [] : [{text: I18n.t('Must be a number'), type: 'error'}]

  function handleLimitedChange(e) {
    onLimitedChange(e.target.value === 'limited')
  }

  function handleAttemptsChange(e) {
    const newValue = parseInt(e.target.value, 10)
    if (e.target.value === '') {
      onAttemptsChange(null)
    } else if (!Number.isNaN(newValue)) {
      onAttemptsChange(newValue)
    } // else don't call it with NaN
  }

  function handleIncrementOrDecrement(step) {
    if (attempts === null) {
      onAttemptsChange(1)
      return
    }
    let result = attempts + step
    if (result < 1) result = 1
    onAttemptsChange(result)
  }

  return (
    <>
      <FormField id={selectIdRef.current} label={I18n.t('Allowed Attempts')}>
        <select
          id={selectIdRef.current}
          value={limitedValue}
          disabled={locked}
          onChange={handleLimitedChange}
        >
          <option value="unlimited">{I18n.t('Unlimited')}</option>
          <option value="limited">{I18n.t('Limited')}</option>
        </select>
      </FormField>

      <div hidden={!limited} style={{marginTop: '16px'}}>
        <NumberInput
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
        />
      </div>
    </>
  )
}
