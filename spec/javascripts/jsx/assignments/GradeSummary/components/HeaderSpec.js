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
        id: '2301',
        title: 'Example Assignment'
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

  test('includes the assignment title as a heading', () => {
    mountComponent()
    equal(wrapper.find('h2').text(), 'Example Assignment')
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

    function postButton() {
      return wrapper.find('button').filterWhere(button => button.text() === 'Post')
    }

    test('displays a confirmation dialog when clicked', () => {
      mountComponent()
      postButton().simulate('click')
      strictEqual(window.confirm.callCount, 1)
    })

    test('publishes grades when dialog is confirmed', () => {
      mountComponent()
      postButton().simulate('click')
      equal(store.getState().assignment.publishGradesStatus, AssignmentActions.STARTED)
    })

    test('does not publish grades when dialog is dismissed', () => {
      window.confirm.returns(false)
      mountComponent()
      postButton().simulate('click')
      strictEqual(store.getState().assignment.publishGradesStatus, null)
    })

    test('is disabled when grades are being published', () => {
      mountComponent()
      store.dispatch(AssignmentActions.setPublishGradesStatus(AssignmentActions.STARTED))
      strictEqual(postButton().prop('disabled'), true)
    })

    test('performs no action upon click when grades are being published', () => {
      mountComponent()
      store.dispatch(AssignmentActions.setPublishGradesStatus(AssignmentActions.STARTED))
      postButton().simulate('click')
      strictEqual(window.confirm.callCount, 0)
    })

    test('is disabled when grades were already published', () => {
      storeEnv.assignment.gradesPublished = true
      mountComponent()
      strictEqual(postButton().prop('disabled'), true)
    })

    test('performs no action upon click when grades were already published', () => {
      storeEnv.assignment.gradesPublished = true
      mountComponent()
      postButton().simulate('click')
      strictEqual(window.confirm.callCount, 0)
    })

    test('is enabled when grade publishing failed', () => {
      mountComponent()
      store.dispatch(AssignmentActions.setPublishGradesStatus(AssignmentActions.STARTED))
      store.dispatch(AssignmentActions.setPublishGradesStatus(AssignmentActions.FAILURE))
      notEqual(postButton().prop('disabled'), true)
    })
  })
})
