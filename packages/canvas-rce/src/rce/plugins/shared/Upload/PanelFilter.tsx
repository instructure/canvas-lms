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

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconSearchLine, IconXLine} from '@instructure/ui-icons'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextInput} from '@instructure/ui-text-input'
import formatMessage from 'format-message'
import React, {useEffect, useState} from 'react'

interface PanelFilterProps {
  mountNode?: HTMLElement
  onChange: Function
  sortValue: string
  searchString: string
  contentType: string
}

function shouldSearch(searchString: string) {
  return searchString.length === 0 || searchString.length >= 3
}

export default function PanelFilter({
  mountNode,
  onChange,
  sortValue,
  searchString,
  contentType,
}: PanelFilterProps) {
  const [pendingSearchString, setPendingSearchString] = useState(searchString)
  const [searchInputTimer, setSearchInputTimer] = useState(0)

  // only run on mounting to trigger change to correct contextType
  useEffect(() => {
    onChange({contentType})
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  function doSearch(value: string) {
    if (shouldSearch(value)) {
      if (searchInputTimer) {
        window.clearTimeout(searchInputTimer)
        setSearchInputTimer(0)
      }
      onChange({searchString: value})
    }
  }

  function handleChangeSearch(value: string) {
    setPendingSearchString(value)
    if (searchInputTimer) {
      window.clearTimeout(searchInputTimer)
    }
    const tid = window.setTimeout(() => doSearch(value), 250)
    setSearchInputTimer(tid)
  }

  function handleClear() {
    handleChangeSearch('')
  }

  function renderClearButton() {
    if (pendingSearchString) {
      return (
        <IconButton
          screenReaderLabel={formatMessage('Clear')}
          onClick={handleClear}
          withBorder={false}
          withBackground={false}
          size="small"
        >
          <IconXLine />
        </IconButton>
      )
    }
    return undefined
  }

  return (
    <Flex margin="none xx-large none none" gap="small" alignItems="start">
      <Flex.Item shouldShrink={true} shouldGrow={false} margin="none none none none">
        <SimpleSelect
          data-testid="filter-sort-by"
          mountNode={mountNode}
          renderLabel={<ScreenReaderContent>{formatMessage('Sort By')}</ScreenReaderContent>}
          assistiveText={formatMessage('Use arrow keys to navigate options.')}
          onChange={(e, selection) => {
            onChange({sortValue: selection.value})
          }}
          value={sortValue}
        >
          <SimpleSelect.Option id="date_added" value="date_added">
            {formatMessage('Date Added')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="alphabetical" value="alphabetical">
            {formatMessage('Alphabetical')}
          </SimpleSelect.Option>
        </SimpleSelect>
      </Flex.Item>
      <Flex.Item shouldGrow={true} margin="none xx-large none none">
        <TextInput
          renderLabel={<ScreenReaderContent>{formatMessage('Search')}</ScreenReaderContent>}
          renderBeforeInput={<IconSearchLine inline={false} />}
          renderAfterInput={renderClearButton()}
          messages={[{type: 'hint', text: formatMessage('Enter at least 3 characters to search')}]}
          placeholder={formatMessage('Search')}
          value={pendingSearchString}
          onChange={(e, value) => handleChangeSearch(value)}
          onKeyDown={e => {
            if (e.key === 'Enter') {
              doSearch(pendingSearchString)
            }
          }}
        />
      </Flex.Item>
    </Flex>
  )
}
