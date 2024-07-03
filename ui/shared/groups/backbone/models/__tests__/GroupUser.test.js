/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Group from '../Group'
import GroupUser from '../GroupUser'
import GroupCategory from '../GroupCategory'

describe('GroupUser', () => {
  let groupUser
  let leaveGroupSpy
  let joinGroupSpy

  beforeEach(() => {
    const groupCategory = new GroupCategory()
    groupUser = new GroupUser({category: groupCategory})
    leaveGroupSpy = jest.spyOn(groupUser, 'leaveGroup')
    joinGroupSpy = jest.spyOn(groupUser, 'joinGroup')
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  test('updates group correctly upon save and fires joinGroup and leaveGroup appropriately', () => {
    const group1 = new Group({id: 777})
    groupUser.save({group: group1})

    expect(groupUser.get('group')).toBe(group1)
    expect(joinGroupSpy).toHaveBeenCalledTimes(1)
    expect(joinGroupSpy).toHaveBeenCalledWith(group1)
    expect(leaveGroupSpy).not.toHaveBeenCalled()

    const group2 = new Group({id: 123})
    groupUser.save({group: group2})

    expect(groupUser.get('group')).toBe(group2)
    expect(joinGroupSpy).toHaveBeenCalledTimes(2)
    expect(joinGroupSpy).toHaveBeenCalledWith(group2)

    groupUser.save({group: null})

    expect(groupUser.get('group')).toBeNull()
    expect(joinGroupSpy).toHaveBeenCalledTimes(2)
    expect(leaveGroupSpy).toHaveBeenCalledTimes(1)
  })
})
