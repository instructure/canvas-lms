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

import Header from 'jsx/assignments/GradeSummary/components/Header'

QUnit.module('GradeSummary Header', suiteHooks => {
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    props = {
      assignment: {
        title: 'Example Assignment'
      }
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent() {
    wrapper = mount(<Header {...props} />)
  }

  test('includes the assignment title as a heading', () => {
    mountComponent()
    equal(wrapper.find('h2').text(), 'Example Assignment')
  })
})
