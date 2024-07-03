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

import React, {useRef, useEffect, useCallback, type RefObject} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconSearchLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {debounce} from 'lodash'
import {DEFAULT_SEARCH_DELAY} from '../utils/constants'

const I18n = useI18nScope('discussion_topics_post')

interface CustomTextInput extends TextInput {
  inputRef: RefObject<TextInput>
}

type Props = {
  name: string
  onSearchEvent: (data: {searchTerm: string}) => void
  searchInputRef?: (input: TextInput | null) => void
  searchDelay?: number
}

export const SearchField: React.FC<Props> = ({
  name,
  onSearchEvent,
  searchInputRef,
  searchDelay = DEFAULT_SEARCH_DELAY,
}) => {
  const inputRef = useRef<TextInput | null>(null)

  const debouncedSearch = useCallback(
    debounce(
      (term: string) => {
        onSearchEvent({searchTerm: term})
      },
      searchDelay,
      {
        leading: false,
        trailing: true,
      }
    ),
    [onSearchEvent]
  )

  const handleSearch = (event: React.ChangeEvent<HTMLInputElement>) => {
    const term = event.target.value
    debouncedSearch(term)
  }

  const handleRef = (input: TextInput | null) => {
    inputRef.current = input
    if (input && 'inputRef' in input) {
      const customInput = input as CustomTextInput
      const inputElement = customInput.inputRef.current
      if (searchInputRef && inputElement) {
        searchInputRef(inputElement)
      }
    }
  }

  useEffect(() => {
    return () => {
      debouncedSearch.cancel()
    }
  }, [debouncedSearch])

  return (
    <TextInput
      renderLabel={
        <ScreenReaderContent>{I18n.t('Search discussions by title')}</ScreenReaderContent>
      }
      placeholder={I18n.t('Search...')}
      renderBeforeInput={<IconSearchLine />}
      ref={handleRef}
      onChange={handleSearch}
      name={name}
    />
  )
}
