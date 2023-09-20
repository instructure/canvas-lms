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

import React from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {IconSearchLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'

import SearchResults from './SearchResults'

export default class SearchApp extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      searchResults: [],
      searchString: '',
      searching: false,
    }
    this.handleKey = this.handleKey.bind(this)
    this.handleChange = this.handleChange.bind(this)
  }

  async handleKey(event) {
    if (event.key === 'Enter' && event.type === 'keydown') {
      const searchString = this.state.searchString
      this.setState({searching: true})
      await this.runSearch(searchString)
      this.setState({searching: false})
      this.textInput.focus()
    }
  }

  handleChange(e, value) {
    this.setState({searchString: value})
  }

  async runSearch(searchString) {
    const res = await fetch(`/smartsearch?q=${searchString}`)
    const json = await res.json()

    const searchResults = json.results

    this.setState({searchResults})
  }

  render() {
    return (
      <View>
        <div onKeyDown={this.handleKey}>
          <TextInput
            interaction={this.state.searching ? 'disabled' : 'enabled'}
            ref={e => (this.textInput = e)}
            onChange={this.handleChange}
            value={this.state.searchString}
            renderAfterInput={() => <IconSearchLine />}
          />
        </div>
        {this.state.searching ? <Spinner /> : null}

        <SearchResults searchResults={this.state.searchResults} />
      </View>
    )
  }
}
