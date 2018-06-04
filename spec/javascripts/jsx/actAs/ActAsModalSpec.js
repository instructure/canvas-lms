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
import ActAsModal from 'jsx/actAs/ActAsModal'
import ActAsMask from 'jsx/actAs/ActAsMask'
import ActAsPanda from 'jsx/actAs/ActAsPanda'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Avatar from '@instructure/ui-elements/lib/components/Avatar'
import Table from '@instructure/ui-elements/lib/components/Table'
import Text from '@instructure/ui-elements/lib/components/Text'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'

QUnit.module('ActAsModal', {
  setup () {
    this.props = {
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
  }
})

test('it renders with panda svgs, user avatar, table, and proceed button present', function () {
  const wrapper = shallow(<ActAsModal {...this.props} />)
  const mask = wrapper.find(ActAsMask)
  const panda = wrapper.find(ActAsPanda)
  const button = wrapper.find(Button)

  ok(mask.exists())
  ok(panda.exists())
  ok(button.exists())
})

test('it renders avatar with user image url', function () {
  const wrapper = shallow(<ActAsModal {...this.props} />)
  const avatar = wrapper.find(Avatar)

  ok(avatar.exists())
  equal(avatar.props().src, 'testImageUrl')
})

test('it renders the table with correct user information', function () {
  const wrapper = shallow(<ActAsModal {...this.props} />)
  const tables = wrapper.find(Table)

  ok(tables.length === 3)

  const textContent = []
  tables.find('tr').forEach((row) => {
    row.find(Text).forEach((rowContent) => {
      textContent.push(rowContent.props().children)
    })
  })
  const tableText = textContent.join(' ')
  const user = this.props.user

  ok(tableText.indexOf(user.name) > -1)
  ok(tableText.indexOf(user.short_name) > -1)
  ok(tableText.indexOf(user.sortable_name) > -1)
  ok(tableText.indexOf(user.email) > -1)
  user.pseudonyms.forEach((pseudonym) => {
    ok(tableText.indexOf(pseudonym.login_id) > -1)
    ok(tableText.indexOf(pseudonym.sis_id) > -1)
    ok(tableText.indexOf(pseudonym.integration_id) > -1)
  })
})

test('it should only display loading spinner if state is loading', function (assert) {
  const done = assert.async()
  const wrapper = shallow(<ActAsModal {...this.props} />)
  notOk(wrapper.find(Spinner).exists())

  wrapper.setState({isLoading: true}, () => {
    ok(wrapper.find(Spinner).exists())
    done()
  })
})
