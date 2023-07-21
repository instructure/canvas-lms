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
import BreakdownDetails from '@canvas/conditional-release-stats/react/components/breakdown-details'

let clock
let container

QUnit.module('Breakdown Details', {
  setup() {
    const applicationElement = document.createElement('div')
    applicationElement.id = 'application'
    document.getElementById('fixtures').appendChild(applicationElement)
    container = document.createElement('div')
    document.getElementById('fixtures').appendChild(container)

    clock = sinon.useFakeTimers()
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(container)
    document.getElementById('fixtures').innerHTML = ''
    clock.restore()
  },
})

// using ReactDOM instead of TestUtils to render because of InstUI
const renderComponent = props => ReactDOM.render(<BreakdownDetails {...props} />, container)

const defaultProps = () => ({
  ranges: [
    {
      scoring_range: {
        id: 1,
        rule_id: 1,
        lower_bound: 0.7,
        upper_bound: 1.0,
        created_at: null,
        updated_at: null,
        position: null,
      },
      size: 2,
      students: [
        {
          user: {
            id: 1,
            name: 'foo',
            login_id: 'student1',
          },
        },
        {
          user: {
            id: 2,
            name: 'bar',
            login_id: 'student2',
          },
        },
      ],
    },
    {
      scoring_range: {
        id: 3,
        rule_id: 1,
        lower_bound: 0.4,
        upper_bound: 0.7,
        created_at: null,
        updated_at: null,
        position: null,
      },
      size: 0,
      students: [],
    },
    {
      scoring_range: {
        id: 2,
        rule_id: 1,
        lower_bound: 0.0,
        upper_bound: 0.4,
        created_at: null,
        updated_at: null,
        position: null,
      },
      size: 0,
      students: [],
    },
  ],
  assignment: {
    id: 7,
    title: 'Points',
    description: '',
    points_possible: 15,
    grading_type: 'points',
    submission_types: ['on_paper'],
    grading_scheme: null,
  },
  students: {
    1: {
      triggerAssignment: {
        assignment: {
          id: '1',
          name: 'hello world',
          points_possible: 100,
          grading_type: 'percent',
        },
        submission: {
          submitted_at: '2016-08-22T14:52:43Z',
          grade: '100',
        },
      },
      followOnAssignments: [
        {
          score: 100,
          trend: 1,
          assignment: {
            id: '2',
            name: 'hello world',
            grading_type: 'percent',
            points_possible: 100,
            submission_types: ['online_text_entry'],
          },
        },
      ],
    },
    2: {
      triggerAssignment: {
        assignment: {
          id: '1',
          name: 'hello world',
          points_possible: 100,
          grading_type: 'percent',
        },
        submission: {
          submitted_at: '2016-08-22T14:52:43Z',
          grade: '100',
        },
      },
      followOnAssignments: [
        {
          score: 100,
          trend: 1,
          assignment: {
            id: '2',
            name: 'hello world',
            grading_type: 'percent',
            points_possible: 100,
            submission_types: ['online_text_entry'],
          },
        },
      ],
    },
  },
  selectedPath: {
    range: 0,
    student: null,
  },
  showDetails: true,
  isStudentDetailsLoading: false,

  // actions
  selectRange: () => {},
  selectStudent: () => {},
})

test('renders component correctly', () => {
  renderComponent(defaultProps())
  clock.tick(500)

  const rendered = document.querySelectorAll('.crs-breakdown-details')
  equal(rendered.length, 1)
})

test('clicking next student calls select student with the next student index', () => {
  const props = defaultProps()
  props.selectedPath.student = 0
  props.selectStudent = sinon.spy()
  renderComponent(props)
  clock.tick(500)

  const nextBtn = document.querySelector('.student-details__next-student')
  nextBtn.click()

  ok(props.selectStudent.calledWith(1))
})

test('clicking next student on the last student wraps around to first student', () => {
  const props = defaultProps()
  props.selectedPath.student = 1
  props.selectStudent = sinon.spy()
  renderComponent(props)
  clock.tick(500)

  const nextBtn = document.querySelector('.student-details__next-student')
  nextBtn.click()

  ok(props.selectStudent.calledWith(0))
})

test('clicking prev student calls select student with the correct student index', () => {
  const props = defaultProps()
  props.selectedPath.student = 1
  props.selectStudent = sinon.spy()
  renderComponent(props)
  clock.tick(500)

  const prevBtn = document.querySelector('.student-details__prev-student')
  prevBtn.click()

  ok(props.selectStudent.calledWith(0))
})

test('clicking prev student on first student wraps around to last student', () => {
  const props = defaultProps()
  props.selectedPath.student = 0
  props.selectStudent = sinon.spy()
  renderComponent(props)
  clock.tick(500)

  const prevBtn = document.querySelector('.student-details__prev-student')
  prevBtn.click()

  ok(props.selectStudent.calledWith(1))
})

test('clicking back on student details unselects student', () => {
  const props = defaultProps()
  props.selectedPath.student = 0
  props.selectStudent = sinon.spy()
  renderComponent(props)
  clock.tick(500)

  const backBtn = document.querySelector('.crs-back-button')
  backBtn.click()

  ok(props.selectStudent.calledWith(null))
})
