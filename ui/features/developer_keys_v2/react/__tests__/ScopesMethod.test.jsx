/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {mount} from 'enzyme'
import DeveloperKeyScopesMethod from '../ScopesMethod'

const props = {
  method: 'get',
}

it('renders the correct method', () => {
  const wrapper = mount(<DeveloperKeyScopesMethod {...props} />)
  expect(wrapper.find('span').first().text()).toContain(props.method)
})

describe('variant map', () => {
  it('maps GET to the primary variant', () => {
    const wrapper = mount(<DeveloperKeyScopesMethod {...props} />)
    expect(wrapper.instance().methodColorMap().get).toBe('primary')
  })

  it('maps PUT to the default variant', () => {
    const wrapper = mount(<DeveloperKeyScopesMethod {...props} />)
    expect(wrapper.instance().methodColorMap().put).toBe('default')
  })

  it('maps POST to the success variant', () => {
    const wrapper = mount(<DeveloperKeyScopesMethod {...props} />)
    expect(wrapper.instance().methodColorMap().post).toBe('success')
  })

  it('maps DELETE to the danger variant', () => {
    const wrapper = mount(<DeveloperKeyScopesMethod {...props} />)
    expect(wrapper.instance().methodColorMap().delete).toBe('danger')
  })
})
