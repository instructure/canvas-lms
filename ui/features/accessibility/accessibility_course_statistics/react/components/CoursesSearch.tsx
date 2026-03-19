/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useDebouncedCallback} from 'use-debounce'

const I18n = createI18nScope('accessibility_course_statistics')

export const CoursesSearch: React.FC<{
  value: string
  onChange: (value: string) => void
}> = ({value, onChange}) => {
  const [localValue, setLocalValue] = useState(value)

  useEffect(() => {
    setLocalValue(value)
  }, [value])

  const debouncedOnChange = useDebouncedCallback((newValue: string) => {
    onChange(newValue)
  }, 300)

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = event.target.value
    setLocalValue(newValue)

    if (newValue === '') {
      onChange('')
      return
    }

    if (newValue.length >= 3) {
      debouncedOnChange(newValue)
    }
  }

  const clearButton = () => {
    return (
      <IconButton
        type="button"
        size="small"
        withBackground={false}
        withBorder={false}
        onClick={() => onChange('')}
        screenReaderLabel={I18n.t('Clear search')}
        data-testid="clear-search-button"
      >
        <IconTroubleLine />
      </IconButton>
    )
  }

  return (
    <View as="div" margin="0 0 medium">
      <TextInput
        renderLabel={() => <ScreenReaderContent>{I18n.t('Search courses')}</ScreenReaderContent>}
        placeholder={I18n.t('Search by course title, SIS ID...')}
        value={localValue}
        onChange={handleChange}
        type="search"
        messages={[
          {
            type: 'hint',
            text: I18n.t(
              'Start typing to search. Results will update automatically after 3 characters.',
            ),
          },
        ]}
        renderBeforeInput={<IconSearchLine inline={false} />}
        renderAfterInput={localValue.length ? clearButton() : null}
      />
    </View>
  )
}
