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

import imageSection, {initialState} from '../imageSection'

describe('imageSection()', () => {
  const subject = (action, stateOverrides) =>
    imageSection({...initialState, ...stateOverrides}, action)

  it('handles "ClearMode" actions', () => {
    expect(subject({type: 'ClearMode'})).toMatchObject(initialState)
  })

  it('handles "Course" actions', () => {
    expect(subject({type: 'Course'})).toMatchObject({
      ...initialState,
      mode: 'Course',
    })
  })

  it('handles "Upload" actions', () => {
    expect(subject({type: 'Upload'})).toMatchObject({
      ...initialState,
      mode: 'Upload',
    })
  })

  it('handles "SingleColor" actions', () => {
    expect(subject({type: 'SingleColor'})).toMatchObject({
      ...initialState,
      mode: 'SingleColor',
    })
  })

  it('handles "MultiColor" actions', () => {
    expect(subject({type: 'MultiColor'})).toMatchObject({
      ...initialState,
      mode: 'MultiColor',
    })
  })

  it('handles "StartLoading" actions', () => {
    expect(subject({type: 'StartLoading'})).toMatchObject({
      ...initialState,
      loading: true,
    })
  })

  it('handles "StopLoading" actions', () => {
    expect(subject({type: 'StopLoading'})).toMatchObject({
      ...initialState,
      loading: false,
    })
  })

  it('handles "SetImage" actions', () => {
    expect(subject({type: 'SetImage', payload: 'img'})).toMatchObject({
      ...initialState,
      image: 'img',
    })
  })

  it('handles "SetImageName" actions', () => {
    expect(subject({type: 'SetImageName', payload: 'name'})).toMatchObject({
      ...initialState,
      imageName: 'name',
    })
  })

  describe('with an invalid action', () => {
    expect(() => subject({type: 'Banana'})).toThrow('Unknown action for image selection reducer')
  })
})
