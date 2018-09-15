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
import {mount} from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme'
import {Provider} from 'react-redux'

import * as AssignmentActions from 'jsx/assignments/GradeSummary/assignment/AssignmentActions'
import Header from 'jsx/assignments/GradeSummary/components/Header'
import configureStore from 'jsx/assignments/GradeSummary/configureStore'

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

  test('includes a "grades posted" message when grades have been published', () => {
    storeEnv.assignment.gradesPublished = true
    mountComponent()
    ok(wrapper.text().includes('they have already been posted'))
  })

  test('excludes the "grades posted" message when grades have not yet been published', () => {
    mountComponent()
    notOk(wrapper.text().includes('they have already been posted'))
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

  QUnit.module('"Post" button', hooks => {
    hooks.beforeEach(() => {
      sinon.stub(window, 'confirm').returns(true)
      sinon
        .stub(AssignmentActions, 'publishGrades')
        .returns(AssignmentActions.setPublishGradesStatus(AssignmentActions.STARTED))
    })

    hooks.afterEach(() => {
      AssignmentActions.publishGrades.restore()
      window.confirm.restore()
    })

    test('is not displayed when there are no graders', () => {
      storeEnv.graders = []
      mountComponent()
      strictEqual(wrapper.find('PostButton').length, 0)
    })

    test('is displayed when there are graders', () => {
      mountComponent()
      strictEqual(wrapper.find('PostButton').length, 1)
    })

    test('receives the assignment gradesPublished property as a prop', () => {
      mountComponent()
      strictEqual(wrapper.find('PostButton').prop('gradesPublished'), false)
    })

    test('receives the unmuteAssignmentStatus as a prop', () => {
      mountComponent()
      store.dispatch(AssignmentActions.setPublishGradesStatus(AssignmentActions.STARTED))
      const button = wrapper.find('PostButton')
      equal(button.prop('publishGradesStatus'), AssignmentActions.STARTED)
    })

    test('displays a confirmation dialog when clicked', () => {
      mountComponent()
      wrapper.find('PostButton').simulate('click')
      strictEqual(window.confirm.callCount, 1)
    })

    test('publishes grades when dialog is confirmed', () => {
      mountComponent()
      wrapper.find('PostButton').simulate('click')
      equal(store.getState().assignment.publishGradesStatus, AssignmentActions.STARTED)
    })

    test('does not publish grades when dialog is dismissed', () => {
      window.confirm.returns(false)
      mountComponent()
      wrapper.find('PostButton').simulate('click')
      strictEqual(store.getState().assignment.publishGradesStatus, null)
    })
  })

  QUnit.module('"Display to Students" button', hooks => {
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

    test('is not displayed when there are no graders', () => {
      storeEnv.graders = []
      mountComponent()
      strictEqual(wrapper.find('DisplayToStudentsButton').length, 0)
    })

    test('is displayed when there are graders', () => {
      mountComponent()
      strictEqual(wrapper.find('DisplayToStudentsButton').length, 1)
    })

    test('receives the assignment as a prop', () => {
      mountComponent()
      const button = wrapper.find('DisplayToStudentsButton')
      deepEqual(button.prop('assignment'), storeEnv.assignment)
    })

    test('receives the unmuteAssignmentStatus as a prop', () => {
      mountComponent()
      store.dispatch(AssignmentActions.setUnmuteAssignmentStatus(AssignmentActions.STARTED))
      const button = wrapper.find('DisplayToStudentsButton')
      equal(button.prop('unmuteAssignmentStatus'), AssignmentActions.STARTED)
    })

    test('displays a confirmation dialog when clicked', () => {
      mountComponent()
      wrapper.find('DisplayToStudentsButton').simulate('click')
      strictEqual(window.confirm.callCount, 1)
    })

    test('unmutes the assignment when dialog is confirmed', () => {
      mountComponent()
      wrapper.find('DisplayToStudentsButton').simulate('click')
      equal(store.getState().assignment.unmuteAssignmentStatus, AssignmentActions.STARTED)
    })

    test('does not unmute the assignment when dialog is dismissed', () => {
      window.confirm.returns(false)
      mountComponent()
      wrapper.find('DisplayToStudentsButton').simulate('click')
      strictEqual(store.getState().assignment.unmuteAssignmentStatus, null)
    })
  })
})
