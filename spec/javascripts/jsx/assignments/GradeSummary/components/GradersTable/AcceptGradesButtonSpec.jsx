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

import AcceptGradesButton from 'ui/features/assignment_grade_summary/react/components/GradersTable/AcceptGradesButton'
import {
  FAILURE,
  STARTED,
  SUCCESS,
} from 'ui/features/assignment_grade_summary/react/grades/GradeActions'

QUnit.module('GradeSummary AcceptGradesButton', suiteHooks => {
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    props = {
      acceptGradesStatus: null,
      graderName: 'Jackie Chan',
      onClick: sinon.stub(),
      selectionDetails: {
        allowed: true,
        provisionalGradeIds: ['4601'],
      },
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent() {
    wrapper = mount(<AcceptGradesButton {...props} />)
  }

  QUnit.module('when grades have not been accepted', contextHooks => {
    contextHooks.beforeEach(mountComponent)

    test('is labeled with "Accept"', () => {
      equal(wrapper.find('button PresentationContent').text(), 'Accept')
    })

    test('is labeled for screen readers with "Accept grades by"', () => {
      equal(
        wrapper.find('button ScreenReaderContent').first().text(),
        'Accept grades by Jackie Chan'
      )
    })

    test('is not read-only', () => {
      strictEqual(wrapper.find('button').prop('aria-readonly'), null)
    })

    test('is not disabled', () => {
      strictEqual(wrapper.find('Button').first().prop('disabled'), null)
    })

    test('calls the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 1)
    })
  })

  QUnit.module('when grades are being accepted', contextHooks => {
    contextHooks.beforeEach(() => {
      props.acceptGradesStatus = STARTED
      mountComponent()
    })

    test('is labeled with "Accepting"', () => {
      // The Spinner in the button duplicates the label. Assert that the label
      // includes the expected text, but is not exactly equal.
      const label = wrapper.find('button').text()
      ok(label.match(/Accepting/))
    })

    test('is read-only', () => {
      strictEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('is not disabled', () => {
      strictEqual(wrapper.find('Button').first().prop('disabled'), null)
    })

    test('does not call the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 0)
    })
  })

  QUnit.module('when grades have been accepted', contextHooks => {
    contextHooks.beforeEach(() => {
      props.acceptGradesStatus = SUCCESS
      props.selectionDetails.provisionalGradeIds = []
      mountComponent()
    })

    test('is labeled with "Accepted"', () => {
      equal(wrapper.find('button').text(), 'Accepted')
    })

    test('is read-only', () => {
      strictEqual(wrapper.find('button').prop('aria-readonly'), true)
    })

    test('is not disabled', () => {
      strictEqual(wrapper.find('Button').first().prop('disabled'), null)
    })

    test('does not call the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 0)
    })
  })

  QUnit.module('when grades were previously accepted', contextHooks => {
    contextHooks.beforeEach(() => {
      props.acceptGradesStatus = null
      props.selectionDetails.provisionalGradeIds = []
      mountComponent()
    })

    test('is labeled with "Accepted"', () => {
      equal(wrapper.find('button').text(), 'Accepted')
    })

    test('is not read-only', () => {
      strictEqual(wrapper.find('button').prop('aria-readonly'), null)
    })

    test('is disabled', () => {
      strictEqual(wrapper.find('Button').first().prop('disabled'), true)
    })

    test('does not call the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 0)
    })
  })

  QUnit.module('when grades failed to be accepted', contextHooks => {
    contextHooks.beforeEach(() => {
      props.acceptGradesStatus = FAILURE
      mountComponent()
    })

    test('is labeled with "Accept"', () => {
      equal(wrapper.find('button PresentationContent').text(), 'Accept')
    })

    test('is labeled for screen readers with "Accept grades by"', () => {
      equal(
        wrapper.find('button ScreenReaderContent').first().text(),
        'Accept grades by Jackie Chan'
      )
    })

    test('is not read-only', () => {
      strictEqual(wrapper.find('button').prop('aria-readonly'), null)
    })

    test('is not disabled', () => {
      equal(wrapper.find('Button').first().prop('disabled'), null)
    })

    test('calls the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 1)
    })
  })

  QUnit.module('when grades cannot be bulk selected for the grader', contextHooks => {
    contextHooks.beforeEach(() => {
      props.selectionDetails = {
        allowed: false,
        provisionalGradeIds: [],
      }
      mountComponent()
    })

    test('is labeled with "Accept"', () => {
      equal(wrapper.find('button PresentationContent').text(), 'Accept')
    })

    test('is labeled for screen readers with "Accept grades by"', () => {
      equal(
        wrapper.find('button ScreenReaderContent').first().text(),
        'Accept grades by Jackie Chan'
      )
    })

    test('is not read-only', () => {
      strictEqual(wrapper.find('button').prop('aria-readonly'), null)
    })

    test('is disabled', () => {
      strictEqual(wrapper.find('Button').first().prop('disabled'), true)
    })

    test('does not call the onClick prop when clicked', () => {
      wrapper.find('button').simulate('click')
      strictEqual(props.onClick.callCount, 0)
    })
  })
})
