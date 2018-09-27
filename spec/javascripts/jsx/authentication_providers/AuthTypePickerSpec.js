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
import AuthTypePicker from 'jsx/authentication_providers/AuthTypePicker'
import {mount} from 'enzyme'

const authTypes = [{name: 'TypeOne', value: '1'}, {name: 'TypeTwo', value: '2'}]

QUnit.module('AuthTypePicker')

test('rendered structure', () => {
  const wrapper = mount(<AuthTypePicker authTypes={authTypes} />)
  equal(wrapper.find('option').length, 2)
})

test('choosing an auth type fires the provided callback', () => {
  const spy = sinon.spy()
  const wrapper = mount(<AuthTypePicker authTypes={authTypes} onChange={spy} />)
  wrapper.find('select').simulate('change')
  ok(spy.called)
})
