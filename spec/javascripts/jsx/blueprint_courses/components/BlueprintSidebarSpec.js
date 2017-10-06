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
import * as enzyme from 'enzyme'
import BlueprintSidebar from 'jsx/blueprint_courses/components/BlueprintSidebar'

QUnit.module('BlueprintSidebar', function (hooks) {
  let clock
  let wrapper

  hooks.beforeEach(() => {
    clock = sinon.useFakeTimers()
    const appElement = document.createElement('div')
    appElement.id = 'application'
    document.getElementById('fixtures').appendChild(appElement)
  })

  hooks.afterEach(() => {
    wrapper.unmount()
    document.getElementById('fixtures').innerHTML = ''
    clock.restore()
  })

  test('renders the BlueprintSidebar component', () => {
    wrapper = enzyme.shallow(<BlueprintSidebar />)
    ok(wrapper.find('.bcs__wrapper').exists())
  })

  test('clicking open button sets isOpen to true', () => {
    wrapper = enzyme.mount(<BlueprintSidebar />)
    wrapper.find('.bcs__trigger button').at(0).simulate('click')
    clock.tick(500)
    strictEqual(wrapper.instance().state.isOpen, true)
  })

  test('clicking close button sets isOpen to false', () => {
    wrapper = enzyme.mount(<BlueprintSidebar />)
    wrapper.instance().open()
    clock.tick(500)
    wrapper.instance().closeBtn.click()
    clock.tick(500)
    strictEqual(wrapper.instance().state.isOpen, false)
  })
})
