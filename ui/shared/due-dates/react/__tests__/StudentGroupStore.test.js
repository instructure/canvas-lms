/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import _ from 'lodash'
import StudentGroupStore from '../StudentGroupStore'
import fakeENV from '@canvas/test-utils/fakeENV'
import sinon from 'sinon'

describe('StudentGroupStore', () => {
  let server
  let responseA
  let responseB

  beforeEach(() => {
    StudentGroupStore.reset()
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    server = sinon.fakeServer.create()

    responseA = [
      {id: 1, title: 'group A', group_category_id: 1},
      {id: 2, title: 'group B', group_category_id: 1},
    ]
    responseB = [
      {id: 3, title: 'group C', group_category_id: 1},
      {id: 4, title: 'group D', group_category_id: 1},
    ]

    // single page
    server.respondWith('GET', '/api/v1/courses/1/groups', [
      200,
      {
        'Content-Type': 'application/json',
        Link: {},
      },
      JSON.stringify(responseA),
    ])

    const linkHeaders1 =
      '<http://api/v1/courses/2/groups?page=2&per_page=2>; rel="next",' +
      '<http://api/v1/courses/2/groups?page=1&per_page=2>; rel="current",' +
      '<http://api/v1/courses/2/groups?page=1&per_page=2>; rel="first",' +
      '<http://api/v1/courses/2/groups?page=2&per_page=2>; rel="last"'

    // multiple pages
    server.respondWith('GET', '/api/v1/courses/2/groups', [
      200,
      {'Content-Type': 'application/json', Link: linkHeaders1},
      JSON.stringify(responseA),
    ])
    server.respondWith('GET', 'http://api/v1/courses/2/groups?page=2&per_page=2', [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(responseB),
    ])
  })

  afterEach(() => {
    server.restore()
    StudentGroupStore.reset()
    fakeENV.teardown()
  })

  // ==================
  //   GETTING STATE
  // ==================
  it('returns groups', () => {
    const someArbitraryVal = 'foo'
    StudentGroupStore.setState({groups: someArbitraryVal})
    expect(StudentGroupStore.getGroups()).toBe(someArbitraryVal)
  })

  it('returns selected group set id', () => {
    const someArbitraryID = 22
    StudentGroupStore.setState({selectedGroupSetId: someArbitraryID})
    expect(StudentGroupStore.getSelectedGroupSetId()).toBe(someArbitraryID)
  })

  it('returns groups filtered by selected group set', () => {
    const g3 = {id: 3, title: 'group C', group_category_id: 3}
    const groups = {
      1: {id: 1, title: 'group A', group_category_id: 1},
      2: {id: 2, title: 'group B', group_category_id: 1},
      3: g3,
    }
    StudentGroupStore.setState({
      groups,
      selectedGroupSetId: 3,
    })
    expect(StudentGroupStore.groupsFilteredForSelectedSet()).toEqual([g3])
  })

  // ==================
  //   SETTING STATE
  // ==================
  it('adding groups works', () => {
    const g1 = {id: 1, title: 'group 1'}
    const initialGroups = {1: g1}
    const g2 = {id: 2, title: 'group 2'}
    const arrayOfGroups = [{id: 2, title: 'group 2'}]
    StudentGroupStore.setState({groups: initialGroups})
    StudentGroupStore.addGroups(arrayOfGroups)
    expect(StudentGroupStore.getGroups()).toEqual(_.keyBy([g1, g2], 'id'))
  })

  // ==================
  //  FETCHING GROUPS
  // ==================
  it('groups are added to state once fetched', () => {
    StudentGroupStore.fetchGroupsForCourse('/api/v1/courses/1/groups')
    server.respond()
    expect(StudentGroupStore.getGroups()[1].title).toBe('group A')
  })

  it('multiple calls are made if server has multiple pages', () => {
    ENV.context_asset_string = 'course_2'
    StudentGroupStore.fetchGroupsForCourse()
    server.respond()
    expect(_.values(StudentGroupStore.getGroups()).length).toBe(2)
    expect(StudentGroupStore.fetchComplete()).toBe(false)
    server.respond()
    expect(_.values(StudentGroupStore.getGroups()).length).toBe(4)
    expect(StudentGroupStore.fetchComplete()).toBe(true)
  })
})
