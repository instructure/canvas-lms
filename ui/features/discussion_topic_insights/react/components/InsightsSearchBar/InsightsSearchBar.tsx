/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useState, useRef} from 'react'
import {View, ViewProps} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {IconButton} from '@instructure/ui-buttons'
import {IconTroubleLine, IconSearchLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {debounce} from '@instructure/debounce'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discussion_insights')

type InsightsSearchBarProps = {
  onSearch: (query: string) => void
  debounceTime?: number
}

const InsightsSearchBar: React.FC<InsightsSearchBarProps> = ({onSearch, debounceTime = 300}) => {
  const [value, setValue] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const inputRef = useRef<HTMLInputElement | null>(null)

  const [loadResults] = useState(() =>
    debounce((value: string) => {
      if (!value || !value.length) {
        setIsLoading(false)
        onSearch('')
        return
      }

      setIsLoading(true)

      setIsLoading(false)
      onSearch(value)
    }, debounceTime),
  )

  const handleChange = (value: string) => {
    setValue(value)
    loadResults(value)
  }

  const handleClear = (
    event: React.MouseEvent<ViewProps, MouseEvent> | React.KeyboardEvent<ViewProps>,
  ) => {
    event.stopPropagation()
    handleChange('')
    inputRef.current?.focus()
  }

  const renderClearButton = () => {
    if (!value.length) return null

    return (
      <IconButton
        type="button"
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel="Clear search"
        onClick={handleClear}
      >
        <IconTroubleLine />
      </IconButton>
    )
  }

  return (
    <View as="div">
      <TextInput
        renderLabel={<ScreenReaderContent>Search</ScreenReaderContent>}
        placeholder={I18n.t('Search...')}
        value={value}
        onChange={e => handleChange(e.target.value)}
        data-testid="discussion-insights-search-bar"
        inputRef={inputElement => {
          inputRef.current = inputElement
        }}
        renderBeforeInput={<IconSearchLine inline={false} />}
        renderAfterInput={renderClearButton()}
        shouldNotWrap
      />
      {isLoading && (
        <Flex direction="column" alignItems="center">
          <Spinner renderTitle="Loading" />
        </Flex>
      )}
    </View>
  )
}

export default InsightsSearchBar
