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

import initialState from '../initialState'
import RceApiSource from '../../../rcs/api'

describe('Sidebar initialState', () => {
  let source, apiSource

  beforeEach(() => {
    source = {
      initializeCollection() {
        return {}
      },
      initializeUpload() {
        return {}
      },
      initializeImages() {
        return {}
      },
      initializeFlickr() {
        return {}
      },
      initializeDocuments() {
        return {}
      },
      initializeMedia() {
        return {}
      },
    }
    apiSource = new RceApiSource()
  })

  it('accepts provided contextType', () => {
    const state = initialState({contextType: 'group'})
    expect(state.contextType).toEqual('group')
  })

  it('normalizes provided contextType', () => {
    const state = initialState({contextType: 'groups'})
    expect(state.contextType).toEqual('group')
  })

  it('accepts provided jwt', () => {
    const state = initialState({jwt: 'theJWT'})
    expect(state.jwt).toEqual('theJWT')
  })

  it('accepts provided source', () => {
    const state = initialState({source})
    expect(state.source).toEqual(source)
  })

  it('accepts provided collections', () => {
    const collections = {iKnowBetterThan: 'theStore'}
    const state = initialState({collections})
    expect(state.collections).toEqual(collections)
  })

  describe('defaults', () => {
    it('contextType to undefined', () => {
      expect(initialState().contextType).toBeUndefined()
    })

    it('jwt to undefined', () => {
      expect(initialState().jwt).toBeUndefined()
    })

    it('source to the api source', () => {
      expect(initialState().source).toEqual(apiSource)
    })

    it('initial collections using source', () => {
      const state = initialState({
        source: Object.assign(source, {
          initializeCollection(endpoint) {
            return {links: [], bookmark: endpoint, loading: false}
          },
        }),
      })
      expect(state.collections.announcements.bookmark).toEqual('announcements')
    })

    it('searchString is empty string', () => {
      expect(initialState().searchString).toEqual('')
    })

    it('sortBy sorts by date desc', () => {
      expect(initialState().sortBy).toEqual({sort: 'date_added', dir: 'desc'})
    })

    it('all_files is not loadingt', () => {
      expect(initialState().all_files).toEqual({isLoading: false})
    })
  })
})
