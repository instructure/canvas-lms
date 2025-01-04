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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {shallow} from 'enzyme'
import BlueprintSidebar from '../BlueprintSidebar'
describe('BlueprintSidebar', () => {
  let wrapper

  beforeEach(() => {
    jest.useFakeTimers()
  })

  afterEach(() => {
    jest.useRealTimers()
  })

  test('renders the BlueprintSidebar component', () => {
    wrapper = shallow(<BlueprintSidebar />)
    expect(wrapper.find('.bcs__wrapper').exists()).toBeTruthy()
  })

  test('clicking open button sets isOpen to true', async () => {
    const ref = React.createRef()
    wrapper = render(<BlueprintSidebar ref={ref} />)
    const button = wrapper.container.querySelectorAll('.bcs__trigger button')[0]
    const user = userEvent.setup({delay: null})
    await user.click(button)
    jest.advanceTimersByTime(500)
    expect(ref.current.state.isOpen).toEqual(true)
  })

  test('clicking close button sets isOpen to false', () => {
    const ref = React.createRef()
    wrapper = render(<BlueprintSidebar ref={ref} />)
    ref.current.open()
    jest.advanceTimersByTime(500)
    ref.current.closeBtn.click()
    jest.advanceTimersByTime(500)
    expect(ref.current.state.isOpen).toEqual(false)
  })
})
