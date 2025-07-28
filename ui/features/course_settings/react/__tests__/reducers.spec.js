/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import reducer from '../reducer'

describe('Course Settings Reducer', () => {
  test('Unknown action types return initialState', () => {
    const initialState = {
      courseImage: 'abc',
    }

    const action = {
      type: 'I_AM_NOT_A_REAL_ACTION',
    }

    const newState = reducer(initialState, action)
    expect(newState).toEqual(initialState)
  })

  test('sets the modal visibility properly', () => {
    const action = {
      type: 'MODAL_VISIBILITY',
      payload: {
        showModal: true,
      },
    }

    const initialState = {
      showModal: false,
    }

    const newState = reducer(initialState, action)
    expect(newState.showModal).toBe(true)
  })

  test('sets uploading image properly', () => {
    const action = {
      type: 'UPLOADING_IMAGE',
    }

    const initialState = {
      uploadingImage: false,
    }

    const newState = reducer(initialState, action)
    expect(newState.uploadingImage).toBe(true)
  })

  test('sets course image properly', () => {
    const action = {
      type: 'GOT_COURSE_IMAGE',
      payload: {
        imageString: '123',
        imageUrl: 'http://imageUrl',
      },
    }

    const initialState = {
      courseImage: 'abc',
      imageUrl: '',
    }

    const newState = reducer(initialState, action)
    expect(newState.courseImage).toBe('123')
    expect(newState.imageUrl).toBe('http://imageUrl')
  })

  test('SET_COURSE_IMAGE_ID', () => {
    const action = {
      type: 'SET_COURSE_IMAGE_ID',
      payload: {
        imageUrl: 'http://imageUrl',
        imageId: '42',
      },
    }

    const initialState = {
      imageUrl: '',
      courseImage: '',
      showModal: true,
    }

    const newState = reducer(initialState, action)
    expect(newState.imageUrl).toBe('http://imageUrl')
    expect(newState.courseImage).toBe('42')
    expect(newState.showModal).toBe(false)
  })

  test('sets removing image properly', () => {
    const action = {
      type: 'REMOVING_IMAGE',
    }

    const initialState = {
      removingImage: false,
    }

    const newState = reducer(initialState, action)
    expect(newState.removingImage).toBe(true)
  })

  test('sets removed image properly', () => {
    const action = {
      type: 'REMOVED_IMAGE',
    }

    const initialState = {
      imageUrl: 'http://imageUrl',
      courseImage: '24',
      removingImage: true,
    }

    const newState = reducer(initialState, action)
    expect(newState.imageUrl).toBe('')
    expect(newState.courseImage).toBe('abc') // 'abc' needs to be the default or reset state in your reducer
    expect(newState.removingImage).toBe(false)
  })

  test('sets removing image to false on error', () => {
    const action = {
      type: 'ERROR_REMOVING_IMAGE',
    }

    const initialState = {
      removingImage: true,
    }

    const newState = reducer(initialState, action)
    expect(newState.removingImage).toBe(false)
  })
})
