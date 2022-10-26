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
import axios from '@canvas/axios'
import moxios from 'moxios'
import ConfirmEndTutorialDialog from 'ui/features/new_user_tutorial/react/ConfirmEndTutorialDialog'

QUnit.module('ConfirmEndTutorialDialog Spec', {
  setup() {
    moxios.install()
  },
  teardown() {
    moxios.uninstall()
  },
})

const defaultProps = {
  isOpen: true,
  handleRequestClose() {},
}

test('handleOkayButtonClick calls the proper api endpoint and data', () => {
  const spy = sinon.spy(axios, 'put')
  const wrapper = shallow(<ConfirmEndTutorialDialog {...defaultProps} />)
  wrapper.find('Button[color="primary"]').simulate('click')
  ok(spy.calledWith('/api/v1/users/self/features/flags/new_user_tutorial_on_off', {state: 'off'}))
  spy.restore()
})

test('handleOkayButtonClick calls onSuccessFunc after calling the api', assert => {
  const done = assert.async()
  const spy = sinon.stub(ConfirmEndTutorialDialog, 'onSuccess')

  const wrapper = shallow(<ConfirmEndTutorialDialog {...defaultProps} />)
  wrapper.find('Button[color="primary"]').simulate('click')
  moxios.wait(() => {
    const request = moxios.requests.mostRecent()
    request.respondWith({status: 200}).then(() => {
      ok(spy.called)
      spy.restore()
      done()
    })
  })
})
