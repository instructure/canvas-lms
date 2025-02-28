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

import React, {useState, useEffect, useMemo} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconSearchLine} from '@instructure/ui-icons'
import {debounce} from 'lodash'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('differentiation_tags')

interface DifferentiationTagSearchProps {
  onSearch: (value: string) => void
  delay?: number
  initialValue?: string
}

const DifferentiationTagSearch: React.FC<DifferentiationTagSearchProps> = ({
  onSearch,
  delay = 100,
  initialValue = '',
}) => {
  const [inputValue, setInputValue] = useState(initialValue)

  const debouncedSearch = useMemo(
    () => debounce((value: string) => onSearch(value), delay),
    [onSearch, delay],
  )

  useEffect(() => {
    debouncedSearch(inputValue)
    return () => {
      debouncedSearch.cancel()
    }
  }, [inputValue, debouncedSearch])

  return (
    <TextInput
      placeholder={I18n.t('Search for Tag')}
      value={inputValue}
      onChange={e => setInputValue(e.target.value)}
      renderLabel={<ScreenReaderContent>{I18n.t('Search for Tag')}</ScreenReaderContent>}
      renderBeforeInput={() => <IconSearchLine />}
      width="100%"
      display="inline-block"
    />
  )
}

export default DifferentiationTagSearch
