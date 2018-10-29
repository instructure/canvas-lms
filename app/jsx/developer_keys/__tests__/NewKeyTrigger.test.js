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
import DeveloperKeyModalTrigger from '../NewKeyTrigger'

const store = {
  dispatch: () => {}
}

const actions = {
  developerKeysModalOpen: jest.fn(),
  ltiKeysSetLtiKey: jest.fn()
}

let wrapper = 'empty wrapper'

const menuContentsNode = () => wrapper.find('Portal').instance().DOMNode

beforeEach(() => {
  window.ENV = {
    LTI_1_3_ENABLED: true
  }

  wrapper = mount(
    <DeveloperKeyModalTrigger store={store} actions={actions} setAddKeyButtonRef={() => {}} />
  )

  wrapper
    .find('Menu')
    .first()
    .find('Button')
    .first()
    .simulate('click')
})

afterEach(() => {
  window.ENV = {}
  wrapper.unmount()
})

it('it opens the API key modal when API key button is clicked', () => {
  menuContentsNode()
    .querySelector('li button')
    .click()
  expect(actions.developerKeysModalOpen).toBeCalled()
})

it('it opens the LTI key modal when LTI key button is clicked', () => {
  menuContentsNode()
    .querySelectorAll('li button')[1]
    .click()
  expect(actions.ltiKeysSetLtiKey).toBeCalled()
  expect(actions.developerKeysModalOpen).toBeCalled()
})
