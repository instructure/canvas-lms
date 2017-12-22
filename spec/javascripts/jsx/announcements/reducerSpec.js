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

import actions from 'jsx/announcements/actions'
import reducer from 'jsx/announcements/reducer'

QUnit.module('Announcements reducer')

const reduce = (action, state = {}) => reducer(state, action)

test('UPDATE_ANNOUNCEMENTS_SEARCH should not update term when term is not defined', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({}), {
    announcementsSearch: { term: 'test' },
  })
  deepEqual(newState.announcementsSearch.term, 'test')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should update term to empty string when term is shorter than 3 chars', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({ term: 'te' }), {
    announcementsSearch: { term: 'test' },
  })
  deepEqual(newState.announcementsSearch.term, '')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should update term to empty string when term is empty string', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({ term: '' }), {
    announcementsSearch: { term: 'test' },
  })
  deepEqual(newState.announcementsSearch.term, '')
})

test('UPDATE_ANNOUNCEMENTS_SEARCH should update term to term in payload when term is at least 3 chars', () => {
  const newState = reduce(actions.updateAnnouncementsSearch({ term: 'foo' }), {
    announcementsSearch: { term: 'test' },
  })
  deepEqual(newState.announcementsSearch.term, 'foo')
})
