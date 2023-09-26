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

import React, { useState } from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {IconSearchLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'

import SearchResults from './SearchResults'

const I18n = useI18nScope('SmartSearch')

export default function SearchApp() {
  const [searchResults, setSearchResults] = useState([]);
  const [searchString, setSearchString] = useState('');
  const [searching, setSearching] = useState(false);
  const [textInput, setTextInput] = useState(null);

  async function handleKey(event) {
    if (event.key === 'Enter' && event.type === 'keydown') {
      setSearching(true)
      await runSearch(searchString)
      setSearching(false)
      textInput.focus()
    }
  }

  function handleChange(e, value) {
    setSearchString(value)
  }

  async function runSearch(searchString) {
    const res = await fetch(`/smartsearch?q=${searchString}`)
    const json = await res.json()

    const searchResults = json.results

    setSearchResults(searchResults)
  }

  return (
    <View>
      <div onKeyDown={handleKey}>
        <TextInput
          renderLabel={<h1>{I18n.t('Search')}</h1>}
          interaction={searching ? 'disabled' : 'enabled'}
          ref={e => (setTextInput(e))}
          onChange={handleChange}
          value={searchString}
          renderAfterInput={() => <IconSearchLine />}
        />
      </div>
      {searching ? <Spinner renderTitle={I18n.t('Searching')} /> : null}

      <SearchResults searchResults={searchResults} />
    </View>
  )
}
