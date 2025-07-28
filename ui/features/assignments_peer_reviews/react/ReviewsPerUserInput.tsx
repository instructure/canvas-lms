/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Flex} from '@instructure/ui-flex'
import {IconWarningSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('assignments_2')

const ReviewsPerUserInput = ({
  initialCount,
  onChange,
}: {
  initialCount: string
  onChange: (value: string) => void
}) => {
  const [errors, setErrors] = useState<FormMessage[]>([])
  const [count, setCount] = useState(initialCount)

  const clearErrors = () => {
    setErrors([])
  }

  const handleChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    clearErrors()
    setCount(value)
    onChange(value)
  }

  const validateCount = () => {
    const newErrors: FormMessage[] = []
    if (count) {
      const input = Number(count)
      if (!Number.isInteger(input)) {
        newErrors.push({
          type: 'newError',
          text: I18n.t('Must be a whole number'),
        })
      } else if (input <= 0) {
        newErrors.push({
          type: 'newError',
          text: I18n.t('Must be greater than 0'),
        })
      }
      setErrors(newErrors)
    }
  }

  return (
    <TextInput
      id='reviews_per_user_input'
      data-testid='reviews_per_user_input'
      renderLabel={I18n.t('Reviews per user')}
      defaultValue={initialCount}
      onChange={handleChange}
      onBlur={validateCount}
      messages={errors}
    />
  )
}

export default ReviewsPerUserInput
