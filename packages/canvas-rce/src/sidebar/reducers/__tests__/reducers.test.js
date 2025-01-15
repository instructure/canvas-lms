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

import * as actions from '../../actions/data'
import reducer from '..'

describe('Sidebar reducer', () => {
  // collection key to use in testing
  const state = {
    contextType: 'course',
    collections: {
      announcements: {
        // has bookmark, not loading
        links: [{href: 'announcement', title: 'Announcement'}],
        bookmark: 'announcementsBookmark',
        isLoading: false,
      },
      modules: {
        // has bookmark, is loading
        links: [{href: 'module', title: 'Module'}],
        bookmark: 'modulesBookmark',
        isLoading: true,
      },
    },
  }

  describe('REQUEST_PAGE', () => {
    it('sets the loading flag on the appropriate collection', () => {
      const newState = reducer(state, actions.requestPage('announcements'))
      expect(newState.collections.announcements.isLoading).toBe(true)
    })

    it('leaves the other collections alone', () => {
      const newState = reducer(state, actions.requestPage('modules'))
      expect(newState.collections.announcements).toEqual(state.collections.announcements)
    })

    it('leaves non-collection keys alone', () => {
      const newState = reducer(state, actions.requestPage('announcements'))
      expect(newState.contextType).toEqual(state.contextType)
    })
  })

  describe('RECEIVE_PAGE', () => {
    const page = {
      links: [{href: 'newLink', title: 'New Link'}],
      bookmark: 'newBookmark',
    }

    it('appends results to the appropriate collection', () => {
      const newState = reducer(state, actions.receivePage('modules', page))
      expect(newState.collections.modules.links.length).toEqual(2)
      expect(newState.collections.modules.links[1]).toEqual(page.links[0])
    })

    it('updates the bookmark on the appropriate collection', () => {
      const newState = reducer(state, actions.receivePage('modules', page))
      expect(newState.collections.modules.bookmark).toEqual(page.bookmark)
    })

    it('clears the loading flag on the appropriate collection', () => {
      const newState = reducer(state, actions.receivePage('modules', page))
      expect(newState.collections.modules.isLoading).toBe(false)
    })

    it('leaves the other collections alone', () => {
      const newState = reducer(state, actions.requestPage('announcements', page))
      expect(newState.collections.modules).toEqual(state.collections.modules)
    })
  })

  describe('FAIL_PAGE', () => {
    it('clears the loading flag on the appropriate collection', () => {
      const newState = reducer(state, actions.failPage('modules'))
      expect(newState.collections.modules.isLoading).toBe(false)
    })

    it('clears the bookmark if the links are empty', () => {
      const emptyModules = {...state.collections.modules, links: []}
      const emptyModulesCollections = {...state.collections, modules: emptyModules}
      const emptyModulesState = {...state, collections: emptyModulesCollections}
      const newState = reducer(emptyModulesState, actions.failPage('modules'))
      expect(newState.collections.modules.bookmark).toBeNull()
    })

    it('leaves the links and bookmark on that collection alone otherwise', () => {
      const newState = reducer(state, actions.failPage('modules'))
      expect(newState.collections.modules.links).toEqual(state.collections.modules.links)
      expect(newState.collections.modules.bookmark).toEqual(state.collections.modules.bookmark)
    })

    it('leaves the other collections alone', () => {
      const newState = reducer(state, actions.failPage('announcements'))
      expect(newState.collections.modules).toEqual(state.collections.modules)
    })
  })
})
