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

import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('files_v2')

const renderClearButton = (searchValue: string, handleClear: () => void) => {
  if (searchValue === '') return null

  return (
    <IconButton
      type="button"
      size="small"
      withBackground={false}
      withBorder={false}
      screenReaderLabel={I18n.t('Clear search')}
      onClick={handleClear}
    >
      <IconTroubleLine />
    </IconButton>
  )
}

interface SearchBarProps {
  initialValue?: string
  onSearch: (searchTerm: string) => void
}

const SearchBar = ({initialValue = '', onSearch}: SearchBarProps) => {
  const [searchValue, setSearchValue] = useState(initialValue)

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    if (searchValue === '') {
      return
    }

    onSearch(searchValue)
  }

  const handleClear = () => {
    setSearchValue('')
  }

  return (
    <form style={{margin: 0}} name="files-search" autoComplete="off" onSubmit={handleSearch}>
      <Flex gap="small">
        <Flex.Item shouldGrow shouldShrink>
          <TextInput
            renderLabel={<ScreenReaderContent>{I18n.t('Search files...')}</ScreenReaderContent>}
            placeholder={I18n.t('Search files...')}
            value={searchValue}
            onChange={(_e, value) => setSearchValue(value)}
            shouldNotWrap
            // fragment fixes a weird focus issue - INSTUI-4466
            renderBeforeInput={<IconSearchLine inline={false} />}
            renderAfterInput={() => renderClearButton(searchValue, handleClear)}
            data-testid="files-search-input"
          />
        </Flex.Item>
        <Flex.Item>
          <Button color="secondary" type="submit" data-testid="files-search-button">
            {I18n.t('Search')}
          </Button>
        </Flex.Item>
      </Flex>
    </form>
  )
}

export default SearchBar
