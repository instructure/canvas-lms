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

import React from 'react'
import {render} from '@testing-library/react'

import Actions from '../../actions'
import CourseImageSelector from '../CourseImageSelector'
import initialState from '../../store/initialState'

jest.mock('../../actions')

afterEach(() => {
  jest.resetAllMocks()
})

describe('CourseImageSelector', () => {
  const defaultProps = {
    courseId: '1',
    name: 'course[image]',
    setting: 'image',
  }

  const fakeStore = () => ({
    subscribe: jest.fn(),
    dispatch: jest.fn(),
    getState: () => initialState,
  })

  it('renders', () => {
    const wrapper = render(<CourseImageSelector {...defaultProps} store={fakeStore()} />)
    expect(wrapper.getByText('Loading')).toBeInTheDocument()
  })

  it('sets the background image style properly', () => {
    const store = fakeStore()
    store.getState = jest.fn().mockReturnValue({...initialState, imageUrl: 'http://coolUrl'})
    const {container} = render(<CourseImageSelector {...defaultProps} store={store} />)

    const element = container.querySelector('.CourseImageSelector')
    expect(element.style.backgroundImage).toBe('url(http://coolUrl)')
  })

  it('renders course image edit options when an image is present', () => {
    const store = fakeStore()
    const mockState = {
      ...initialState,
      imageUrl: 'http://coolUrl',
      gettingImage: false,
      removingImage: false,
    }
    store.getState = jest.fn().mockReturnValue(mockState)

    // Mock the subscribe callback to trigger state updates
    let subscribeCallback
    store.subscribe = jest.fn(callback => {
      subscribeCallback = callback
    })

    const {container} = render(<CourseImageSelector {...defaultProps} store={store} />)

    // Trigger the subscription callback to update the component state
    if (subscribeCallback) {
      subscribeCallback()
    }

    // The Menu component should be present when image exists and not loading
    const menuTrigger = container.querySelector('button')
    expect(menuTrigger).toBeTruthy()
  })

  it('adds the wide classname if the wide prop is true', () => {
    const store = fakeStore()
    store.getState = jest.fn().mockReturnValue({...initialState, imageUrl: 'http://coolUrl'})
    const {container} = render(<CourseImageSelector {...defaultProps} store={store} wide={true} />)

    const wrapper = container.querySelector('.CourseImageSelectorWrapper')
    expect(wrapper.classList.contains('wide')).toBe(true)
  })

  it('passes the setting prop to actions', () => {
    const store = fakeStore()
    store.getState = jest.fn().mockReturnValue({...initialState, imageUrl: 'http://coolUrl'})
    render(<CourseImageSelector {...defaultProps} setting="banner_image" store={store} />)

    expect(Actions.getCourseImage).toHaveBeenCalledWith('1', 'banner_image')
  })
})
