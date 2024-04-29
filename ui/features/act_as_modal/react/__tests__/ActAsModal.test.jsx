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
import ActAsModal from '../ActAsModal'
import ActAsMask from '../svg/ActAsMask'
import ActAsPanda from '../svg/ActAsPanda'
import {Button} from '@instructure/ui-buttons'
import {render} from '@testing-library/react'

const props = {
  user: {
    name: 'test user',
    short_name: 'foo',
    id: '5',
    avatar_image_url: 'testImageUrl',
    sortable_name: 'bar, baz',
    email: 'testUser@test.com',
    pseudonyms: [
      {
        login_id: 'qux',
        sis_id: 555,
        integration_id: 222,
      },
      {
        login_id: 'tic',
        sis_id: 777,
        integration_id: 888,
      },
    ],
  },
}
describe('ActAsModal', () => {
  it('renders with panda svgs, user avatar, table, and proceed button present', () => {
    const wrapper = shallow(<ActAsModal {...props} />)
    expect(wrapper).toMatchSnapshot()

    const mask = wrapper.find(ActAsMask)
    const panda = wrapper.find(ActAsPanda)
    const button = wrapper.find(Button)

    expect(mask.exists()).toBeTruthy()
    expect(panda.exists()).toBeTruthy()
    expect(button.exists()).toBeTruthy()
  })

  it('renders avatar with user image url', async () => {
    const wrapper = render(<ActAsModal {...props} />)
    expect(
      wrapper.getByLabelText('Act as User').querySelector("span[data-fs-exclude='true'] img").src
    ).toContain('testImageUrl')
  })

  test('it renders the table with correct user information', () => {
    const wrapper = render(<ActAsModal {...props} />)
    const tables = wrapper.getByLabelText('Act as User').querySelectorAll('table')

    expect(tables).toHaveLength(3)

    const {user} = props
    expect(wrapper.getByText(user.name)).toBeInTheDocument()
    expect(wrapper.getByText(user.short_name)).toBeInTheDocument()
    expect(wrapper.getByText(user.sortable_name)).toBeInTheDocument()
    expect(wrapper.getByText(user.email)).toBeInTheDocument()
    user.pseudonyms.forEach(pseudonym => {
      expect(wrapper.getByText(pseudonym.login_id)).toBeInTheDocument()
      expect(wrapper.getByText('' + pseudonym.sis_id)).toBeInTheDocument()
      expect(wrapper.getByText('' + pseudonym.integration_id)).toBeInTheDocument()
    })
  })

  test('it should only display loading spinner if state is loading', async () => {
    const ref = React.createRef()
    const wrapper = render(<ActAsModal {...props} ref={ref} />)
    expect(wrapper.queryByText('Loading')).not.toBeInTheDocument()
    ref.current.setState({isLoading: true})
    expect(wrapper.getByText('Loading')).toBeInTheDocument()
  })
})
