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

import {
  FAILURE,
  NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE,
  STARTED
} from 'jsx/assignments/GradeSummary/assignment/AssignmentActions'
import PostButton from 'jsx/assignments/GradeSummary/components/PostButton'

QUnit.module('GradeSummary PostButton', suiteHooks => {
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    props = {
      gradesPublished: false,
      onClick: sinon.spy(),
      publishGradesStatus: null
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent() {
    wrapper = mount(<PostButton {...props} />)
  }

  QUnit.module('when grades have not been published', contextHooks => {
    contextHooks.beforeEach(mountComponent)

    test('is labeled with "Post"', () => {
      equal(wrapper.find('button').text(), 'Post')
    })

    test('is not read-only', () => {
      notEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('calls the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 1)
    })
  })

  QUnit.module('when grades are being published', contextHooks => {
    contextHooks.beforeEach(() => {
      props.publishGradesStatus = STARTED
      mountComponent()
    })

    test('is labeled with "Posting Grades"', () => {
      // The Spinner in the button duplicates the label. Assert that the label
      // includes the expected text, but is not exactly equal.
      const label = wrapper.find('button').text()
      ok(label.match(/Posting Grades/))
    })

    test('is read-only', () => {
      strictEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('does not call the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 0)
    })
  })

  QUnit.module('when grades have been published', contextHooks => {
    contextHooks.beforeEach(() => {
      props.gradesPublished = true
      mountComponent()
    })

    test('is labeled with "Grades Posted"', () => {
      // The Icon in the button duplicates the label. Assert that the label
      // includes the expected text, but is not exactly equal.
      const label = wrapper.find('button').text()
      ok(label.match(/Grades Posted/))
    })

    test('is read-only', () => {
      strictEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('does not call the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 0)
    })
  })

  QUnit.module('when grade publishing failed', contextHooks => {
    contextHooks.beforeEach(() => {
      props.publishGradesStatus = FAILURE
      mountComponent()
    })

    test('is labeled with "Post"', () => {
      equal(wrapper.find('button').text(), 'Post')
    })

    test('is not read-only', () => {
      notEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('calls the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 1)
    })
  })

  QUnit.module('when grade publishing failed for missing grade selections', contextHooks => {
    contextHooks.beforeEach(() => {
      props.publishGradesStatus = NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE
      mountComponent()
    })

    test('is labeled with "Post"', () => {
      equal(wrapper.find('button').text(), 'Post')
    })

    test('is not read-only', () => {
      notEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('calls the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 1)
    })
  })
})
