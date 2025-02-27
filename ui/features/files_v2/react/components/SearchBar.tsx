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

import {useNavigate, useLocation} from 'react-router-dom'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {useState, useRef, useEffect} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'

const I18n = createI18nScope('files_v2')

interface SearchBarProps {
  initialValue?: string
}

const SearchBar = ({initialValue = ''}: SearchBarProps) => {
  const [searchValue, setSearchValue] = useState(initialValue)
  const timeoutRef = useRef<number | undefined>(undefined)
  const navigate = useNavigate()
  const location = useLocation()

  useEffect(() => {
    if (!location.pathname.includes('/search')) {
      setSearchValue('')
    }
  }, [location.pathname])

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>, searchString: string) => {
    e.preventDefault()
    setSearchValue(searchString)
    clearTimeout(timeoutRef.current)
    startSearch(searchString)
  }

  const startSearch = (searchString: string) => {
    timeoutRef.current = window.setTimeout(() => {
      if (searchString === '') {
        handleClear()
        return
      }
      const path = window.location.pathname
      const context = path.split('/')[3]
      const searchUrl = filesEnv.showingAllContexts
        ? `/folder/${context}/search?search_term=${searchString}`
        : `/search?search_term=${searchString}`
      navigate(searchUrl)
    }, 350)
  }

  const handleClear = () => {
    setSearchValue('')
    clearTimeout(timeoutRef.current)
    const path = window.location.pathname
    const context = path.split('/')[3]
    const clearUrl = filesEnv.showingAllContexts ? `/folder/${context}` : '/'
    navigate(clearUrl)
  }

  const renderClearButton = () => {
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

  return (
    <View as="div">
      <form name="files-search" autoComplete="off">
        <TextInput
          renderLabel={<ScreenReaderContent>{I18n.t('Search files...')}</ScreenReaderContent>}
          placeholder={I18n.t('Search files...')}
          value={searchValue}
          onChange={(e, value) => handleChange(e, value)}
          onKeyDown={e => {
            if (e.key === 'Enter') e.preventDefault()
          }}
          shouldNotWrap
          renderBeforeInput={<IconSearchLine inline={false} />}
          renderAfterInput={renderClearButton}
          data-testid="files-search-input"
        />
      </form>
    </View>
  )
}

export default SearchBar
