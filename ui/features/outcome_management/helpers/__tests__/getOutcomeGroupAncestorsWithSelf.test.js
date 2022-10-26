/*
 * Copyright (C) 2022 - present Instructure, Inc.

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

import {getOutcomeGroupAncestorsWithSelf} from '../getOutcomeGroupAncestorsWithSelf'

describe('getOutcomeGroupAncestorsWithSelf', () => {
  const groupId = 2
  const siblingGroupId = 3
  const childGroupId = 4
  const parentGroupId = 1
  const collections = {
    [parentGroupId]: {parentGroupId: null},
    [groupId]: {parentGroupId},
    [siblingGroupId]: {parentGroupId},
    [childGroupId]: {parentGroupId: groupId},
  }

  it('returns self if group not in collections', () => {
    expect(getOutcomeGroupAncestorsWithSelf({}, groupId)).toEqual([groupId])
  })

  it('returns self if there are no ancestors', () => {
    expect(getOutcomeGroupAncestorsWithSelf(collections, parentGroupId)).toEqual([parentGroupId])
  })

  it('returns only ancestors and self and does not include sibling groups', () => {
    const result = getOutcomeGroupAncestorsWithSelf(collections, groupId)
    expect(result).toEqual([groupId, parentGroupId])
    expect(result).not.toContain(siblingGroupId)
  })

  it('returns only ancestors and self and does not include child groups', () => {
    const result = getOutcomeGroupAncestorsWithSelf(collections, groupId)
    expect(result).toEqual([groupId, parentGroupId])
    expect(result).not.toContain(childGroupId)
  })

  it('returns all ancestors and self if deeply nested', () => {
    const result = getOutcomeGroupAncestorsWithSelf(collections, childGroupId)
    expect(result).toEqual([childGroupId, groupId, parentGroupId])
  })
})
