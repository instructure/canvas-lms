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

import * as AssignmentActions from 'ui/features/assignment_grade_summary/react/assignment/AssignmentActions.js'
import Header from 'ui/features/assignment_grade_summary/react/components/Header.js'
import configureStore from 'ui/features/assignment_grade_summary/react/configureStore.js'

QUnit.module('GradeSummary Header', suiteHooks => {
  let store
  let storeEnv
  let wrapper

  suiteHooks.beforeEach(() => {
    storeEnv = {
      assignment: {
        courseId: '1201',
        gradesPublished: false,
        id: '2301',
        muted: true,
        title: 'Example Assignment'
      },
      currentUser: {
        graderId: 'teach',
        id: '1105'
      },
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'}
      ]
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent() {
    store = configureStore(storeEnv)
    wrapper = mount(
      <Provider store={store}>
        <Header />
      </Provider>
    )
  }

  test('includes the "Grade Summary" heading', () => {
    mountComponent()
    equal(wrapper.find('h1').text(), 'Grade Summary')
  })

  test('includes the assignment title', () => {
    mountComponent()
    const children = wrapper.find('header').children()
    const childArray = children.map(child => child)
    const headingIndex = childArray.findIndex(child => child.text() === 'Grade Summary')
    equal(childArray[headingIndex + 1].text(), 'Example Assignment')
  })

  test('includes a "grades released" message when grades have been released', () => {
    storeEnv.assignment.gradesPublished = true
    mountComponent()
    ok(wrapper.text().includes('they have already been released'))
  })

  test('excludes the "grades released" message when grades have not yet been released', () => {
    mountComponent()
    notOk(wrapper.text().includes('they have already been released'))
  })

  QUnit.module('Graders Table', () => {
    test('is not displayed when there are no graders', () => {
      storeEnv.graders = []
      mountComponent()
      strictEqual(wrapper.find('GradersTable').length, 0)
    })

    test('is displayed when there are graders', () => {
      mountComponent()
      strictEqual(wrapper.find('GradersTable').length, 1)
    })
  })

  QUnit.module('"Release Grades" button', hooks => {
    hooks.beforeEach(() => {
      sinon.stub(window, 'confirm').returns(true)
      sinon
        .stub(AssignmentActions, 'releaseGrades')
        .returns(AssignmentActions.setReleaseGradesStatus(AssignmentActions.STARTED))
    })

    hooks.afterEach(() => {
      AssignmentActions.releaseGrades.restore()
      window.confirm.restore()
    })

    test('is always displayed', () => {
      storeEnv.graders = []
      mountComponent()
      strictEqual(wrapper.find('ReleaseButton').length, 1)
    })

    test('receives the assignment gradesPublished property as a prop', () => {
      mountComponent()
      strictEqual(wrapper.find('ReleaseButton').prop('gradesReleased'), false)
    })

    test('receives the unmuteAssignmentStatus as a prop', () => {
      mountComponent()
      store.dispatch(AssignmentActions.setReleaseGradesStatus(AssignmentActions.STARTED))
      wrapper.update()
      const button = wrapper.find('ReleaseButton')
      equal(button.prop('releaseGradesStatus'), AssignmentActions.STARTED)
    })

    test('displays a confirmation dialog when clicked', () => {
      mountComponent()
      wrapper.find('ReleaseButton').simulate('click')
      strictEqual(window.confirm.callCount, 1)
    })

    test('releases grades when dialog is confirmed', () => {
      mountComponent()
      wrapper.find('ReleaseButton').simulate('click')
      equal(store.getState().assignment.releaseGradesStatus, AssignmentActions.STARTED)
    })

    test('does not release grades when dialog is dismissed', () => {
      window.confirm.returns(false)
      mountComponent()
      wrapper.find('ReleaseButton').simulate('click')
      strictEqual(store.getState().assignment.releaseGradesStatus, null)
    })
  })

  QUnit.module('"Post to Students" button', hooks => {
    hooks.beforeEach(() => {
      storeEnv.assignment.gradesPublished = true
      sinon.stub(window, 'confirm').returns(true)
      sinon
        .stub(AssignmentActions, 'unmuteAssignment')
        .returns(AssignmentActions.setUnmuteAssignmentStatus(AssignmentActions.STARTED))
    })

    hooks.afterEach(() => {
      AssignmentActions.unmuteAssignment.restore()
      window.confirm.restore()
    })

    test('is always displayed', () => {
      storeEnv.graders = []
      mountComponent()
      strictEqual(wrapper.find('PostToStudentsButton').length, 1)
    })

    test('receives the assignment as a prop', () => {
      mountComponent()
      const button = wrapper.find('PostToStudentsButton')
      deepEqual(button.prop('assignment'), storeEnv.assignment)
    })

    test('receives the unmuteAssignmentStatus as a prop', () => {
      mountComponent()
      store.dispatch(AssignmentActions.setUnmuteAssignmentStatus(AssignmentActions.STARTED))
      wrapper.update()
      const button = wrapper.find('PostToStudentsButton')
      equal(button.prop('unmuteAssignmentStatus'), AssignmentActions.STARTED)
    })

    test('displays a confirmation dialog when clicked', () => {
      mountComponent()
      wrapper.find('PostToStudentsButton').simulate('click')
      strictEqual(window.confirm.callCount, 1)
    })

    test('unmutes the assignment when dialog is confirmed', () => {
      mountComponent()
      wrapper.find('PostToStudentsButton').simulate('click')
      equal(store.getState().assignment.unmuteAssignmentStatus, AssignmentActions.STARTED)
    })

    test('does not unmute the assignment when dialog is dismissed', () => {
      window.confirm.returns(false)
      mountComponent()
      wrapper.find('PostToStudentsButton').simulate('click')
      strictEqual(store.getState().assignment.unmuteAssignmentStatus, null)
    })
  })
})
