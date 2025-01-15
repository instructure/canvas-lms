/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import * as actions from '../flickr'
import {spiedStore} from './utils'

describe('Flickr data actions', () => {
  const successSource = {
    searchFlickr() {
      return Promise.resolve([{go: 'baduk'}])
    },
  }

  const defaults = {
    jwt: 'theJWT',
    source: successSource,
  }

  function setupState(props) {
    return {...defaults, ...props}
  }

  describe('searchFlickr', () => {
    it('chains through search to results', async () => {
      const baseState = setupState()
      baseState.flickr = {searching: false}
      const store = spiedStore(baseState)

      await store.dispatch(actions.searchFlickr('weiqi'))

      expect(store.spy).toHaveBeenCalledWith({
        type: actions.START_FLICKR_SEARCH,
        term: 'weiqi',
      })

      expect(store.spy).toHaveBeenCalledWith({
        type: actions.RECEIVE_FLICKR_RESULTS,
        results: [{go: 'baduk'}],
      })
    })
  })
})
