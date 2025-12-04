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

import React, {useEffect, useState} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useDebouncedCallback} from 'use-debounce'
import {IconButton} from '@instructure/ui-buttons'
import {Alert} from '@instructure/ui-alerts'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('accessibility_checker')

interface SearchIssueProps {
  onSearchChange: (value: string) => Promise<boolean>
}

export const SearchIssue: React.FC<SearchIssueProps> = ({onSearchChange}) => {
  const [searchInput, setSearchInput] = useState<string>('')
  const [alertMessage, setAlertMessage] = useState<string | null>(null)

  useEffect(() => {
    const queryString = window.location.search
    const params = new URLSearchParams(queryString)
    const searchQuery = params.get('search')
    if (searchQuery) {
      setSearchInput(searchQuery)
    }
  }, [])

  useEffect(() => {
    if (alertMessage !== null) {
      const timeout = setTimeout(() => setAlertMessage(null), 3000)
      return () => clearTimeout(timeout)
    }
  }, [alertMessage, setAlertMessage])

  const shouldSearch = (searchString: string) => {
    const searchQueryLength = searchString.trim().length
    return searchQueryLength === 0 || searchQueryLength >= 3
  }

  const debouncedOnSearchChange = useDebouncedCallback((value: string) => {
    if (shouldSearch(value)) {
      onSearchChange(value).then(result => {
        const msg =
          value.length > 0
            ? I18n.t('Search filter applied. Accessibility issues updated.')
            : I18n.t('Search filter cleared. Accessibility issues updated.')

        setTimeout(() => result && setAlertMessage(msg), 1500)
      })
    }
  }, 300)

  const handleChange = (value: string) => {
    setSearchInput(value)
    debouncedOnSearchChange(value)
  }

  const clearButton = () => {
    if (!searchInput.length) return null

    return (
      <IconButton
        type="button"
        size="small"
        withBackground={false}
        withBorder={false}
        onClick={() => handleChange('')}
        screenReaderLabel={I18n.t('Clear search')}
        data-testid="clear-search-button"
      >
        <IconTroubleLine />
      </IconButton>
    )
  }

  return (
    <>
      <View as="div" margin="medium 0">
        {/* Wrap search input in form with role="search" for accessibility landmark navigation */}
        <form role="search" onSubmit={e => e.preventDefault()}>

          <TextInput
            id="issueSearchInput"
            value={searchInput}
            renderBeforeInput={() => <IconSearchLine inline={false} />}
            renderAfterInput={clearButton}
            renderLabel={''}
            onChange={event => handleChange(event.target.value)}
            messages={[
              {
                type: 'hint',
                text: I18n.t(
                  'Start typing to search. Results will update automatically after 3 characters.',
                ),
              },
            ]}
            placeholder={I18n.t('Search resource titles...')}
            width="100%"
            data-testid="issue-search-input"
          />
        </form>
      </View>
      {alertMessage && (
        <Alert
          liveRegion={getLiveRegion}
          liveRegionPoliteness="assertive"
          isLiveRegionAtomic
          screenReaderOnly
        >
          {alertMessage}
        </Alert>
      )}
    </>
  )
}
