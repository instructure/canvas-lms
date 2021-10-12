/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import imageSection, {defaultState} from '../imageSection'

describe('imageSection()', () => {
  const subject = (action, stateOverrides) =>
    imageSection({...defaultState, ...stateOverrides}, action)

  it('handles "Course" actions', () => {
    expect(subject({type: 'Course'})).toMatchObject({
      ...defaultState,
      mode: 'Course'
    })
  })

  it('handles "Upload" actions', () => {
    expect(subject({type: 'Upload'})).toMatchObject({
      ...defaultState,
      mode: 'Upload'
    })
  })

  it('handles "SingleColor" actions', () => {
    expect(subject({type: 'SingleColor'})).toMatchObject({
      ...defaultState,
      mode: 'SingleColor'
    })
  })

  it('handles "MultiColor" actions', () => {
    expect(subject({type: 'MultiColor'})).toMatchObject({
      ...defaultState,
      mode: 'MultiColor'
    })
  })

  describe('with an invalid action', () => {
    expect(() => subject({type: 'Banana'})).toThrow('Unknown action for image selection reducer')
  })
})
