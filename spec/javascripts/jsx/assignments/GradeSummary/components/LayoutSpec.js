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

import * as StudentActions from 'jsx/assignments/GradeSummary/students/StudentActions'
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
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'}
      ]
    }
    sinon
      .stub(StudentActions, 'loadStudents')
      .returns(StudentActions.setLoadStudentsStatus(StudentActions.STARTED))
  })

  suiteHooks.afterEach(() => {
    StudentActions.loadStudents.restore()
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

  test('loads students upon mounting', () => {
    mountComponent()
    strictEqual(StudentActions.loadStudents.callCount, 1)
  })

  test('does not load students when there are not graders', () => {
    storeEnv.graders = []
    mountComponent()
    strictEqual(StudentActions.loadStudents.callCount, 0)
  })

  QUnit.module('when students have not yet loaded', () => {
    test('displays a spinner', () => {
      mountComponent()
      strictEqual(wrapper.find('Spinner').length, 1)
    })
  })

  QUnit.module('when some students have loaded', hooks => {
    let students

    hooks.beforeEach(() => {
      students = [{id: '1111', displayName: 'Adam Jones'}, {id: '1112', displayName: 'Betty Ford'}]
    })

    test('renders the GradesGrid', () => {
      mountComponent()
      store.dispatch(StudentActions.addStudents(students))
      strictEqual(wrapper.find('GradesGrid').length, 1)
    })

    test('does not display a spinner', () => {
      mountComponent()
      store.dispatch(StudentActions.addStudents(students))
      strictEqual(wrapper.find('Spinner').length, 0)
    })
  })
})
