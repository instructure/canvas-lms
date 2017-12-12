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
import {mount, shallow} from 'enzyme'
import CourseImageSelector from '../CourseImageSelector'
import initialState from '../../store/initialState'


describe('CourseImageSelector', () => {
  const fakeStore = () => ({
    subscribe: jest.fn(),
    dispatch: jest.fn(),
    getState: () => initialState
  })

  it('renders', () => {
    const wrapper = mount(<CourseImageSelector store={fakeStore()} />)
    expect(wrapper.text()).toContain('Loading')
  })

  it('sets the background image style properly', () => {
    const store = fakeStore()
    store.getState = jest.fn().mockReturnValue({...initialState, imageUrl: 'http://coolUrl'})
    const wrapper = shallow(<CourseImageSelector store={store} />)

    expect(wrapper.find('.CourseImageSelector').prop('style').backgroundImage).toBe('url(http://coolUrl)')
  })

  it('renders course image edit options when an image is present', () => {
    const store = fakeStore()
    store.getState = jest.fn().mockReturnValue({...initialState, imageUrl: 'http://coolUrl'})
    const wrapper = shallow(<CourseImageSelector store={store} />)

    wrapper.setState({gettingImage: false})
    expect(wrapper.find('PopoverMenu').exists()).toBeTruthy()
  })

})




