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
import { shallow } from 'enzyme'
import ActAsModal from '../ActAsModal'
import ActAsMask from '../ActAsMask'
import ActAsPanda from '../ActAsPanda'
import Text from '@instructure/ui-elements/lib/components/Text'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Avatar from '@instructure/ui-elements/lib/components/Avatar'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import Table from '@instructure/ui-elements/lib/components/Table'

const props = {
  user: {
    name: 'test user',
    short_name: 'foo',
    id: '5',
    avatar_image_url: 'testImageUrl',
    sortable_name: 'bar, baz',
    email: 'testUser@test.com',
    pseudonyms: [{
      login_id: 'qux',
      sis_id: 555,
      integration_id: 222
    }, {
      login_id: 'tic',
      sis_id: 777,
      integration_id: 888
    }]
  }
}
describe('ActAsModal',  () => {
  it('renders with panda svgs, user avatar, table, and proceed button present', () => {
    const wrapper = shallow(<ActAsModal {...props} />)
    // expect(wrapper).toMatchSnapshot() // Coming soon.... (need to get enzyme upgraded to 3.x first)

    const mask = wrapper.find(ActAsMask)
    const panda = wrapper.find(ActAsPanda)
    const button = wrapper.find(Button)

    expect(mask.exists()).toBeTruthy()
    expect(panda.exists()).toBeTruthy()
    expect(button.exists()).toBeTruthy()
  })

  it('renders avatar with user image url', () => {
    const wrapper = shallow(<ActAsModal {...props} />)
    const avatar = wrapper.find(Avatar)

    expect(avatar.props().src).toBe('testImageUrl')
  })

  test('it renders the table with correct user information', () => {
    const wrapper = shallow(<ActAsModal {...props} />)
    const tables = wrapper.find(Table)

    expect(tables).toHaveLength(3)

    const textContent = []
    tables.find('tr').forEach(row => {
      row.find(Text).forEach(rowContent => {
        textContent.push(rowContent.props().children)
      })
    })
    const tableText = textContent.join(' ')
    const {user} = props

    expect(tableText).toContain(user.name)
    expect(tableText).toContain(user.short_name)
    expect(tableText).toContain(user.sortable_name)
    expect(tableText).toContain(user.email)
    user.pseudonyms.forEach((pseudonym) => {
      expect(tableText).toContain(pseudonym.login_id)
      expect(tableText).toContain(pseudonym.sis_id)
      expect(tableText).toContain(pseudonym.integration_id)
    })
  })

  test('it should only display loading spinner if state is loading', done => {
    const wrapper = shallow(<ActAsModal {...props} />)
    expect(wrapper.find(Spinner).exists()).toBeFalsy()

    wrapper.setState({isLoading: true}, () => {
      expect(wrapper.find(Spinner).exists()).toBeTruthy()
      done()
    })
  })
})
