/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {shallow} from 'enzyme'
import NewUserTutorialToggleButton from '../NewUserTutorialToggleButton'
import createTutorialStore from '../util/createTutorialStore'

describe('NewUserTutorialToggleButton Spec', () => {
  test('Defaults to expanded', () => {
    const store = createTutorialStore()
    const wrapper = shallow(<NewUserTutorialToggleButton store={store} />)
    expect(wrapper.state('isCollapsed')).toBeFalsy()
  })

  test('Toggles isCollapsed when clicked', () => {
    const fakeEvent = {
      preventDefault() {},
    }

    const store = createTutorialStore()
    const wrapper = shallow(<NewUserTutorialToggleButton store={store} />)
    wrapper.simulate('click', fakeEvent)
    expect(wrapper.state('isCollapsed')).toBeTruthy()
  })

  test('shows IconMoveStart when isCollapsed is true', () => {
    const store = createTutorialStore({isCollapsed: true})
    const wrapper = shallow(<NewUserTutorialToggleButton store={store} />)
    expect(wrapper.find('IconMoveStartLine').exists()).toBeTruthy()
  })

  test('shows IconMoveEnd when isCollapsed is false', () => {
    const store = createTutorialStore({isCollapsed: false})
    const wrapper = shallow(<NewUserTutorialToggleButton store={store} />)
    expect(wrapper.find('IconMoveEndLine').exists()).toBeTruthy()
  })
})
