//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {map} from 'lodash'
import {View} from '@canvas/backbone'
import AutocompleteView from './AutocompleteView'

export default class SearchView extends View {
  static initClass() {
    this.prototype.els = {'#search-autocomplete': '$autocomplete'}
  }

  initialize() {
    super.initialize(...arguments)
    this.render()
    this.autocompleteView = new AutocompleteView({
      el: this.$autocomplete,
      single: true,
      excludeAll: true,
    }).render()
    return this.autocompleteView.on('changeToken', this.onSearch, this)
  }

  onSearch(tokens) {
    return this.trigger(
      'search',
      map(tokens, x => `user_${x}`)
    )
  }
}
SearchView.initClass()
