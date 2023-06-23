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

import {useScope} from '@canvas/i18n'
import {SimpleSelect} from '@instructure/ui-simple-select'
import React, {useEffect, useState} from 'react'
import moment, {Moment} from 'moment-timezone'
import {
  FrequencyOptionValue,
  FrequencyOption,
  FrequencyOptionsArray,
  generateFrequencyOptions,
  generateFrequencyRRule,
} from './FrequencyPickerUtils'

const {Option} = SimpleSelect as any
const I18n = useScope('calendar_frequency_picker')

export type OnFrequencyChange = (frequency: FrequencyOptionValue, RRule: string | null) => void

export type FrequencyPickerProps = {
  readonly date: string
  readonly frequency?: FrequencyOptionValue
  readonly locale: string
  readonly onChange: OnFrequencyChange
}

export default function FrequencyPicker({
  date,
  frequency = 'not-repeat',
  locale,
  onChange,
}: FrequencyPickerProps) {
  const [parsedMoment, setParsedMoment] = useState<Moment>(moment(date))
  const [options, setOptions] = useState<FrequencyOptionsArray>(
    generateFrequencyOptions(parsedMoment, locale)
  )

  useEffect(() => {
    const newMoment = moment(date)
    setParsedMoment(newMoment)
    setOptions(generateFrequencyOptions(newMoment, locale))
    onChange(frequency, generateFrequencyRRule(frequency, newMoment))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [date])

  const handleSelectOption = (e: any, option: FrequencyOption) => {
    onChange(option.id, generateFrequencyRRule(option.id, parsedMoment))
  }

  return (
    <SimpleSelect
      renderLabel={I18n.t('frequency', 'Frequency:')}
      value={frequency}
      onChange={handleSelectOption}
    >
      {options.map(opt => (
        <Option id={opt.id} key={opt.id} value={opt.id}>
          {opt.label}
        </Option>
      ))}
    </SimpleSelect>
  )
}
