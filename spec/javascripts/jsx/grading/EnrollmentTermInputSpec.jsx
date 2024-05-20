/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'
import {findRenderedDOMComponentWithClass} from 'react-dom/test-utils'
import {defaults, map} from 'lodash'
import Input from 'ui/features/account_grading_standards/react/EnrollmentTermInput'

const wrapper = document.getElementById('fixtures')

QUnit.module('EnrollmentTermInput', {
  renderComponent(props = {}) {
    const defaultProps = {
      enrollmentTerms: [
        {
          id: '1',
          name: 'Fall 2009 - Art',
          startAt: new Date('2009-06-03T02:57:42.000Z'),
          endAt: new Date('2009-12-03T02:57:53.000Z'),
          createdAt: new Date('2009-05-27T16:51:41.000Z'),
          workflowState: 'active',
          gradingPeriodGroupId: '65',
          sisTermId: null,
          displayName: 'Fall 2009 - Art',
        },
        {
          id: '2',
          name: null,
          startAt: null,
          endAt: new Date('2013-12-03T02:57:53.000Z'),
          createdAt: new Date('2015-10-27T16:51:41.000Z'),
          workflowState: 'active',
          gradingPeriodGroupId: '62',
          sisTermId: null,
          displayName: 'Term created Oct 27, 2015',
        },
        {
          id: '5',
          name: null,
          startAt: new Date('2012-06-06T20:09:32.000Z'),
          endAt: null,
          createdAt: new Date('2012-06-03T20:09:32.000Z'),
          workflowState: 'active',
          gradingPeriodGroupId: '64',
          sisTermId: null,
          displayName: 'Term starting Jun 6, 2016',
        },
      ],
      selectedIDs: ['2'],
      setSelectedEnrollmentTermIDs() {},
    }

    const element = React.createElement(Input, defaults(props, defaultProps))
    return ReactDOM.render(element, wrapper)
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test("displays 'No unassigned terms' if there are no selectable terms", function () {
  const enrollmentTermInput = this.renderComponent({enrollmentTerms: [], selectedIDs: []})
  const header = findRenderedDOMComponentWithClass(enrollmentTermInput, 'ic-tokeninput-header')
  const title = ReactDOM.findDOMNode(header).textContent
  equal(title, 'No unassigned terms')
})

test('selectedEnrollmentTerms uses the enrollment term display name', function () {
  const enrollmentTermInput = this.renderComponent()
  const termNames = map(enrollmentTermInput.selectedEnrollmentTerms(), 'name')
  propEqual(termNames, ['Term created Oct 27, 2015'])
})

test('selectableOptions uses the enrollment term display name', function () {
  const enrollmentTermInput = this.renderComponent()
  const options = enrollmentTermInput.selectableOptions('active')
  const termNames = map(options, option => option.props.children)
  propEqual(termNames, ['Term starting Jun 6, 2016'])
})
