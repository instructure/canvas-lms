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
  SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS,
  STARTED,
} from 'ui/features/assignment_grade_summary/react/assignment/AssignmentActions'
import ReleaseButton from 'ui/features/assignment_grade_summary/react/components/ReleaseButton'

QUnit.module('GradeSummary ReleaseButton', suiteHooks => {
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    props = {
      gradesReleased: false,
      onClick: sinon.spy(),
      releaseGradesStatus: null,
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent() {
    wrapper = mount(<ReleaseButton {...props} />)
  }

  QUnit.module('when grades have not been released', contextHooks => {
    contextHooks.beforeEach(mountComponent)

    test('is labeled with "Release Grades"', () => {
      equal(wrapper.find('button').text(), 'Release Grades')
    })

    test('is not read-only', () => {
      notEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('calls the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 1)
    })
  })

  QUnit.module('when grades are being released', contextHooks => {
    contextHooks.beforeEach(() => {
      props.releaseGradesStatus = STARTED
      mountComponent()
    })

    test('is labeled with "Releasing Grades"', () => {
      // The Spinner in the button duplicates the label. Assert that the label
      // includes the expected text, but is not exactly equal.
      const label = wrapper.find('button').text()
      ok(label.match(/Releasing Grades/))
    })

    test('is read-only', () => {
      strictEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('does not call the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 0)
    })
  })

  QUnit.module('when grades have been released', contextHooks => {
    contextHooks.beforeEach(() => {
      props.gradesReleased = true
      mountComponent()
    })

    test('is labeled with "Grades Released"', () => {
      // The Icon in the button duplicates the label. Assert that the label
      // includes the expected text, but is not exactly equal.
      const label = wrapper.find('button').text()
      ok(label.match(/Grades Released/))
    })

    test('is read-only', () => {
      strictEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('does not call the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 0)
    })
  })

  QUnit.module('when grade releasing failed', contextHooks => {
    contextHooks.beforeEach(() => {
      props.releaseGradesStatus = FAILURE
      mountComponent()
    })

    test('is labeled with "Release Grades"', () => {
      equal(wrapper.find('button').text(), 'Release Grades')
    })

    test('is not read-only', () => {
      notEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('calls the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 1)
    })
  })

  QUnit.module('when grade releasing failed for missing grade selections', contextHooks => {
    contextHooks.beforeEach(() => {
      props.releaseGradesStatus = NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE
      mountComponent()
    })

    test('is labeled with "Release Grades"', () => {
      equal(wrapper.find('button').text(), 'Release Grades')
    })

    test('is not read-only', () => {
      notEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('calls the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 1)
    })
  })

  QUnit.module('when there are graders with inactive enrollment', () => {
    test('enables onClick when releaseGradesStatus is null', () => {
      props.releaseGradesStatus = null
      mountComponent()
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 1)
    })

    test('disables onClick when releaseGradesStatus is SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS', () => {
      props.releaseGradesStatus = SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS
      mountComponent()
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 0)
    })
  })
})
