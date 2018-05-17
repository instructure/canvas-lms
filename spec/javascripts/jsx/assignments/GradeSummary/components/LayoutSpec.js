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
import {Provider} from 'react-redux'

import Layout from 'jsx/assignments/GradeSummary/components/Layout'
import configureStore from 'jsx/assignments/GradeSummary/configureStore'

QUnit.module('GradeSummary Layout', suiteHooks => {
  let storeEnv
  let store
  let wrapper

  suiteHooks.beforeEach(() => {
    storeEnv = {
      assignment: {
        courseId: '1201',
        id: '2301',
        title: 'Example Assignment'
      },
      graders: [{graderId: '1101'}, {graderId: '1102'}]
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent() {
    store = configureStore(storeEnv)
    wrapper = mount(
      <Provider store={store}>
        <Layout />
      </Provider>
    )
  }

  test('includes the Header', () => {
    mountComponent()
    strictEqual(wrapper.find('Header').length, 1)
  })

  test('includes a "no graders" message when there are no graders', () => {
    storeEnv.graders = []
    mountComponent()
    ok(wrapper.text().includes('Moderation is unable to occur'))
  })

  test('excludes the "no graders" message when there are graders', () => {
    mountComponent()
    notOk(wrapper.text().includes('Moderation is unable to occur'))
  })
})
